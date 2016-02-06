#!/usr/bin/env Rscript

rm(list=ls())

args <- commandArgs(trailingOnly = T)

require(data.table)
require(ggplot2)

src <- readRDS(args[1])

scales <- c(weeks=60*60*24*7)
tarscale <- "weeks"

.ign <- ggsave(args[2], 
  ggplot(src[,
    list(lifetime=((depart-arrive)/(60*60*24*7))),
    keyby=location_id
  ]) + theme_bw() +
    aes(x=lifetime) +
    geom_bar(binwidth=1) + labs(x="weeks of hotspot life", y="hotspots with that duration")
)