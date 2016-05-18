## take clustering computations and make a user preferences dt

rm(list=ls())

args <- commandArgs(trailingOnly = T)

require(data.table)

srcs <- lapply(args, readRDS)
names(srcs) <- c("data.dt","vMF.dt","pwr.dt","usage.dt")

categorizer <- function(src.dt, cat, ref) {
  rle_expr <- paste0("rle(",cat,")")
  key_expr <- c("user_id",cat)
  lvls <- levels(src.dt[[cat]])
  mx_expr <- parse(text=paste0("list(main=factor(",cat,"[which.max(prop)], ordered=T, levels=lvls),share=max(prop))"))
  rle_dt <- src.dt[, rle(as.numeric(eval(parse(text=cat)))), keyby=user_id]
  prop_ref <- src.dt[,list(prop=sum(logout-login)), keyby=key_expr][ref][,list(prop=prop/usage), keyby=key_expr]
  prop_lab <- prop_ref[, eval(mx_expr), by=user_id]
  chunks <- data.table(dcast(rle_dt, user_id ~ values, value.var="lengths", fun.aggregate = sum), key="user_id")
  ## cast data, maybe?
  digest <- rle_dt[, list(tot_visits = sum(lengths), mn_reps=mean(lengths), switches=.N), keyby=user_id][ref][prop_lab][chunks]
  list(rle_dt=rle_dt, prop_ref=prop_ref, prop_lab=prop_lab, digest=digest)
}

with(srcs,{
  setkey(data.dt, location_id, user_id, login, logout)
  withClusters.dt <- data.dt[vMF.dt][pwr.dt][usage.dt]
  setkey(withClusters.dt, login)
  ref <- data.dt[,
                   list(
                     ul=length(unique(location_id)),
                     life=max(logout)-min(login),
                     usage=sum(logout-login)),
                   keyby=user_id
                   ]
  lifetime_dts <- categorizer(withClusters.dt, "lifetime_cat", ref)
  pwr_dts <- categorizer(withClusters.dt, "pwr_clust", ref)
  vMF_dts <- categorizer(withClusters.dt, "vMFcluster", ref)
  res <- ref[
    lifetime_dts$digest[, list(lifetime_main = main, lifetime_share = share), keyby=user_id]
  ][
    pwr_dts$digest[, list(pwr_main = main, pwr_share = share), keyby=user_id]
  ][
    vMF_dts$digest[, list(peak_main = main, peak_share = share), keyby=user_id]
  ][
    between(life, 365*24*60*60, 3*365*24*60*60) & between(ul,3,20)
  ]
  saveRDS(res, pipe("cat", "wb"))
})