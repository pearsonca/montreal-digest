#!/usr/bin/env Rscript
rm(list=ls())
## invoke from command line, w/ rscripts as wd

# input/user.RData
# input/censor.RData
# input/locClusters.RData
# input/userPrefs.RData
# input/loc_probs.csv

suppressPackageStartupMessages({
  require(data.table)
  require(stats4)
  require(methods)
  require(optparse)
})

parse_args <- function(argv = commandArgs(trailingOnly = T)) {
  parser <- optparse::OptionParser(
    usage = "usage: %prog (un)matched (low|mid|high) (lo|med|hi) (early|middle|late) N I",
    description = "visualize persistence community results",
    option_list = list(
      optparse::make_option(
        c("--verbose","-v"),  action="store_true", default = FALSE,
        help="verbose?"
      ),
      optparse::make_option(
        c("--target","-t"), default = "input",
        help="target base directory; default input"
      )
    )
  )
  req_pos <- list(complement=function(ar){
    stopifnot(ar == "unmatched" | ar == "matched")
    ar
  }, lft_cat=function(ar){
    stopifnot(grepl("(low|mid|high)", ar))
    ar
  }, pwr_cat=function(ar){
    stopifnot(grepl("(lo|med|hi)", ar))
    ar
  }, tm_cat=function(ar){
    stopifnot(grepl("(early|middle|late)", ar))
    ar
  }, count=as.integer, id=as.integer)
  parsed <- optparse::parse_args(parser, argv, positional_arguments = length(req_pos))
  parsed$options$help <- NULL
  result <- c(mapply(function(f,c) f(c), req_pos, parsed$args, SIMPLIFY = F), parsed$options)
  if(result$verbose) print(result)
  result
}

with(parse_args(
#  c("matched", "mid", "lo", "late", "10", "001", "-v")
), {
  template_user_ids <- readRDS("input/user.RData")[(lifetime_main == lft_cat & pwr_main == pwr_cat & peak_main == tm_cat), user_id]
  if (verbose) print(template_user_ids)
  censor.dt <- readRDS("input/censor.RData")
  
  binomial_meetings_distro <- censor.dt[
    user_id %in% template_user_ids,
    .N,
    by=list(user_id, login_day)
  ][,		
    list(pbin = mean(sapply(N, function(n) min(n-1, 9)))/9),		
    keyby=user_id		
  ]
  
  invlogit <- function(a) 1/(1+exp(-a))
  
  gamma_usage_waiting_distro <- censor.dt[
    user_id %in% template_user_ids,
    list(diffs = diff(unique(sort(login_day)))),
    by=list(user_id)
  ][,		
    {
      res <- as.list(exp(mle(	
        function(logk, logmu, diffs) -sum(dgamma(diffs, shape=exp(logk), scale=exp(logmu-logk), log=T)),		
        start=list(logk=0, logmu=log(max(mean(diffs),1))),		
        fixed=list(diffs=diffs)		
      )@coef))
      names(res) <- c("shape","mean")
      res
    },		
    keyby=user_id		
  ]
  ressrc = readRDS("input/userPrefs.RData")[
    user_id %in% template_user_ids,		
    list(.N, p = list(pref)),		
    keyby=list(user_id, lifetime_cat, pwr_clust, vMFcluster)		
  ][binomial_meetings_distro][gamma_usage_waiting_distro]
  locs <- readRDS("input/locClusters.RData")[location_id %in% fread("input/loc_probs.csv")$V1]
  src <- if(complement=="matched") {
    locs[(lifetime_cat == lft_cat & pwr_clust == pwr_cat & vMFcluster == tm_cat), location_id]
  } else {
    locs[!(lifetime_cat == lft_cat & pwr_clust == pwr_cat & vMFcluster == tm_cat), location_id]
  }
  covertLoc <- sample(src, 1, replace = T)
  repl <- (count > length(template_user_ids))
  nm1 <- sprintf("%s/%s/%s/%s/%s/%02d/%03d-covert-in.csv", target, complement, lft_cat, pwr_cat, tm_cat, count, id)
  if (verbose) print(nm1)
  stopifnot(file.create(nm1))
  config1 <- file(nm1, open = "w")
  cat(sprintf("%d\n", covertLoc), file = config1)
  users <- sample(template_user_ids, count, replace = repl)
  ret <- ressrc[user_id %in% users][,{
    things <- Reduce(function(left, right) rbind(left, right),
     apply(.SD, 1, function(dtrow) {
       locs[
         lifetime_cat == dtrow$lifetime_cat & pwr_clust == dtrow$pwr_clust & vMFcluster == dtrow$vMFcluster,
         list(lc=sample(location_id, dtrow$N), ps=unlist(dtrow$p))
         ]
     }))
    strout = paste(shape[1], mean[1], pbin[1], paste(things$lc, collapse = " "), paste(things$ps, collapse = " "), collapse = " ")
    cat(strout,"\n", file = config1)
    strout
  }, by=user_id]
  flush(config1); close(config1)
  ret
})