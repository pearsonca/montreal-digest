# location peak stats

rm(list=ls())

args <- commandArgs(trailingOnly = T)

if (length(args)<3) stop("too few arguments to training-locations-dt.R: ", args)

require(data.table)

training_locations <- readRDS(args[1])
src <- readRDS(args[2])

refpredictors <- function(SD) with(SD, {
  duration <- logout - login
  total_login_time <- sum(duration)
  usage_by_weekday <- with_usage_zeros(SD[,
                                          list(usage = sum(login_day_secs)), keyby=weekday
                                          ], weekday_zeroes)
  usage_on_logout_day <- with_usage_zeros(SD[,
                                             list(usage = sum(logout_day_secs)), keyby=weekday
                                             ], weekday_zeroes)$usage
  
  weekday_percent <- with(usage_by_weekday, {
    ## logout usage "on" Sunday belongs to Monday, on M to Tues, etc
    usage <- (usage + c(usage_on_logout_day[7], usage_on_logout_day[-7])) / total_login_time
    names(usage) <- weekday
    usage
  })
  
  usage_by_month <- with_usage_zeros(SD[,
                                        list(usage = sum(logout - login) / total_login_time), keyby=month
                                        ], monthly_zeroes)
  
  monthly_percent <- with(usage_by_month, {
    names(usage) <- month
    usage
  })
  
  user_count <- length(unique(user_id))
  life <- max(logout) - min(login)
  
  dur_quantiles <- quantile(duration)
  login_hours <- login_parser(rle(sort(login_hour)))
  logout_hours <- logout_parser(rle(sort(logout_hour)))
  
  short <- (login_hour == logout_hour) & (login_day == logout_day)
  
  login_usage_by_hour <- data.table(usage = 
                                      ifelse(short, logout_time - login_time, (login_hour + 1)*3600 - login_time), hour = login_hour)
  logout_usage_by_hour <- data.table(usage = 
                                       logout_time[!short] - logout_hour[!short]*3600, hour = logout_hour[!short])
  
  long <- (login_day != logout_day) & !(login_hour == 23 & logout_hour == 0)
  cross_day <- rbindlist(with(SD[long, list(login_hour, logout_hour)],
                              mapply(function(in_hr, out_hr) {
                                data.table(usage = rep.int(3600, out_hr-in_hr+23), hour = ((in_hr+1):(out_hr+23))%%24)
                              }, in_hr = login_hour, out_hr = logout_hour, SIMPLIFY = F)
  ))
  # what's left?
  mid <- logout_hour > (login_hour + 1)
  inday <- rbindlist(with(SD[mid, list(login_hour, logout_hour)],
                          mapply(function(in_hr, out_hr) {
                            data.table(usage = rep.int(3600, out_hr-in_hr-1), hour = (in_hr+1):(out_hr-1))
                          }, in_hr = login_hour, out_hr = logout_hour, SIMPLIFY = F)
  ))
  usage_by_hour <- with_usage_zeros(rbind(login_usage_by_hour, logout_usage_by_hour, cross_day, inday)[, list(usage = sum(usage)/total_login_time), keyby=hour], hourly_zeros)
  
  hourly_percent <- with(usage_by_hour, {
    names(usage) <- paste0("hr", hour)
    usage
  })
  
  return(c(list(
    log10_lifetime = log10(life),
    log10_total_duration = log10(total_login_time),
    log10_unique_users = log10(user_count),
    ave_duration = mean(duration), sd_duration = sd(duration)
  ),
  weekday_percent, monthly_percent, hourly_percent,
  as.list(dur_quantiles), as.list(login_hours), as.list(logout_hours)
  ))
})
digestor <- function(dt, preds, training, cache = "../input/initPred.RData") {
  { if (!file.exists(cache)) {
    d <- dt[, preds(.SD), by=location_id]
    saveRDS(d, cache)
    d
  } else {
    readRDS(cache)
  } } -> ref
  
  centered <- ref[,lapply(.SD[,-1,with=F],function(col) col-mean(col))]
  scaled <- cbind(location_id = ref$location_id, centered[,lapply(.SD, function(col) col/sd(col))])
  list(raw = ref, training = scaled[training], validation = scaled[!training])
}

initial_digest <- digestor(censor.dt, refpredictors, training_locations)

temporal_data_slice <- melt(initial_digest$raw[, .SD, .SDcols = c(1, grep("hr", names(initial_digest$raw)))], id.var = "location_id")
temporal_data_slice[grepl("log", variable), measure := sub("_hr_.+","", variable)]
temporal_data_slice[!grepl("log", variable), measure := "usage"]
temporal_data_slice[, hour:= as.integer(gsub("[^\\d]","", variable, perl=T))]
setkey(temporal_data_slice, location_id, measure, hour)

peaks <- temporal_data_slice[, list(peak=which.max(value)-1), by=list(location_id, measure)]