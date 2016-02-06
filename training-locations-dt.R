#!/usr/bin/env Rscript

rm(list=ls())

args <- commandArgs(trailingOnly = T)

if (length(args)<3) stop("too few arguments to training-locations-dt.R: ", args)

require(data.table)
require(jsonlite)

src <- readRDS(args[1])
params <- fromJSON(args[2])

with(params,{
  set.seed(seed)
  saveRDS(src[,list(location_id, training=runif(.N) < training_fraction)], args[3])  
})
