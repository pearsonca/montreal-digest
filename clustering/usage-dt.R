## compute usage clusters

## compute von Mises Fisher clusters

# get detail input

args <- commandArgs(trailingOnly = T)
# args <- "input/digest/filter/detail_input.rds"
# inpath, assumpath, outpath

require(data.table)

res <- readRDS(args[1])

## get peaks dt...?

refpredictors <- function(SD) with(SD, {
  duration <- logout - login
  total_login_time <- sum(duration)
  
  user_count <- length(unique(user_id))
  life <- max(logout) - min(login)
  
  return(list(
    log10_lifetime = log10(life),
    log10_total_duration = log10(total_login_time),
    log10_unique_users = log10(user_count)
  ))
})

raw <- res[, refpredictors(.SD), by=location_id]

agg.dt <- raw[,list(log10_total_duration,log10_unique_users,log10_lifetime), keyby=location_id]
lg10lm <- lm(log10_total_duration-log10_unique_users ~ log10_lifetime, agg.dt)
agg.dt <- cbind(agg.dt, predict(lg10lm, agg.dt, interval="prediction", level=1/3))[,
  lifetime_cat := factor(ifelse(log10_total_duration-log10_unique_users < lwr, "low", ifelse(log10_total_duration-log10_unique_users < upr, "mid", "high")), levels=c("low","mid","high"), ordered=T)]

saveRDS(agg.dt[,lifetime_cat,keyby=location_id], pipe("cat","wb"))