## take clustering computations and make a user preferences dt

rm(list=ls())

args <- commandArgs(trailingOnly = T)

require(data.table)

srcs <- lapply(args, readRDS)
names(srcs) <- c("vMF.dt","pwr.dt","usage.dt")

with(srcs,{
  saveRDS(vMF.dt[pwr.dt][usage.dt], pipe("cat", "wb"))
})