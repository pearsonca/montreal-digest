#!/usr/bin/env Rscript

rm(list=ls())

args <- commandArgs(trailingOnly = T)

require(data.table)
require(ggplot2)

src <- readRDS(args[1])

scales <- c(weeks=60*60*24*7)
tarscale <- "weeks"

.ign <- ggsave(args[2], 
  ggplot(src) +
   theme_bw() +
   aes(x=location_id, ymin=arrive/scales[tarscale], ymax=depart/scales[tarscale]) +
   geom_linerange() +
   coord_flip() + labs(y=paste0(tarscale," since start"), x="hotspot")
)