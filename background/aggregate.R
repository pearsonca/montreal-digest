#!/usr/bin/env Rscript
## read in raw input

# setwd(sprintf("%s/muri-overall", Sys.getenv("GITPROJHOME")))
rm(list=ls())

require(data.table)
require(igraph)
require(parallel)
require(optparse)

filelister <- function(dir) list.files(sub("/$", "", dir), "^\\d+.rds$", full.names = T)

parse_args <- function(argv = commandArgs(trailingOnly = T)) {
  parser <- optparse::OptionParser(
    usage = "usage: %prog path/to/input-useratob-scores/ path/to/accumulated-useratob-scores/",
    description = "convert (community X, user.a in community X, user.b in community X, 1) at interval k, to (...) cumulated up to interval k.",
    option_list = list(
      optparse::make_option(
        c("--verbose","-v"),  action="store_true", default = FALSE,
        help="verbose?"
      ),
      optparse::make_option(
        c("--discount","-d"), default = 0.9,
        help="the discount rate for scores from previous interval."
      ),
      optparse::make_option(
        c("--censor","-c"), default = 6,
        help="the equivalent number of score-less intervals to consider before dropping a link."
      )
    )
  )
  req_pos <- list(inputfiles=filelister, outputdir=identity)
  parsed <- optparse::parse_args(parser, argv, positional_arguments = length(req_pos))
  parsed$options$help <- NULL
  result <- c(mapply(function(f,c) f(c), req_pos, parsed$args, SIMPLIFY = F), parsed$options)
  result$storeres <- function(dt, was) {
    saveRDS(dt, sub(parsed$args[1], parsed$args[2], was))
    dt
  }
  
  if(result$verbose) print(result)
  result
}

readIn <- function(fn) {
  res <- readRDS(fn)[,score,by=list(user.a, user.b)]
  res[
    user.b < user.a,
    `:=`(user.b = user.a, user.a = user.b)
    ]
  res
}

clargs <- parse_args(
#  c("input/background-clusters/spin-glass/acc-15-30/", "input/background-clusters/spin-glass/agg-15-30/") # uncomment to debug
)

with(clargs,{
  censor_score <- discount^censor
  doneFiles <- list.files(sub("/$","", outputdir), full.names = T)
#  browser()
  trim <- length(doneFiles)-1 # assume: files produced sequentially + last file has write error of some kind
  reduceInputFiles <- if (trim) inputfiles[-(1:trim)] else inputfiles[-1]
  init.dt <- if (trim) readRDS(doneFiles[trim]) else storeres(readIn(inputfiles[1]), inputfiles[1])
  # trim input files to the first file not yet processed
  Reduce(
    function(prev, currentfn) {
      newres <- rbind(readIn(currentfn), prev[, score := score*discount ])
      storeres(newres[,list(score = sum(score)), keyby=list(user.a, user.b)][score > censor_score], currentfn)
    },
    reduceInputFiles,
    init.dt
  )
})