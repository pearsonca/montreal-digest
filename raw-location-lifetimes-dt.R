#!/usr/bin/env Rscript

rm(list=ls())

args <- commandArgs(trailingOnly = T)

if (length(args)<2) stop("too few arguments to raw-location-lifetimes-dt.R: ", args)

require(data.table)

src <- readRDS(args[1])
saveRDS(
  src[,list(
      arrive=min(login),
      depart=max(logout)
    ), keyby=location_id
  ]
, args[2])