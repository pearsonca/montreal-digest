## compute variability clusters

args <- commandArgs(trailingOnly = T)
# args <- "input/digest/filter/detail_input.rds"
# inpath, assumpath, outpath

require(data.table)

res <- readRDS(args[1])

## get peaks dt...?

with_usage_zeros <- function(orig.usage, zeros) orig.usage[zeros][,
                                                                  list(usage = ifelse(is.na(usage), i.usage, usage)), keyby=key(zeros)
                                                                  ]


process_hour_rle <- function(prefix) {
  hrsind <- 0:23
  nms <- sapply(hrsind, function(h) sprintf("%s_hr_%.2d", prefix, h))
  function(hrrle) with(hrrle, {
    missing <- hrsind[!(hrsind %in% values)]
    res <- c(lengths, rep.int(0, length(missing)))[order(c(values, missing))] / sum(lengths)
    names(res) <- nms
    res
  })
}

hourly_zeros <- data.table(
  hour = 0:23,
  usage = 0, key = "hour"
)


login_parser <- process_hour_rle("login")
logout_parser <- process_hour_rle("logout")

refpredictors <- function(SD) with(SD, {
  duration <- logout - login
  total_login_time <- sum(duration)
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
  
  return(c(
    hourly_percent, as.list(login_hours), as.list(logout_hours)
  ))
})

raw <- res[, refpredictors(.SD), by=location_id]

freq_power <- function(ref, measure) {
  mn <- mean(as.matrix(ref[,-1,with=F]))
  fftref <- mvfft(t(ref[,-1,with=F])-mn)
  pwr <- Re(fftref*Conj(fftref))[1+1:12,]
  res <- t(pwr)
  dimnames(res)[[2]] <- paste0(as.integer(gsub("[^\\d]","",dimnames(res)[[2]], perl=T)), "_perday")
  cbind(melt(data.table(cbind(location_id = ref[,location_id], res)), id.var = "location_id"), measure = measure)
}


ref_usage <- raw[,.SD,.SDcols=c(1,grep("^hr", names(raw)))]
ref_login <- raw[,.SD,.SDcols=c(1,grep("^login", names(raw)))]
ref_logout <- raw[,.SD,.SDcols=c(1,grep("^logout", names(raw)))]
pwr <- rbind(
  freq_power(ref_usage, "usage"),
  freq_power(ref_login, "login"),
  freq_power(ref_logout, "logout")
)

setkey(pwr, measure, location_id, variable)
peak_freq_cat <- pwr[,list(peak_freq = ifelse(variable[which.max(value)] == "1_perday","daily","multimode")), keyby=list(measure, location_id)]
tot_pwr <- pwr[,list(tot_pwr = sum(value)), keyby=list(measure, location_id)]
pwr_divisions <- tot_pwr[,{
  res <- as.list(quantile(tot_pwr, probs = c(1,2)/3))
  names(res) <- c("low","hi")
  res
}, keyby=measure]
pwr_cluster <- tot_pwr[pwr_divisions][peak_freq_cat][,
                                                     list(peak_freq, pwr_cat = ifelse(tot_pwr < low,"lo",ifelse(tot_pwr < hi, "med","hi"))),
                                                     keyby=list(measure, location_id)
                                                     ]

pre_pwr_clust <- data.table(dcast(pwr_cluster, location_id ~ measure, value.var = "pwr_cat"))
pwr_multi_clusters <- setorder(pre_pwr_clust[,.N,by=list(login, logout, usage)], -N)
reduced_pwr_clust <- pre_pwr_clust[, list(pwr_clust = factor(ifelse((login == logout) || (login == usage), login, logout), levels=c("lo","med","hi"), ordered=T)), keyby=location_id]

saveRDS(reduced_pwr_clust, pipe("cat","wb"))