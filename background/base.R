#!/usr/bin/env Rscript
## read in raw input

rm(list=ls())

require(data.table)
require(igraph)
require(parallel)

source("buildStore.R")

slice <- function(dt, low, high) relabeller(
  dt[start < high*24*3600 & low*24*3600 < end,
  list(score=.N),
  by=list(user.a, user.b)]
)

emptygraph <- data.table(user_id=integer(), community=integer())

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
    usage = "usage: %prog path/to/raw-userab-times.rds window interval output_interval [maxintervals]",
    description = "convert (user.a, user.b, start, end) into (user, community, interval).",
    option_list = list(
      optparse::make_option(
        c("--verbose","-v"),  action="store_true", default = FALSE,
        help="verbose?"
      )
    )
  )
  req_pos <- list(base.dt=rawReader, intDays=as.integer, winDays=as.integer, inc=as.integer)
  parsed <- optparse::parse_args(parser, argv, positional_arguments = length(req_pos))
  parsed$options$help <- NULL
  result <- c(mapply(function(f,c) f(c), req_pos, parsed$args, SIMPLIFY = F), parsed$options)
  if(result$verbose) print(result)
  result
}

clargs <- parse_args(
#  c("input/raw/pairs.rds", "30", "30", "001", "-v","-m","5") # uncomment for debugging
)

resolve <- function(base.dt, intDays, winDays, inc, verbose=F) {
  st = base.dt[1, floor(start/60/60/24)]
  with(slice(base.dt, st + inc*intDays-winDays, st + inc*intDays), {
    store <- if (dim(res)[1] == 0) emptygraph else buildStore(res)
    if (verbose) cat("finishing", inc, "\n", file = stderr())
    originalUserIDs(store, mp)
  })
}

saveRDS(
  do.call(resolve, clargs),
  pipe("cat", "wb")
)