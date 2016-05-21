
INTERVALS := 15 30
WINDOWS := 15 30
# no window smaller than interval
FORBID := 30/15
SCORING := drop-only censor bonus

BG-BASE-FACTORIAL :=

$(foreach inter,$(INTERVALS),\
 $(foreach window,$(WINDOWS),\
  $(eval BG-BASE-FACTORIAL += $(inter)/$(window))\
))

BG-BASE-FACTORIAL := $(filter-out $(FORBID),$(BG-BASE-FACTORIAL))

BG-FACTORIAL :=

$(foreach base,$(BG-BASE-FACTORIAL),\
 $(foreach score,$(SCORING),\
  $(eval BG-FACTORIAL += $(base)/$(score))\
))