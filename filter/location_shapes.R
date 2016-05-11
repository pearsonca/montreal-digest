
rm(list=ls())

args <- commandArgs(trailingOnly = T)

require(reshape2); require(data.table);

output <- readRDS(args[1])

filled_shapes <- dcast.data.table(output[!is.nan(shapes),{
  res <- rep(0, length.out=24)
  res[login_hour+1] <- shapes
  list(hour=0:23, shapes = res)
}, keyby=location_id], location_id ~ hour, value.var = "shapes")

write.table(filled_shapes, file=stdout(), sep=",", row.names = F, col.names = F)
