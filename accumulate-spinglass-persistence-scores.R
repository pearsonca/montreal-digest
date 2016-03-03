#!/usr/bin/env Rscript
## read in raw input

# setwd(sprintf("%s/muri-overall", Sys.getenv("GITPROJHOME")))
require(data.table)
require(igraph)
require(parallel)

rm(list=ls())

args <- commandArgs(trailingOnly = T)
# args <- c("input/background-clusters/spin-glass/30-30-acc", "input/background-clusters/spin-glass/30-30-acc.rds")
tardir <- args[1]
scorefiles <- list.files(tardir, "^\\d+.rds$", full.names = T)

disc <- 0.9
censor <- disc^6 # i.e., no activity in six months

readIn <- function(fn) readRDS(fn)[,score,keyby=list(user.a,user.b,interval)]
storeres <- function(dt, was) {
  saveRDS(dt, sub(".rds","-acc.rds", was))
  dt
}

Reduce(function(prev, cur.filename) {
  newres <- rbind(readIn(cur.filename), prev[, score := score*disc ])
  ntrvl <- newres[,max(interval)]
  storeres(newres[,list(interval=ntrvl, score = sum(score)), keyby=list(user.a, user.b)][score > censor], cur.filename)
}, scorefiles[-1], storeres(readIn(scorefiles[1]), scorefiles[1]))

accfiles <- list.files(tardir, "acc", full.names = T)
saveRDS(rbindlist(lapply(accfiles, readRDS)), args[2])
