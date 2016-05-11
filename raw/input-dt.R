#!/usr/bin/env Rscript
## read in raw input

rm(list=ls())

original_data <- commandArgs(trailingOnly = T)[1]

require(data.table)

saveRDS(setkey(fread(
    original_data, header = F, sep=" ",
    colClasses = list(integer=1.4),
    col.names  = c("user_id", "location_id", "login", "logout")
  ), login, logout, user_id, location_id
), pipe("cat", "wb"))