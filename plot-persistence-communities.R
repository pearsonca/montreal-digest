#!/usr/bin/env Rscript

rm(list=ls())

require(data.table)
require(igraph)

filelister <- function(dir) list.files(dir, "^\\d+.rds$", full.names = T)

parse_args <- function(argv = commandArgs(trailingOnly = T)) {
  parser <- optparse::OptionParser(
    usage = "usage: %prog path/to/pc-results/ outputfile_base",
    description = "visualize persistence community results",
    option_list = list(
      optparse::make_option(
        c("--verbose","-v"),  action="store_true", default = FALSE,
        help="verbose?"
      )
    )
  )
  req_pos <- list(inputfiles=filelister, outputbase=identity)
  parsed <- optparse::parse_args(parser, argv, positional_arguments = length(req_pos))
  parsed$options$help <- NULL
  result <- c(mapply(function(f,c) f(c), req_pos, parsed$args, SIMPLIFY = F), parsed$options)
  if(result$verbose) print(result)
  result
}

digest <- function(inputfiles, outputbase, verbose) {
  tmp <- rbindlist(lapply(inputfiles, function(fn) {
    hld <- readRDS(fn)
    interval <- as.integer(sub(".+/(\\d+)\\.rds","\\1", fn))
    hld[,.N,by=community][,{
      res<-quantile(N,probs = (0:4)/4)
      names(res) <- c("mn","lo","med","hi","mx")
      c(as.list(res), interval=interval, count=max(community))
    }]
  }))
  pcount <- ggplot(tmp) + aes(x=interval, y=count) + geom_line()
  psizedistro <- ggplot(tmp) + aes(x=interval, y=med, ymin=lo, ymax=mx) +
    geom_line() + geom_ribbon(alpha=0.2) +
    geom_point(aes(y=mx)) + geom_point(aes(y=mn))
  ggsave(sprint('%s_%s.png', outputbase, 'distro'), psizedistro)
  ggsave(sprint('%s_%s.png', outputbase, 'count'), pcount)
}

do.call(digest, parse_args())