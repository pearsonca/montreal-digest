#!/usr/bin/env Rscript
## read in raw input

rm(list=ls())

args <- commandArgs(trailingOnly = T)
# inpath, assumpath, outpath

secs_per_day <- 60*60*24

require(data.table)

res <- readRDS(args[1])

res[,
  `:=`(
    login_day  = login %/% secs_per_day,
    logout_day = logout %/% secs_per_day
  )
][,
  `:=`(
    login_time  = login  - login_day*secs_per_day,
    logout_time = logout - logout_day*secs_per_day
  )
][,
  `:=`(
    login_hour  = as.integer(login_time / 60 / 60),
    logout_hour = as.integer(logout_time / 60 / 60)
  )
][,
  `:=`(
    login_day_secs = ifelse(login_day == logout_day, logout_time - login_time, secs_per_day - login_time),
    logout_day_secs = ifelse(login_day == logout_day, 0, logout_time)
  )
]

saveRDS(res, pipe("cat", "wb"))