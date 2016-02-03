#!/usr/bin/env Rscript

rm(list=ls())

args <- commandArgs(trailingOnly = T)

require(data.table)
require(ggplot2)

src <- readRDS(args[1])

scales <- c(weeks=60*60*24*7)
tarscale <- "weeks"

p <- ggplot(src[,list(t_min=min(login),t_max=max(logout)), keyby=location_id]) +
  theme_bw() +
  aes(x=location_id, ymin=t_min/scales[tarscale], ymax=t_max/scales[tarscale]) +
  geom_linerange() +
  coord_flip() + labs(y=paste0(tarscale," since start"), x="hotspot")

ggsave(args[2], p)