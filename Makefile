## This is CCV
current: target
-include target.mk
Ignore = target.mk

vim_session:
	bash -cl "vmt" notes.md

## -include makestuff/perl.def
-include makestuff/python.def

######################################################################

Sources += $(wildcard *.md)

######################################################################

## Comparisons for reverse engineering

Ignore += $(wildcard *.xml *.XML)

## pubchange.xmldiff: start.XML pubchange.XML 
%.xmldiff: start.XML %.XML 
	xmldiff $^ > $@

######################################################################

## Build a presentations section?

## Probably want to archive using tsv soon (see cron)
Sources += present.pgr

## current.present.yaml: current.xml
%.present.yaml: %.xml Makefile
	pyenv/bin/ccv_generator -i $< -f "Contributions/Presentations" $@

## current.present.up.xml: current.present.yaml
%.up.xml: %.yaml
	pyenv/bin/ccv_generator -i $< $@

Sources += $(wildcard *.tmp)
Sources += $(wildcard *.pgr)
## Ignore += *.pgr
## current.present.pgr: current.present.yaml present.tmp ypgr.py
%.present.pgr: %.present.yaml present.tmp ypgr.py
	$(PITH)

## current.present.new.yaml: current.present.pgr present.tmp pgry.py
## new.present.new.yaml: new.present.pgr present.tmp pgry.py
%.present.new.yaml: %.present.pgr present.tmp pgry.py
	$(PITH)

## new.present.new.up.xml: new.present.pgr
## current.present.new.up.xml: 
## current.present.up.xml: 
current.present.old.up.xml: current.present.old.yaml

## diff current.present.new.yaml: current.present.old.yaml > tmp.diff ##

######################################################################

## 2025 Nov 02 (Sun) How to behave? Import the tsvpgr stuff from cron??
## For now, just save different .pgrs!

######################################################################

pypath = pyenv

Ignore += *.yaml
## start.yaml: start.XML
%.yaml: tmp.xml | ccv_generator.pip
	$(ccvTrans)

ccvTrans = pyenv/bin/ccv_generator -i $< $@

ccv_generator.pip: | ruamel.yaml.pip

######################################################################

### Makestuff

Sources += Makefile

Ignore += makestuff
msrepo = https://github.com/dushoff

## ln -s ../makestuff . ## Do this first if you want a linked makestuff
Makefile: makestuff/00.stamp
makestuff/%.stamp: | makestuff
	- $(RM) makestuff/*.stamp
	cd makestuff && $(MAKE) pull
	touch $@
makestuff:
	git clone --depth 1 $(msrepo)/makestuff

-include makestuff/os.mk

-include makestuff/pyenv.mk

-include makestuff/git.mk
-include makestuff/visual.mk
