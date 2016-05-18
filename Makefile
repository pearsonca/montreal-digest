
include references.mk
include $(REFDIR)/references.mk

# usage: $(call first,middles...,last)
wrap = $(addsuffix $(3),$(addprefix $(1),$(2)))

EMPTY :=
SPACE := $(EMPTY) $(EMPTY)

default:
	@echo hello world

INBASE := $(INDIR)/$(WORKINGDIR)
OUTBASE := $(OUTDIR)/$(WORKINGDIR)

## where intermediate calculations from digestion (for use in other calcs) go
$(INBASE): | $(INDIR)
	mkdir $@

## where digest-related analyses (e.g., characterizations of data set) go
$(OUTBASE): | $(OUTDIR)
	mkdir $@

R := /usr/bin/env Rscript

$(INBASE)/%.rds: %-dt.R
	$(R) $^ > $@

$(addprefix $(INBASE)/,raw filter clustering background): | $(INBASE)
	mkdir $@

# translated raw data

$(INBASE)/raw/input.rds: $(INDIR)/merged.o | $(INBASE)/raw

$(INBASE)/raw/pairs.rds: $(INDIR)/paired.o | $(INBASE)/raw

$(INBASE)/raw/location-lifetimes.rds: $(INBASE)/raw/input.rds


# filtered raw data

$(INBASE)/filter/input.rds: $(INBASE)/raw/input.rds $(INDIR)/assumptions.json | $(INBASE)/filter

$(INBASE)/filter/detail_input.rds: $(INBASE)/filter/input.rds

$(INBASE)/filter/location_stats.rds: $(INBASE)/filter/input.rds

$(INBASE)/filter/location_%.csv: filter/location_%.R $(INBASE)/filter/location_stats.rds
	$(R) $^ > $@

# clustering computations

CLUSTERDIMS := vonMisesFisher variability usage
CLUSTERRDS := $(call wrap,$(INBASE)/clustering/,$(CLUSTERDIMS),.rds)

$(CLUSTERRDS): $(INBASE)/filter/detail_input.rds | $(INBASE)/clustering

$(INBASE)/clustering/userrefs.rds: $(INBASE)/filter/detail_input.rds $(CLUSTERRDS) | $(INBASE)/clustering
$(INBASE)/clustering/locrefs.rds: $(CLUSTERRDS) | $(INBASE)/clustering
$(INBASE)/clustering/uprefs.rds: $(INBASE)/filter/detail_input.rds $(INBASE)/clustering/locrefs.rds $(INBASE)/clustering/userrefs.rds | $(INBASE)/clustering

covertprecursors: $(INBASE)/clustering/userrefs.rds $(INBASE)/clustering/locrefs.rds $(INBASE)/clustering/uprefs.rds $(INBASE)/filter/location_pdf.csv $(INBASE)/filter/location_cdf.csv $(INBASE)/filter/location_means.csv $(INBASE)/filter/location_shapes.csv

# full cluster info

# background processing

INTERVALS := 15 30
WINDOWS := 15 30
# no window smaller than interval
FORBID := 30/15
SCORING := drop-only censor bonus

define factorial1dir
$(INBASE)/background/$(1): | $(INBASE)/background
	mkdir $$@
endef

$(foreach inter,$(INTERVALS),$(eval $(call factorial1dir,$(inter))))

# assumes argument is of flavor a/b/c/etc, where last item is a directory to be constructed
define factorial2dir
$(INBASE)/background/$(1): | $(INBASE)/background/$(dir $(1))
	mkdir $$@
endef

BG-BASE-FACTORIAL :=

$(foreach inter,$(INTERVALS),\
 $(foreach window,$(WINDOWS),\
  $(eval BG-BASE-FACTORIAL += $(inter)/$(window))\
))

BG-BASE-FACTORIAL := $(filter-out $(FORBID),$(BG-BASE-FACTORIAL))

nfmt = $(shell printf '%03d' $(1))

$(foreach inter,$(INTERVALS),\
 $(eval $(inter)-LIMIT := $(shell $(R) background/maxinterval.R $(INBASE)/raw/pairs.rds $(inter)))\
)

seq2 = $(strip $(shell for i in $$(seq $(1) $(2)); do printf '%03d ' $$i; done))
seq = $(call seq2,1,$(1))

#$(info limit $(30-LIMIT))
#$(info $(call seq,$(30-LIMIT)))
#$(info limit $($(firstword $(subst /,$(SPACE),30/15))-LIMIT))

getlim = $($(firstword $(subst /,$(SPACE),$(1)))-LIMIT)

define basebgrule
$(call factorial2dir,$(1))

$(INBASE)/background/$(1)/ints $(INBASE)/background/$(1)/base: | $(INBASE)/background/$(1)
	mkdir $$@

$(INBASE)/background/$(1)/ints/%.rds: background/intervals.R $(INBASE)/raw/pairs.rds | $(INBASE)/background/$(1)/ints
	$(R) $$^ $(subst /,$(SPACE),$(1)) $$* > $$@

$(subst /,-,$(1))-ALLINTERVALS := $(call wrap,$(INBASE)/background/$(1)/ints/,$(call seq,$($(firstword $(subst /,$(SPACE),$(1)))-LIMIT)),.rds)

all-$(subst /,-,$(1))-intervals: $$($(subst /,-,$(1))-ALLINTERVALS)

.PRECIOUS: $(INBASE)/background/$(1)/ints/%.rds

background/background-$(subst /,-,$(1))-base.pbs: all-$(subst /,-,$(1))-intervals | background/base_pbs.sh
	$$| $$(notdir $$(basename $$@)) $(1) $(call getlim,$(1)) > $$@

all-base-pbs: background/background-$(subst /,-,$(1))-base.pbs

$(INBASE)/background/$(1)/base/%.rds: background/base.R $(INBASE)/background/$(1)/ints/%.rds | $(INBASE)/background/$(1)/base
	$(R) $$^ > $$@

.PRECIOUS: $(INBASE)/background/$(1)/base/*.rds

endef

$(foreach b,$(BG-BASE-FACTORIAL),$(eval $(call basebgrule,$(b))))

BG-FACTORIAL :=

$(foreach base,$(BG-BASE-FACTORIAL),\
 $(foreach score,$(SCORING),\
  $(eval BG-FACTORIAL += $(base)/$(score))\
))

$(foreach b,$(BG-FACTORIAL),$(eval $(call factorial2dir,$(b))))

define bgrule

$(addprefix $(INBASE)/background/$(1)/,acc agg pc): | $(INBASE)/background/$(1)
	mkdir $$@

$(INBASE)/background/$(1)/acc/%.rds: background/accumulate.R $(call wrap,$(INBASE)/background/$(dir $(1)),base ints,/%.rds) | $(INBASE)/background/$(1)/acc
	$(R) $$^ $(lastword $(subst /,$(SPACE),$(1))) > $$@

background/background-$(subst /,-,$(1))-acc.pbs: | background/acc_pbs.sh
	$$| $$(notdir $$(basename $$@)) $(1) $(call getlim,$(1)) > $$@

all-acc-pbs: background/background-$(subst /,-,$(1))-acc.pbs

$(INBASE)/background/$(1)/pc/%.rds: background/persistence.R $(INBASE)/background/$(1)/agg/%.rds | $(INBASE)/background/$(1)/pc
	$(R) $$^ $(lastword $(subst /,$(SPACE),$(1))) > $$@

background/background-$(subst /,-,$(1))-pc.pbs: | background/pc_pbs.sh
	$$| $$(notdir $$(basename $$@)) $(1) $(call getlim,$(1)) > $$@

all-pc-pbs: background/background-$(subst /,-,$(1))-pc.pbs

endef

# foreach item in bg factorial, generate make rules for all the backgrounds
$(foreach comb,$(BG-FACTORIAL),\
$(eval $(call bgrule,$(comb)))\
)

dec = $(shell echo $(1)-1|bc|xargs printf '%03d')

define aggtar
$(INBASE)/background/$(1)/agg/$(2).rds: background/aggregate.R $(INBASE)/background/$(1)/acc/$(2).rds $(INBASE)/background/$(1)/agg/$(call dec,$(2)).rds | $(INBASE)/background/$(1)/agg
	$(R) $$^ > $$@
endef

define aggrule
$(INBASE)/background/$(1)/agg/001.rds: background/aggregate.R $(INBASE)/background/$(1)/acc/001.rds | $(INBASE)/background/$(1)/agg
	$(R) $$^ > $$@

$(foreach i,$(call seq2,2,$(call getlim,$(1))),\
$(call aggtar,$(1),$(i))
)

background/background-$(subst /,-,$(1))-agg.pbs: | background/agg_pbs.sh
	$$| $$(notdir $$(basename $$@)) $(1) $(call getlim,$(1)) > $$@

all-agg-pbs: background/background-$(subst /,-,$(1))-agg.pbs

endef

.SECONDEXPANSION:

$(foreach comb,$(BG-FACTORIAL),\
$(eval $(call aggrule,$(comb)))\
)