#!/usr/bin/env Rscript
## read in raw input

# setwd(sprintf("%s/muri-overall", Sys.getenv("GITPROJHOME")))
suppressPackageStartupMessages(require(data.table))
suppressPackageStartupMessages(require(igraph))

rm(list=ls())

trans <- function(dt) {
  dt[ user.b < user.a, `:=`(user.b = user.a, user.a = user.b)]
  setkey(dt, user.a, user.b)
}

parse_args <- function(argv = commandArgs(trailingOnly = T)) {
  parser <- optparse::OptionParser(
    usage = "usage: %prog path/to/community-interval.rds path/to/useratob-interval.rds score-scheme",
    description = "convert (user, community) and (user.a, user.b, interval) into (user.a in community X, user.b in community X, 1[+/- bonuses]).",
    option_list = list(
      optparse::make_option(
        c("--verbose","-v"),  action="store_true", default = FALSE,
        help="verbose?"
      )
    )
  )
  req_pos <- list(community.dt=readRDS, pairs.dt=readRDS, scoring=identity)
  parsed <- optparse::parse_args(parser, argv, positional_arguments = length(req_pos))
  result <- c(mapply(function(f,c) f(c), req_pos, parsed$args, SIMPLIFY = F), parsed$options)
  if(result$verbose) print(result)
  result
}

community_pairs <- function(comm.dt) trans(comm.dt[, {
    tmp <- combn(user_id, 2)
    list(user.a = tmp[1,], user.b = tmp[2,], score = 1)
  },
  by=list(community)
])

with(parse_args(
#  c("input/background-clusters/spin-glass/base-30-30/001.rds","input/background-clusters/spin-glass/acc-30-30/001.rds") # uncomment for debugging
),{
  res <- trans(if (dim(community.dt)[1]) community.dt[, {
      tmp <- combn(user_id, 2)
      list(user.a = tmp[1,], user.b = tmp[2,], score = 1)
    },
    by=list(community)
  ] else data.table(community=integer(0), user.a = integer(0), user.b=integer(0), score=integer(0)))
  
  if ((scoring == "bonus") & dim(res)[1]) {
    tars <- res[pairs.dt][!is.na(community), list(increment=T), keyby=list(user.a, user.b)]
    res[tars, score := score + 1]
  }
  
  ## TODO IF "BONUS", INCREASE SCORE BY PAIRS.DT
  # roughly res[pairs.dt][, score := score + 1 ]
  
  saveRDS(res, pipe("cat", "wb"))
})