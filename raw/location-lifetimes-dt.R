#!/usr/bin/env Rscript

rm(list=ls())

require(data.table)

src <- readRDS(commandArgs(trailingOnly = T)[1])
saveRDS(
  src[,list(
      arrive=min(login),
      depart=max(logout)
    ), keyby=location_id
  ]
, pipe("cat", "wb"))