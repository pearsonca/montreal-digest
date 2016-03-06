
relabeller <- function(dt) {
  ret <- if (dim(dt)[1]) {
    remap_ids <- setkey(dt[,list(user_id=unique(c(user.a,user.b)))], user_id)[, new_user_id := .GRP, by=user_id]
    relabelled <- data.table(
      user.a=remap_ids[dt[,list(user_id=user.a)]]$new_user_id,
      user.b=remap_ids[dt[,list(user_id=user.b)]]$new_user_id
    )
    for (nm in grep("user", names(dt), invert = T, value = T)) {
      relabelled[[nm]] <- dt[[nm]]
    }
    list(res=relabelled, mp=remap_ids)
  } else list(res=dt, mp=data.table(user_id=integer(0), new_user_id=integer(0)))
  ret
}

## - make the user.a <=> user.b graph, gg
## - identify the components, comps
## - separate the components that are *not* already a community (size > ulim), leftovers
## - for the k components that are small enough to already be communities,
##   label those users as in communities 1:k, according to their components
basicGraphPartition <- function(res, ulim=60) {
  gg <- graph(t(res[,list(user.a, user.b)]), directed=F)
  E(gg)$weight <- res$score
  comps <- components(gg)
  
  leftovers <- which(comps$csize > ulim)
  completeCommunities <- (1:comps$no)[-leftovers] # components to treat as their own communities
  
  base <- if (length(completeCommunities)) {
    newuids <- which(comps$membership %in% completeCommunities)
    commap  <- rep.int(NA, max(completeCommunities))
    commap[completeCommunities] <- 1:length(completeCommunities)
    data.table(
      new_user_id=newuids,
      community=commap[comps$membership[newuids]]
    ) #  mp[newuids, list(user_id, community=newcoms)]
  } else data.table(new_user_id=integer(0), community=integer(0))
  
  list(gg=gg, comps=comps, leftovers=leftovers, base=base)
}

targettedGraphPartition <- function(target, grp, compnts) {
  origs <- which(compnts$membership == target) # which vertices are we decomposing into communities?
  ggs <- induced_subgraph(grp, origs) # get subgraph; n.b.: this re-indexes vertices
  cs <- cluster_spinglass(ggs) # find spin-glass communities
  while(redn <- sum(sizes(cs)==1)) {
    # if communities of size 1 are identified, re-spinglass with fewer spins
    # until all communities are size > 1
    cs <- cluster_spinglass(ggs, spins = length(cs)-redn)
  }
  lapply(communities(cs), function(comm) origs[comm]) # so convert them back to original indices
}

## have gg, comps, leftover, base from with
buildStore <- function(res, ulim=60) with(
  basicGraphPartition(res, ulim), Reduce(
  function(base, add) rbindlist({
    c(list(base),mapply(
      data.table,
      new_user_id = add,
      community = 1:length(add)+base[,max(community)],
      SIMPLIFY = F
    ))
  }),
  lapply(leftovers, targettedGraphPartition, grp=gg, compnts=comps),
  base
))

# TODO accomplish via join?
originalUserIDs <- function(store, idmap) {
  idmap[store$new_user_id, list(user_id, community=store$community)]
}