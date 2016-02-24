#!/usr/bin/env Rscript
## read in raw input

rm(list=ls())

require(data.table)
require(igraph)
require(parallel)

slice <- function(dt, low, high) {
  sub <- dt[start < high*24*3600 & low*24*3600 < end,.N,by=list(user.a, user.b)]
  remap_ids <- setkey(sub[,list(user_id=unique(c(user.a,user.b)))], user_id)[, new_user_id := .GRP, by=user_id]
  relabelled <- data.table(
    user.a=remap_ids[sub[,list(user_id=user.a)]]$new_user_id,
    user.b=remap_ids[sub[,list(user_id=user.b)]]$new_user_id,
    score=sub$N
  )
  list(res=relabelled, mp=remap_ids)
}

emptygraph <- data.table(user_id=integer(), community=integer())

resolve <- function(base.dt, intDays, winDays, mxinc=NA, st = base.dt[1, floor(start/60/60/24)]) {
  n <- min(ceiling(base.dt[,(max(end)-min(start))/60/60/24]/intDays), mxinc, na.rm = TRUE)
  targets <- 1:n
  completed <- as.integer(gsub(".rds","",list.files(gsub("\\.rds","", outfile))))
  want <- targets[c(-completed,-(n+1))]
  #  system.time(
  mclapply(want, function(inc) with(slice(base.dt, st + inc*intDays-winDays, st + inc*intDays), {
    resfile <- gsub("\\.rds",sprintf("/%02d.rds",inc), outfile)
    if (dim(res)[1] == 0) {
      store <- emptygraph
    } else {
      gg <- graph(t(res[,list(user.a, user.b)]), directed=F)
      E(gg)$weight <- res$score
      comps <- components(gg)
      dn <- which(comps$csize <= 60) # components to treat as their own communities
      newuids <- which(comps$membership %in% dn)
      commap <- rep(NA, max(dn))
      commap[dn] <- 1:length(dn)
      newcoms <- commap[comps$membershi[newuids]]
      init <- mp[newuids, list(user_id, community=newcoms)]
      an <- (1:comps$no)[-dn]
      store <- Reduce(
        function(base, add) {
          offset <- base[,max(community)]
          rbind(base, rbindlist(mapply(function(comm, id) {
            mp[comm, list(user_id, community=id)]
          }, add, 1:length(add)+offset, SIMPLIFY = F)))
        },
        lapply(an, function(tr) {
          ggs <- induced_subgraph(gg, which(comps$membership == tr))
          cs <- cluster_spinglass(ggs)
          redn <- sum(sizes(cs)==1)
          while(redn != 0) {
            newn <- length(cs)-redn
            cs <- cluster_spinglass(ggs, spins = newn)
            redn <- sum(sizes(cs)==1)
          }
          communities(cs)
        }),
        init
      )
    }
    saveRDS(
      store,
      resfile
    )
  }), mc.cores = crs)
}

args <- commandArgs(trailingOnly = T)
# args <- c("input/raw-pairs.rds", "30", "30", "input/background-clusters/spin-glass/30-30.rds")
if (length(args)<4) stop("too few arguments to background-spinglass.R: ", args)

raw.dt <- readRDS(args[1])
raw.dt[
  user.b < user.a,
  `:=`(user.b = user.a, user.a = user.b)
  ]
setkey(raw.dt, start, end, user.a, user.b)

intervalDays <- as.integer(args[2])
windowDays <- as.integer(args[3])
outfile <- args[4]

crs <- min(as.integer(Sys.getenv("PBS_NUM_PPN")), detectCores(), na.rm = T)

resolve(raw.dt, intervalDays, windowDays, mxinc = 20)
