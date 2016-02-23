#!/usr/bin/env Rscript
## read in raw input

# setwd("/Volumes/Data/workspaces/muri-overall")
require(data.table)
require(igraph)
require(parallel)

rm(list=ls())

args <- commandArgs(trailingOnly = T)
# args <- c("input/background-clusters/spin-glass/30-30.rds", "0.7")

precomms <- readRDS(args[1])
# for each interval
thing <- precomms[interval < 4, {
    tmp <- combn(user_id, 2)
    list(user.a = tmp[1,], user.b = tmp[2,])
  },
  by=list(interval, community)
]

