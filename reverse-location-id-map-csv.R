#!/usr/bin/env Rscript
## read in raw input

rm(list=ls())

args <- commandArgs(trailingOnly = T)
# inpath == remap-location-ids.rds, outpath
if (length(args)<2) stop("too few arguments to reverse-location-id-map-csv.R: ", args)

require(data.table)

remap <- readRDS(args[1])[, location_id, keyby = new_location_id]
write.table(remap$location_id, args[2], row.names = F, col.names = F)