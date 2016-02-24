#!/usr/bin/env Rscript
## read in raw input

# setwd(sprintf("%s/muri-overall", Sys.getenv("GITPROJHOME")))
require(data.table)
require(igraph)
require(parallel)

rm(list=ls())

args <- commandArgs(trailingOnly = T)
# args <- c("input/background-clusters/spin-glass/30-30.rds", "10")

precomms <- readRDS(args[1])
target <- as.integer(args[2])
precomms[interval == target, .N, by=list(community)]
precomms[interval == target, {
    
    tmp <- combn(user_id, 2)
    list(user.a = tmp[1,], user.b = tmp[2,])
  },
  by=list(community)
]
# for each interval

# maxint <- max(precomms$interval)
system.time(thing <- precomms[interval < 5, {
    tmp <- combn(user_id, 2)
    list(user.a = tmp[1,], user.b = tmp[2,])
  },
  by=list(interval, community)
], gcFirst = T)

system.time(thing <- rbindlist(mclapply(1:4, function(ntrvl){
  precomms[interval == ntrvl, {
    tmp <- combn(user_id, 2)
    list(user.a = tmp[1,], user.b = tmp[2,])
  },
  by=list(community)]
}, mc.cores = detectCores()-1)))