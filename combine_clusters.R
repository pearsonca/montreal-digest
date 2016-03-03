#!/usr/bin/env Rscript
## read in raw input

require(data.table)

rm(list=ls())

args <- commandArgs(trailingOnly = T)
# args <- c("input/background-clusters/spin-glass/30-30-base")
if (length(args)<1) stop("too few arguments to combine_clusters.R: ", args)

srcdir <- args[1]
srcfiles <- list.files(srcdir, full.names = T)

saveRDS(setkey(rbindlist(lapply(srcfiles, function(fn) {
  res <- readRDS(fn)
  res[, interval := as.integer(gsub(".+/(\\d+)\\.rds","\\1", fn))]
  res
})), interval, community, user_id), sprintf("%s.rds",args[1]))