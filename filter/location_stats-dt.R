
rm(list=ls())

args <- commandArgs(trailingOnly = T)

censor.dt <- readRDS(args[1])

require(methods); require(stats4); require(data.table);

censor.dt[, login_hour := as.integer((login %% (60*60*24)) / 60 / 60)]

le <- function(logk, logmu, diffs) -sum(dgamma(diffs, shape=exp(logk), scale=exp(logmu-logk), log=T))

output <- censor.dt[, c(as.list({
  if (.N > 5) {
    sts <- list(logk=0, logmu=log(mean(logout-login)))
    dfs <- list(diffs=(logout-login))
    mest <- mle(
      le,
      start=sts,
      fixed=dfs
    )
    res <- exp(mest@coef)
  } else res <- c(NaN, mean(logout-login))
  names(res) <- c("shapes", "means")
  res
}), usage = sum(logout-login)),
    keyby=list(location_id, login_hour)
]

saveRDS(output, pipe("cat", "wb"))