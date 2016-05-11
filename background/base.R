#!/usr/bin/env Rscript
## read in raw input

rm(list=ls())

suppressPackageStartupMessages(require(data.table))

source("buildStore.R")

emptygraph <- data.table(user_id=integer(), community=integer())

rawReader <- function(pth) {
  raw.dt <- readRDS(pth)
  raw.dt[
    user.b < user.a,
    `:=`(user.b = user.a, user.a = user.b)
  ]
  setkey(raw.dt, user.a, user.b)
}

parse_args <- function(argv = commandArgs(trailingOnly = T)) {
  parser <- optparse::OptionParser(
    usage = "usage: %prog path/to/raw-userab-times.rds",
    description = "convert (user.a, user.b, start, end) into (user, community).",
    option_list = list(
      optparse::make_option(
        c("--verbose","-v"),  action="store_true", default = FALSE,
        help="verbose?"
      )
    )
  )
  req_pos <- list(base.dt=rawReader)
  parsed <- optparse::parse_args(parser, argv, positional_arguments = length(req_pos))
  parsed$options$help <- NULL
  result <- c(mapply(function(f,c) f(c), req_pos, parsed$args, SIMPLIFY = F), parsed$options)
  if(result$verbose) print(result)
  result
}

clargs <- parse_args(
#  c("input/raw/pairs.rds", "-v","-m","5") # uncomment for debugging
)

resolve <- function(base.dt, verbose=F) {
  with(relabeller(base.dt), {
    store <- if (dim(res)[1] == 0) emptygraph else buildStore(res)
    originalUserIDs(store, mp)
  })
}

saveRDS(
  do.call(resolve, clargs),
  pipe("cat", "wb")
)