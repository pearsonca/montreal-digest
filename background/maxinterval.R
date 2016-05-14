#!/usr/bin/env Rscript
## read in raw input

rm(list=ls())

suppressPackageStartupMessages(require(data.table))

args <- commandArgs(trailingOnly = T)
base.dt <- readRDS(args[1])
intDays <- as.integer(args[2])
st <- base.dt[1, floor(start/60/60/24)]
cat(ceiling(base.dt[,max(end)/60/60/24 - st]/intDays))
