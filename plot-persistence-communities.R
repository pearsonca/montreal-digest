#!/usr/bin/env Rscript

rm(list=ls())

require(data.table)
require(ggplot2)
require(reshape2)

filelister <- function(dir) list.files(dir, "^\\d+.rds$", full.names = T)
dirlister <- function(pat) list.files(sub("/[^/]+$", "", pat), pattern=sub(".+/([^/]+)$", "\\1", pat), include.dirs = T, full.names = T)

parse_args <- function(argv = commandArgs(trailingOnly = T)) {
  parser <- optparse::OptionParser(
    usage = "usage: %prog path/to/pc-pattern outputbase",
    description = "visualize persistence community results",
    option_list = list(
      optparse::make_option(
        c("--verbose","-v"),  action="store_true", default = FALSE,
        help="verbose?"
      )
    )
  )
  req_pos <- list(inputdirs=dirlister, outputbase=identity)
  parsed <- optparse::parse_args(parser, argv, positional_arguments = length(req_pos))
  parsed$options$help <- NULL
  result <- c(mapply(function(f,c) f(c), req_pos, parsed$args, SIMPLIFY = F), parsed$options)
  if(result$verbose) print(result)
  result
}

digest <- function(inputdirs, outputbase, verbose) {
  #browser()
  tmp <- rbindlist(lapply(inputdirs, function(dir) {
      stride <- as.numeric(sub(".+-(\\d+)-\\d+$","\\1",dir)); win <- as.numeric(sub(".+-\\d+-(\\d+)$","\\1",dir));
      rbindlist(lapply(filelister(dir), function(fn) {
      hld <- readRDS(fn)
      interval <- as.integer(sub(".+/(\\d+)\\.rds","\\1", fn))
      if (dim(hld)[1]) {
        mrhold <- hld[,.N,by=community]
        mrhold[between(N,3,60),{
          h <- hist(N, breaks=2:60, plot = F)
          res <- h$density
          names(res) <- 3:60
          c(as.list(res), interval=interval, count=dim(mrhold)[1], stride=stride, window=win)
        }]
      } else {
        res <- rep(NA, times=60-3+1)
        names(res) <- 3:60
        do.call(data.table, c(as.list(res), interval=interval, count=0, stride=stride, window=win))
      }
      
      }))
    }
  ))
  pcount <- ggplot(tmp[,count,keyby=list(stride, window, interval)]) + theme_bw() + 
    aes(x=interval/(30/stride), y=count, color=factor(paste0(window," days")), linetype=factor(paste0("every ", stride," days"))) +
    geom_line() + labs(
      x="interval", y="# of communities",
      color='collection\nwindow', linetype='collection\nfrequency'
    )
  psizedistro <- ggplot(
    melt(tmp[,!"count", with=F], id.vars = c("interval", "stride", "window"), value.name = "density")[!is.na(density) & density != 0][, population := as.integer(as.character(variable))]
  ) + theme_bw() + aes(
    ymin = population-0.5, ymax = population+0.5,
    xmax = interval/(30/stride)+0.5/(30/stride), xmin = interval/(30/stride)-0.5/(30/stride),
    fill=log(density)
  ) +
    geom_rect() +
    facet_grid(stride ~ window) + labs(x="interval", y="community size") #+
    #geom_point(aes(y=mx)) + geom_point(aes(y=mn))
  #browser()
  ggsave(sprintf('%s_%s.png', outputbase, 'distro'), psizedistro)
  ggsave(sprintf('%s_%s.png', outputbase, 'count'), pcount)
}

do.call(digest, parse_args(
  c("input/background-clusters/spin-glass/pc-*", "output/background-clusters/spin-glass/pc_cluster_trends")
))

do.call(digest, parse_args(
  c("input/background-clusters/spin-glass/base-*", "output/background-clusters/spin-glass/base_cluster_trends")
))