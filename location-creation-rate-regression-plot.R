#!/usr/bin/env Rscript

rm(list=ls())

args <- commandArgs(trailingOnly = T)

require(reshape2)
require(data.table)
require(ggplot2)

src <- readRDS(args[1])

# weekdiv <- 60*60*24
# 
# weekly_incidence <- melt(src[,
#   list(
#     activate = (arrive/weekdiv) %/% 7,
#     shutdown = (depart/weekdiv) %/% 7
#   ),
#   by=location_id
# ], id.vars = "location_id", variable.name = "event", value.name = "week")[,
#   .N, keyby=list(event, week)
# ]
# 
# weekly_incidence[event=="shutdown", N := -N ]
# 
# .ign <- ggsave(args[2], 
#   ggplot(weekly_incidence[week < 320]) +
#    theme_bw() +
#     aes(x=week, y=N, fill=event) + facet_grid(event ~ ., scales = "free_y") +
#     labs(x="week", y="hotspots", color="event") +
#     geom_bar(stat="identity", width=1)
# )

ref <- src[,
  list(
    creation_day = (arrive/60/60) %/% 24,
    shutdown_day = (arrive/60/60) %/% 24
  ),
  by=location_id
][,
  .N,
  by=creation_day
][,
  list(creation_day = creation_day - min(creation_day), N)
]

zeros <- data.table(
  creation_day = 0:max(ref$creation_day),
  N = 0,
  key = "creation_day"
)
creations <- merge(ref, zeros, all=TRUE)[,
  list(N = max(N.x, N.y, na.rm=T)),
  keyby = creation_day
]

.ign <- ggsave(args[2], 
  ggplot(creations) + theme_bw() +
    aes(x=creation_day, y=N) +
    stat_smooth(method = "glm") + geom_point() +
    labs(x="creation day", y="hotspots created")
)