#!/usr/bin/env Rscript
## read in raw input

rm(list=ls())

args <- commandArgs(trailingOnly = T)
# inpath, outpath
if (length(args)<2) stop("too few arguments to remap-user-ids-dt.R: ", args)

require(data.table)

remap <- readRDS(args[1])[, list(new_user_id=.GRP), keyby=user_id]
saveRDS(
  remap,
  args[2]
)
