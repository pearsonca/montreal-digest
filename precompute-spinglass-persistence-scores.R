#!/usr/bin/env Rscript
## read in raw input

# setwd(sprintf("%s/muri-overall", Sys.getenv("GITPROJHOME")))
require(data.table)
require(igraph)
require(parallel)

rm(list=ls())

args <- commandArgs(trailingOnly = T)
# args <- c("input/background-clusters/spin-glass/30-30.rds")

precomms <- readRDS(args[1])
n <- precomms[,max(interval)]
# n <- 10
# precomms[interval == target, .N, by=list(community)]
# precomms[interval < target, {
#     
#     tmp <- combn(user_id, 2)
#     list(user.a = tmp[1,], user.b = tmp[2,])
#   },
#   by=list(community)
# ]
# for each interval

# maxint <- max(precomms$interval)

crs <- min(as.integer(Sys.getenv("PBS_NUM_PPN")), detectCores(), na.rm = T)

mclapply(1:n, function(ntrvl){
  saveRDS(precomms[interval == ntrvl, {
    tmp <- combn(user_id, 2)
    list(user.a = tmp[1,], user.b = tmp[2,], interval=ntrvl, score = 1)
  },
  by=list(community)], sub("\\.rds",sprintf("-acc/agg-%02d.rds", ntrvl), args[1]))
}, mc.cores = crs)