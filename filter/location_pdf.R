
rm(list=ls())

args <- commandArgs(trailingOnly = T)

require(reshape2); require(data.table);

output <- readRDS(args[1])

# output[shapes == NaN] returns ~10% of rows, however only ~.1 of usage.  So: elimate.
# discard times w/ login durations cannot be determined

filled_pdf <- dcast.data.table(output[!is.nan(shapes),{
  res <- rep(0, length.out=24)
  res[login_hour+1] <- usage / sum(usage)
  list(hour=0:23, prop = res)
}, keyby=location_id], location_id ~ hour, value.var = "prop")

write.table(filled_pdf, file=stdout(), sep=",", row.names = F, col.names = F)