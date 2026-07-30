## This is CCV -- for common CV stuff only!
current: target
-include target.mk
Ignore = target.mk

vim_session:
	bash -ic "vmt README.md notes.md"

## -include makestuff/perl.def
pyvenv: ; $(cleanpyvenv)
-include makestuff/pyvenv.mk
-include makestuff/python.def

######################################################################

Sources += $(wildcard *.md)

## Comparisons for reverse engineering
## see notes.md

Ignore += *.xmldiff *.diff
## pubchange.xmldiff: start.XML pubchange.XML 
%.xmldiff: start.XML %.XML 
	xmldiff $^ > $@

######################################################################

## python package; now installed locally as a fork!

generator = pyvenv/bin/ccv_generator

alldirs += ccv_generator
ccv_generator.lpip: | ruamel.yaml.pip ccv_generator
	pyvenv/bin/pip install -e ../ccv_generator
	$(touch)

ccv_generator: | ../ccv_generator
	ln -fs ../$@/ .

../ccv_generator: ../%:
	cd .. && $(MAKE) $*

ccv_generator/Makefile: | ccv_generator
	cd ccv_generator && $(LNF) jd.mk Makefile

Ignore += $(alldirs)

######################################################################

## Generic rules

Sources += download.xml
Ignore += $(wildcard *.XML)

.PRECIOUS: %.up.yaml
%.up.yaml: %.pgr %.tmp pgry.py
	$(PITH)

%.XML: %.up.yaml | downloader.ccvpatch
	$(generator) -i $< tmp.xml && $(MV) tmp.xml $@

## downloader.ccvpatch: ccv_generator.lpip

######################################################################

## Experimenting 2026 Jul 29 (Wed)

## recipe line why needed??
download.all.yaml: download.xml
	$(generator) -i $< $@

%.all.yaml: %.xml
	$(generator) -i $< $@

######################################################################

## Build a pubs thing (with pre-processing)
## Sticking with the one-download idea right now 2026 Jul 29 (Wed)

journal.yaml: download.xml
	$(generator) -i $< -f "Contributions/Publications/Journal Articles" $@

## Making .tmp by editing yaml
Ignore += journal.PGR
journal.PGR: journal.yaml journal.tmp ypgr.py
	$(PITH)

jtest: journal.PGR
	$(CP) $< test.journal.pgr

## test.journal.up.yaml: test.journal.pgr journal.tmp
test.journal.up.yaml: test.journal.pgr journal.tmp pgry.py
%.journal.up.yaml: %.journal.pgr journal.tmp pgry.py
	$(PITH)

## test.journal.XML: test.journal.pgr journal.tmp
## test.journal.XML: test.journal.pgr test.journal.up.yaml

## First seriously curated journal.pgr
## Downloaded from CCV with collaborator symbols
## Eventually merge with all the Taiwan historical work?
## Code for adding is still in cron but should be easy to move if this directory weren't such a mess
## Added some symbols manually; need to upload to CCV
## first.journal.XML: first.journal.pgr

######################################################################

## Using biography directory

pardirs += biography
hotdirs += biography

## A bit wasteful if I am always opening biography to work there
## Do need to Ignore, though
alldirs += $(pardirs)

ccv.journal.up.yaml: biography/ccvpubs.2020.newyear.pgr journal.tmp pgry.py
	$(PITH)

## ccv.journal.XML: 

######################################################################

## Not implemented, but implement if you have auth or connection problems

Sources += dataset-cv.xml
dataset-cv.xml:
	curl -Lko $@ https://ccv-cvc.ca/schema/$@

######################################################################

## collab pipeline starts here (made it from David's stuff!)

## collab.up.yaml: collab.pgr collab.tmp pgry.py
## collab.XML: collab.pgr

######################################################################

## Stuff below here is hasty NSERC stuff

mirrors += earn

## Do we even need a collab variable now that we have collab.tmp?
collab = "Activities/International Collaboration Activities"

## Something broken here 2026 Jul 26 (Sun)
earn.collab.yaml: earn/ccv.xml | ccv_generator.lpip
	$(generator) -i $< -f $(collab) $@

## earn.collab.pgr: earn.collab.yaml collab.tmp ypgr.py
%.collab.pgr: %.collab.yaml collab.tmp ypgr.py
	$(PITH)

## download.present.yaml: download.xml
## current.present.yaml: current.xml
%.present.yaml: %.xml | ccv_generator.lpip
	$(generator) -i $< -f "Contributions/Presentations" $@

%.all.yaml: %.xml

######################################################################

## Debugging certificates or something?

## openssl s_client -connect ccv-cvc.ca:443 -servername ccv-cvc.ca -showcerts </dev/null 2>/dev/null | grep -E "^(subject|issuer)="

######################################################################

## pgrClean is a one-use script (not a pipeline script) for combining information from different sources to make a clean pgr for going forward
## The pgr files here are dummies or may not exist – may be good to use for short-term cleaning
new.pgr: dump.pgr pgrClean.py
	$(PITH)

######################################################################

## Build a presentations section?
Sources += present.md

## Probably want to archive using tsv soon (see cron)
Sources += present.pgr

## current.present.yaml: current.xml
%.present.yaml: %.xml | ccv_generator.lpip
	$(generator) -i $< -f "Contributions/Presentations" $@

## jd.present.new.up.xml: jd.present.pgr
Ignore += *.up.xml
%.up.xml: %.yaml | ccv_generator.lpip
	$(generator) -i $< $@

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

## pypath = pyvenv

Ignore += *.yaml
## start.yaml: start.XML
%.yaml: tmp.xml | ccv_generator.lpip
	$(ccvTrans)

ccvTrans = $(generator) -i $< $@

######################################################################

## Move this stuff to new package

## Bizarre auth fix from Claude 2026 Jul 26 (Sun)
## Maybe go back and cache whatever it's always getting from internet

## patching the package was not my first choice, but …
Sources += $(wildcard *.patch)
Ignore += *.patch
.PRECIOUS: %.patch
%.patch: %.py
	- diff -u $(generator)/$< $< > $@

## /home/dushoff/terminal/dirs/ccv/pyvenv/bin/pip show -f ccv-generator
## downloader.ccvpatch: downloader.patch
## downloader.ccvpatch: downloader.patch
%.ccvpatch: %.patch | ccv_generator.lpip
	patch $(generator)/$*.py < $<
	$(touch)

#### NOT USED
## This suppressed the wrong stuff, apparently
## sitecustomize.pypackage: sitecustomize.py
Ignore += *.pypackage
%.pypackage: %.py
	$(CP) $< pyvenv/lib/python3*/site-packages/
	$(touch)

## Confusing debug from Claude. -p reveals the make DB!
## make -p 2>/dev/null | grep -B2 -A6 '^earn\.collab\.pgr *:'
## make -r earn.collab.pgr
## make -rd earn.collab.pgr > make.log

######################################################################

### Makestuff

Sources += Makefile

Ignore += makestuff
msrepo = https://github.com/dushoff

## ln -s ../makestuff . ## Do this first if you want a linked makestuff
Makefile: makestuff/02.stamp
makestuff/%.stamp: | makestuff
	- $(RM) makestuff/*.stamp
	cd makestuff && $(MAKE) pull
	touch $@
makestuff:
	git clone --depth 1 $(msrepo)/makestuff

-include makestuff/os.mk

-include makestuff/mirror.mk
-include makestuff/hotcold.mk

-include makestuff/git.mk
-include makestuff/visual.mk
