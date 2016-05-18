# translate.R raw sim output => new user_ids (negatives), original location ids, correct times

args <- commandArgs(trailingOnly = T)
# args <- c("input/remap-location-ids.rds", "output/matched/mid/lo/late/10/001-covert-out.csv", "20649600")


require(data.table)

location_remap <- readRDS(args[1])[, location_id, keyby=new_location_id]
orig <- fread(args[2])

orig$V2 <- location_remap[orig$V2, location_id]
orig$V1 <- -orig$V1
offset <- as.integer(args[3])
orig$V3 <- orig$V3 + offset
orig$V4 <- orig$V4 + offset

write.table(orig, file = stdout(), row.names = F, col.names = F, sep = ",", quote = F)
