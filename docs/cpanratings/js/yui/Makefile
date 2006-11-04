
# VERSION=0.11.4
VERSION=yui

COMPS = yahoo dom event connection 
DIRS = $(patsubst %,$(VERSION)/build/%, $(COMPS))
FILES = $(foreach dir, $(DIRS), $(wildcard $(dir)/*-min.js)) yui/build/container/container_core-min.js

all: $(FILES)
	cat $(FILES) > yui.js

