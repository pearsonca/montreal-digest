#!/usr/bin/env Rscript

rm(list=ls())

args <- commandArgs(trailingOnly = T)
# args <- c("input/raw-location-lifetimes.rds", "input/remap-location-ids.rds", "input/location-lifetimes.rds")
if (length(args)<3) stop("too few arguments to location-lifetimes-dt.R: ", args)

src <- readRDS(args[1])
remap <- readRDS(args[2])

require(data.table)

saveRDS(src[remap][,list(arrive,depart),keyby=list(location_id=new_location_id)], args[3])