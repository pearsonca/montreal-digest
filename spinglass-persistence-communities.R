#!/usr/bin/env Rscript
## read in raw input
# setwd(sprintf("%s/muri-overall", Sys.getenv("GITPROJHOME")))
rm(list=ls())

require(data.table)
require(igraph)

source("../montreal-digest/buildStore.R")

emptygraph <- data.table(user_id=integer(), community=integer())

resolve <- function(base.dt, outputfn, verbose, crs) with(relabeller(base.dt[score > 1]), {
  store <- if (dim(res)[1] == 0) emptygraph else buildStore(res, crs=crs, verbose=verbose)
  if (verbose) cat("finishing", outputfn,"\n")
  saveRDS(
    originalUserIDs(store, mp),
    outputfn
  )
})

parser <- optparse::OptionParser(
  usage = "usage: %prog path/to/agg-interval-userab-scores.rds path/to/interval-user-community.rds",
  description = "convert (user.a, user.b, score) accumulated to interval k into (user, persistence community) at interval k.",
  option_list = list(
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

req_pos <- list(base.dt=readRDS, outputfn=identity)

parse_args <- function(argv = commandArgs(trailingOnly = T)) {
  parsed <- optparse::parse_args(parser, argv, positional_arguments = length(req_pos))
  parsed$options$help <- NULL
  result <- c(mapply(function(f,c) f(c), req_pos, parsed$args, SIMPLIFY = F), parsed$options)
  if(result$verbose) print(result)
  result
}

# for (i in 3:132) {
#   agg <- sprintf("input/background-clusters/spin-glass/agg-15-30/%03d.rds", i)
#   pc <- sub("agg","pc",agg)
  do.call(resolve, parse_args(
#    c(agg, pc, "-v")
  ))
#}
