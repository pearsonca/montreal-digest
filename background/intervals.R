#!/usr/bin/env Rscript
## read in raw input

rm(list=ls())

suppressPackageStartupMessages(require(data.table))

source("buildStore.R")

slice <- function(dt, low, high) dt[
  start < high*24*3600 & low*24*3600 < end,
  list(score=.N),
  by=list(user.a, user.b)
]

parse_args <- function(argv = commandArgs(trailingOnly = T)) {
  parser <- optparse::OptionParser(
    usage = "usage: %prog path/to/raw-userab-times.rds interval window increment",
    description = "convert (user.a, user.b, start, end) into (user, community, interval).",
    option_list = list(
      optparse::make_option(
        c("--verbose","-v"),  action="store_true", default = FALSE,
        help="verbose?"
      )
    )
  )
  req_pos <- list(base.dt=readRDS, intDays=as.integer, winDays=as.integer, inc=as.integer)
  parsed <- optparse::parse_args(parser, argv, positional_arguments = length(req_pos))
  parsed$options$help <- NULL
  result <- c(mapply(function(f,c) f(c), req_pos, parsed$args, SIMPLIFY = F), parsed$options)
  if(result$verbose) print(result)
  result
}

clargs <- parse_args(
#  c("input/raw/pairs.rds", "30", "001", "-v") # uncomment for debugging
)

resolve <- function(base.dt, intDays, winDays, inc, verbose=F) {
  st <- base.dt[1, floor(start/60/60/24)]
  slice(base.dt, st + inc*intDays-winDays, st + inc*intDays)
}

saveRDS(
  do.call(resolve, clargs),
  pipe("cat", "wb")
)