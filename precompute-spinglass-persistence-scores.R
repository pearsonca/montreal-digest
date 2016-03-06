#!/usr/bin/env Rscript
## read in raw input

# setwd(sprintf("%s/muri-overall", Sys.getenv("GITPROJHOME")))
require(data.table)
require(igraph)
require(parallel)
require(optparse)

rm(list=ls())

parse_args <- function(argv = commandArgs(trailingOnly = T)) {
  parser <- optparse::OptionParser(
    usage = "usage: %prog path/to/community-interval.rds path/to/output-useratob-scores.rds",
    description = "convert (user, community) into (user.a in community X, user.b in community X, 1).",
    option_list = list(
      optparse::make_option(
        c("--verbose","-v"),  action="store_true", default = FALSE,
        help="verbose?"
      )
    )
  )
  req_pos <- list(input.dt=readRDS, outputfn=identity)
  parsed <- optparse::parse_args(parser, argv, positional_arguments = length(req_pos))
  result <- c(mapply(function(f,c) f(c), req_pos, parsed$args, SIMPLIFY = F), parsed$options)
  if(result$verbose) print(result)
  result
}

with(parse_args(
#  c("input/background-clusters/spin-glass/base-30-30/001.rds","input/background-clusters/spin-glass/acc-30-30/001.rds") # uncomment for debugging
),{
  res <- if (dim(input.dt)[1]) input.dt[, {
      tmp <- combn(user_id, 2)
      list(user.a = tmp[1,], user.b = tmp[2,], score = 1)
    },
    by=list(community)
  ] else data.table(community=integer(0), user.a = integer(0), user.b=integer(0), score=integer(0))

  saveRDS(res, outputfn)
})