#!/usr/bin/env Rscript
## read in raw input

# setwd(sprintf("%s/muri-overall", Sys.getenv("GITPROJHOME")))
require(data.table)
require(igraph)
require(parallel)

rm(list=ls())

args <- commandArgs(trailingOnly = T)
# args <- c("input/background-clusters/spin-glass/30-30-base.rds","input/background-clusters/spin-glass/30-30-acc")

precomms <- readRDS(args[1])
n <- precomms[,max(interval)]

crs <- min(as.integer(Sys.getenv("PBS_NUM_PPN")), detectCores(), na.rm = T)

mclapply(1:n, function(ntrvl){
  saveRDS(precomms[interval == ntrvl, {
    tmp <- combn(user_id, 2)
    list(user.a = tmp[1,], user.b = tmp[2,], interval=ntrvl, score = 1)
  },
  by=list(community)], sprintf("%s/%02d.rds", args[2], ntrvl))
}, mc.cores = crs)