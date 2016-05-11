
rm(list=ls())

args <- commandArgs(trailingOnly = T)

require(reshape2); require(data.table);

output <- readRDS(args[1])

filled_means <- dcast.data.table(output[!is.nan(shapes),{
  res <- rep(0, length.out=24)
  res[login_hour+1] <- means
  list(hour=0:23, means = res)
}, keyby=location_id], location_id ~ hour, value.var = "means")

write.table(filled_means, file=stdout(), sep=",", row.names = F, col.names = F)