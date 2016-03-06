#!/usr/bin/env Rscript
## read in raw input

rm(list=ls())

require(data.table)
require(igraph)

source("../montreal-digest/buildStore.R")

emptygraph <- data.table(user_id=integer(), community=integer())

resolve <- function(base.dt, outputfn, verbose) with(relabeller(base.dt), {
  store <- if (dim(res)[1] == 0) emptygraph else buildStore(res)
  if (verbose) cat("finishing", outputfn,"\n")
  saveRDS(
    originalUserIDs(store, mp),
    outputfn
  )
})

parse_args <- function(argv = commandArgs(trailingOnly = T)) {
  parser <- optparse::OptionParser(
    usage = "usage: %prog path/to/acc-interval-userab-scores.rds path/to/interval-user-community.rds",
    description = "convert (user.a, user.b, score) accumulated to interval k into (user, persistence community) at interval k.",
    option_list = list(
      optparse::make_option(
        c("--verbose","-v"),  action="store_true", default = FALSE,
        help="verbose?"
      )
    )
  )
  req_pos <- list(base.dt=readRDS, outputfn=identity)
  parsed <- optparse::parse_args(parser, argv, positional_arguments = length(req_pos))
  parsed$options$help <- NULL
  result <- c(mapply(function(f,c) f(c), req_pos, parsed$args, SIMPLIFY = F), parsed$options)
  if(result$verbose) print(result)
  result
}

do.call(resolve, parse_args())