#!/usr/bin/env Rscript
## read in raw input

# setwd(sprintf("%s/muri-overall", Sys.getenv("GITPROJHOME")))
rm(list=ls())

require(data.table)

readIn <- function(fn) {
  res <- readRDS(fn)[,score,by=list(user.a, user.b)]
  res[
    user.b < user.a,
    `:=`(user.b = user.a, user.a = user.b)
    ]
  res
}

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
  req_pos <- list(score.dt=readIn)
  minargs <- length(req_pos)
  parsed <- optparse::parse_args(parser, argv, positional_arguments = c(0,1)+minargs)
  parsed$options$help <- NULL
  result <- c(mapply(function(f,c) f(c), req_pos, parsed$args, SIMPLIFY = F), parsed$options)
  result$prev.dt <- if (length(parsed$args)==2) readIn(parsed$args[2]) else data.table(user.a=integer(), user.b=integer(), score=numeric())
  if(result$verbose) print(result)
  result
}

clargs <- parse_args(
#  c("input/digest/background/30/30/bonus/acc/002.rds", "input/digest/background/30/30/bonus/agg/001.rds") # uncomment to debug
)

with(clargs,{
  saveRDS(
    rbind(score.dt, prev.dt[, score := score*discount ])[,
      list(score = sum(score)), keyby=list(user.a, user.b)
    ][
      score > discount^censor
    ],
    pipe("cat", "wb")
  )
})