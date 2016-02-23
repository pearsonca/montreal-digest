# precomputed communities review

rm(list=ls())
require(reshape2)
require(data.table)
require(bit64)
require(ggplot2)

args <- commandArgs(trailingOnly = T)
# args <- list.files("input/background-clusters/spin-glass","rds", full.names = T)
all <- rbindlist(lapply(args, function(fn) {
  readRDS(fn)[, scenario := gsub(".+/(\\d+-\\d+).rds","\\1", fn) ]
}))

qns <- all[,
  .N,
  keyby=list(scenario,interval,community)
][,
  {
    res <- as.list(quantile(N,p=c(0,0.25,0.5,0.75,1))) 
    # names(res) <- c("min","low","median","high","max")
    res
  },
  keyby=list(scenario,interval)
]

ggplot(melt.data.table(qns, id.vars = c("scenario","interval"), variable.name = "quantile", value.name = "community size")) +
  aes(x=interval, y=`community size`, color=quantile) +
  facet_grid(. ~ scenario, scales = "free_x") +
  geom_line() + theme_bw() + scale_y_log10()

cns <- all[,
  list(count=max(community)),
  keyby=list(scenario,interval)
]

ggplot(cns) + aes(x=interval, y=count) + facet_grid(. ~ scenario, scales="free_x") + geom_step() + theme_bw()
