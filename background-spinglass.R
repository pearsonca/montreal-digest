#!/usr/bin/env Rscript
## read in raw input

rm(list=ls())

require(data.table)
require(igraph)
require(parallel)

source("../montreal-digest/buildStore.R")

slice <- function(dt, low, high) relabeller(
  dt[start < high*24*3600 & low*24*3600 < end,
  list(score=.N),
  by=list(user.a, user.b)]
)

emptygraph <- data.table(user_id=integer(), community=integer())

resolve <- function(
  base.dt, intDays, winDays, outputdir, crs,
  mxint=NA, verbose, ...
) {
  st = base.dt[1, floor(start/60/60/24)]
  n <- min(ceiling(base.dt[,max(end)/60/60/24 - st]/intDays), mxint, na.rm = TRUE)
  targets <- 1:n
  completed <- as.integer(gsub(".rds","", list.files(outputdir, "rds") ))
  want <- targets[c(-completed,-(n+1))]
  #  system.time(
  mclapply(want, function(inc) with(slice(base.dt, st + inc*intDays-winDays, st + inc*intDays), {
    store <- if (dim(res)[1] == 0) emptygraph else buildStore(res)
    resfile <- sprintf("%s/%03d.rds", outputdir, inc)
    if (verbose) cat("finishing", resfile,"\n")
    saveRDS(
      originalUserIDs(store, mp),
      resfile
    )
  }), mc.cores = crs, mc.allow.recursive = F)
}

require(optparse)

rawReader <- function(pth) {
  raw.dt <- readRDS(pth)
  raw.dt[
    user.b < user.a,
    `:=`(user.b = user.a, user.a = user.b)
  ]
  setkey(raw.dt, start, end, user.a, user.b)
}

parse_args <- function(argv = commandArgs(trailingOnly = T)) {
  parser <- optparse::OptionParser(
    usage = "usage: %prog path/to/raw-userab-times.rds window interval outputfile [maxintervals]",
    description = "convert (user.a, user.b, start, end) into (user, community, interval).",
    option_list = list(
      optparse::make_option(
        c("--max","-m"), type = "integer", dest="mxint",
        help="the maximum number of intervals to consider"
      ),
      optparse::make_option(
        c("--verbose","-v"),  action="store_true", default = FALSE,
        help="verbose?"
      ),
      optparse::make_option(
        c("--cores","-c"), dest = "crs",
        default = min(as.integer(Sys.getenv("PBS_NUM_PPN")), detectCores()-1, na.rm = T),
        help="number of cores to use in multithreaded calculation."
      )
    )
  )
  req_pos <- list(base.dt=rawReader, intDays=as.integer, winDays=as.integer, outputdir=identity)
  parsed <- optparse::parse_args(parser, argv, positional_arguments = length(req_pos))
  parsed$options$help <- NULL
  result <- c(mapply(function(f,c) f(c), req_pos, parsed$args, SIMPLIFY = F), parsed$options)
  if(result$verbose) print(result)
  result
}

clargs <- parse_args(
#  c("input/raw-pairs.rds", "30", "30", "input/background-clusters/spin-glass/30-30", "-v","-m","5") # uncomment for debugging
)

do.call(resolve, clargs)
