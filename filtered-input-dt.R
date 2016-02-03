#!/usr/bin/env Rscript
## read in raw input

rm(list=ls())

args <- commandArgs(trailingOnly = T)
# inpath, assumpath, outpath
if (length(args)<3) stop("too few arguments to filtered-input-dt.R: ", args)

require(data.table)
require(jsonlite)

raw <- readRDS(args[1])
assumptions <- fromJSON(args[2])

res <- with(assumptions,{
  filtered <- raw[(logout != login) & ((logout - login) <= max_hours*60*60)]
  invalid.users <- filtered[,
    list(.N, lifetime = (max(logout) - min(login))/60/60/24),
    by=user_id
  ][N < min_logins | lifetime < min_lifetime]$user_id
  invalid.locs  <- filtered[,
    .N,
    by=location_id
  ][N < min_logins]$location_id
  while((length(invalid.users) > 0) | (length(invalid.locs) > 0)) {
    filtered <- filtered[!(user_id %in% invalid.users) & !(location_id %in% invalid.locs)]
    invalid.users <- filtered[,
      list(.N, lifetime = (max(logout) - min(login))/60/60/24),
      by=user_id
    ][N < min_logins | lifetime < min_lifetime]$user_id
    invalid.locs  <- filtered[,
      .N,
      by=location_id
    ][N < min_logins]$location_id
  }
  filtered
})

saveRDS(res, args[3])