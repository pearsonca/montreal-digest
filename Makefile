
include references.mk
include $(REFDIR)/references.mk

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

$(INBASE)/raw-input.rds: $(INDIR)/merged.o

$(INBASE)/raw-pairs.rds: $(INDIR)/paired.o

$(INBASE)/filtered-input.rds: $(DATAPATH)/raw-input.$(RDS) $(DATAPATH)/assumptions.$(JSN)
