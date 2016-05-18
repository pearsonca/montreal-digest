## take clustering computations and make a user preferences dt

rm(list=ls())

args <- commandArgs(trailingOnly = T)

# args <- c("input/digest/filter/detail_input.rds", "input/digest/clustering/locrefs.rds", "input/digest/clustering/userrefs.rds")

require(data.table)

srcs <- lapply(args, readRDS)
names(srcs) <- c("censor.dt","loccluster.dt","userref.dt")

saveRDS(with(srcs,{
  intermediate <- censor.dt[
    user_id %in% userref.dt$user_id, list(visits = .N), by=list(user_id, location_id)
  ][,
    list(location_id, pref=visits/sum(visits)), keyby=user_id
  ][,
    list(user_id, pref), keyby=location_id
  ]
  
  intermediate[
    loccluster.dt[
      location_id %in% unique(intermediate$location_id),
      list(lifetime_cat, pwr_clust, vMFcluster), keyby=location_id
    ]
  ][,
    list(lifetime_cat, pwr_clust, vMFcluster, pref),
    keyby=user_id
  ]
}), pipe("cat","wb"))