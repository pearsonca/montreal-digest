#!/usr/bin/env Rscript

rm(list=ls())

args <- commandArgs(trailingOnly = T)

require(reshape2)
require(data.table)
require(ggplot2)

src <- readRDS(args[1])

weekdiv <- 60*60*24

weekly_incidence <- melt(src[,
  list(
    activate = (arrive/weekdiv) %/% 7,
    shutdown = (depart/weekdiv) %/% 7
  ),
  by=location_id
], id.vars = "location_id", variable.name = "event", value.name = "week")[,
  .N, keyby=list(event, week)
]

weekly_incidence[event=="shutdown", N := -N ]

.ign <- ggsave(args[2], 
  ggplot(weekly_incidence[week < 320]) +
   theme_bw() +
    aes(x=week, y=N, fill=event) + facet_grid(event ~ ., scales = "free_y") +
    labs(x="week", y="hotspots", color="event") +
    geom_bar(stat="identity", width=1)
)