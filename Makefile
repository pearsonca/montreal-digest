
include references.mk
include $(REFDIR)/references.mk

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

$(INBASE)/filter/location_stats.rds: $(INBASE)/filter/input.rds

$(INBASE)/filter/location_%.csv: filter/location_%.R $(INBASE)/filter/location_stats.rds
	$(R) $^ > $@

# clustering computations

$(INBASE)/clustering/vonMisesFisher.rds: $(INBASE)/filter/input.rds | $(INBASE)/clustering


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

define basebgrule
$(call factorial2dir,$(1))

$(INBASE)/background/$(1)/ints $(INBASE)/background/$(1)/base: | $(INBASE)/background/$(1)
	mkdir $$@

$(INBASE)/background/$(1)/ints/%.rds: background/intervals.R $(INBASE)/raw/pairs.rds | $(INBASE)/background/$(1)/ints
	$(R) $$^ $(subst /,$(SPACE),$(1)) $$* > $$@

$(subst /,-,$(1))-ALLINTERVALS := $(addprefix $(INBASE)/background/$(1)/ints/,$(shell $(R) background/mkints.R $(INBASE)/raw/pairs.rds $(firstword $(subst /,$(SPACE),$(1)))))

all-$(subst /,-,$(1))-intervals: $$($(subst /,-,$(1))-ALLINTERVALS)

.PRECIOUS: $(INBASE)/background/$(1)/ints/%.rds

background/background-$(subst /,-,$(1))-base.pbs: all-$(subst /,-,$(1))-intervals | background/base_pbs.sh
	$$| $$(notdir $$(basename $$@)) $(1) $$(words $$($(subst /,-,$(1))-ALLINTERVALS)) > $$@

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

$(INBASE)/background/$(1)/acc/%.rds: background/accumulate.R $(INBASE)/background/$(dir $(1))base/%.rds | $(INBASE)/background/$(1)/acc
	$(R) $$^ $(subst /,$(SPACE),$(1)) $$* > $$@

$(INBASE)/background/$(1)/agg/%.rds: background/aggregate.R $(INBASE)/background/$(1)/acc/%.rds | $(INBASE)/background/$(1)/agg
	$(R) $$^ $$* > $$@

$(INBASE)/background/$(1)/pc/%.rds: background/pc.R $(INBASE)/background/$(1)/agg/%.rds | $(INBASE)/background/$(1)/pc
	$(R) $$^ $$(subst /,$(SPACE),$$*) > $$@

endef

# foreach item in bg factorial, generate make rules for all the backgrounds
$(foreach comb,$(BG-FACTORIAL),\
$(eval $(call bgrule,$(comb)))\
)