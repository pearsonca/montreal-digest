#!/usr/bin/env Rscript
## read in raw input

rm(list=ls())

args <- commandArgs(trailingOnly = T)
# inpath, outpath
if (length(args)<2) stop("too few arguments to raw-input-dt.R: ", args)

require(data.table)

saveRDS(setkey(fread(
    args[1], header = F, sep=" ",
    colClasses = list(integer=1.4),
    col.names  = c("user_id", "location_id", "login", "logout")
  ), login, logout, user_id, location_id
), args[2])