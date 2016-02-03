#!/usr/bin/env Rscript
## read in raw input

rm(list=ls())

args <- commandArgs(trailingOnly = T)
# inpath, outpath
if (length(args)<3) stop("too few arguments to remapped-input-dt.R: ", args)
# location remap, user remap, filtered, target
# 'location' before 'user' depends on * expansion in literal order: l comes before u

require(data.table)

location_remap <- readRDS(args[1])
user_remap <- readRDS(args[2])
filtered <- readRDS(args[3])

outkey <- key(filtered)

saveRDS(setkeyv(
  setkey(
    setkey(filtered, location_id)[location_remap],
    user_id
  )[user_remap][,list(login, logout), by=list(user_id=new_user_id, location_id=new_location_id)],
  outkey
), args[4])