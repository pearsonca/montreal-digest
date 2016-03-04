#!/usr/bin/env Rscript
## read in raw input

rm(list=ls())

require(data.table)
require(igraph)
require(parallel)

remap <- function(dt) {
  remap_ids <- setkey(dt[,list(user_id=unique(c(user.a,user.b)))], user_id)[, new_user_id := .GRP, by=user_id]
  relabelled <- data.table(
    user.a=remap_ids[dt[,list(user_id=user.a)]]$new_user_id,
    user.b=remap_ids[dt[,list(user_id=user.b)]]$new_user_id,
    score=dt$score
  )
  list(res=relabelled, mp=remap_ids)
}

emptygraph <- data.table(user_id=integer(), community=integer())

resolve <- function(base.dt, output) with(remap(base.dt), {
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
    cat("finishing",output,"\n")
    saveRDS(
      store,
      output
    )
})

args <- commandArgs(trailingOnly = T)
# args <- c("input/background-clusters/spin-glass/30-15-pc/01.rds")
if (length(args)<1) {
  stop("too few arguments to spinglass-persistence-communities.R: ", args)
}

raw.dt <- readRDS(sub("pc/","acc/",args[1]))
raw.dt[
  user.b < user.a,
  `:=`(user.b = user.a, user.a = user.b)
  ]
setkey(raw.dt, interval, user.a, user.b)

targetfile <- args[1]
 
resolve(raw.dt, targetfile)
