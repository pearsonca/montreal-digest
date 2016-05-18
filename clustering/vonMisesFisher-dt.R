## compute von Mises Fisher clusters

# get detail input

args <- commandArgs(trailingOnly = T)
# args <- "input/digest/filter/detail_input.rds"
# inpath, assumpath, outpath

require(data.table)
require(movMF)

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

temporal_data_slice <- melt(raw[, .SD, .SDcols = c(1, grep("hr", names(raw)))], id.var = "location_id")
temporal_data_slice[grepl("log", variable), measure := sub("_hr_.+","", variable)]
temporal_data_slice[!grepl("log", variable), measure := "usage"]
temporal_data_slice[, hour:= as.integer(gsub("[^\\d]","", variable, perl=T))]
setkey(temporal_data_slice, location_id, measure, hour)

peaks <- temporal_data_slice[, list(peak=which.max(value)-1), by=list(location_id, measure)]

psi <- peaks[measure == "usage", peak/24*pi] # usage angle
tht <- peaks[measure == "login", peak/24*pi] # login angle
phi <- peaks[measure == "logout", peak/24*pi] # logout angle
x0 <- cos(psi)
x1 <- sin(psi)*cos(tht)
x2 <- sin(psi)*sin(tht)*cos(phi)
x3 <- sin(psi)*sin(tht)*sin(phi)
pos <- cbind(x0,x1,x2,x3)

#lls <- lapply(8:11, function(k) movMF(pos, k, list(maxiter=10000, nruns=20)))
#bics <- lapply(lls, stats::BIC)
vmfmodel <- movMF(pos, 3, list(maxiter=10000, nruns=20))
temporal_cluster <- data.table(
  location_id = peaks[measure == "usage"]$location_id,
  vMFcluster = predict(vmfmodel, pos), key="location_id"
)
vmfrename <- peaks[measure == "usage"][temporal_cluster][,
  list(med=median(peak)), by=vMFcluster
][, vMFcluster, keyby=med][,
  list(vMFcluster, rename=factor(c("early","middle","late"), levels=c("early","middle","late"), ordered = T))]
temporal_cluster <- merge(temporal_cluster, vmfrename, by="vMFcluster")[,list(vMFcluster=rename), keyby=location_id]

saveRDS(temporal_cluster, pipe("cat","wb"))