## This is CCV -- for common CV stuff only!
current: target
-include target.mk
Ignore = target.mk

vim_session:
	bash -ic "vmt README.md notes.md"

Sources += $(wildcard *.md)

## -include makestuff/perl.def
pyvenv: ; $(cleanpyvenv)
-include makestuff/pyvenv.mk
-include makestuff/python.def

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

## Bump the number to force a pull of ccv_generator in other copies
Ignore += *.stamp
Makefile: ccv_generator01.stamp
ccv_generator%.stamp: | ccv_generator/Makefile
	- $(RM) ccv_generator*.stamp
	cd ccv_generator && $(MAKE) pull
	touch $@

Ignore += $(alldirs)

######################################################################

Sources += download.xml
Ignore += $(wildcard *.XML)

Ignore += *.yaml
.PRECIOUS: %.up.yaml
%.up.yaml: %.pgr %.tmp pgry.py
	$(PITH)

%.XML: %.up.yaml | ccv_generator.lpip
	$(generator) -i $< tmp.xml && $(MV) tmp.xml $@

######################################################################
## Using biography directory

pardirs += biography
hotdirs += biography

## A bit wasteful if I am always opening biography to work there
## Do need to Ignore, though
alldirs += $(pardirs)

######################################################################

## Pubs (journal articles) now curated in biography
## Maybe make the local into journal.PGR and have it follow a generic rule
## using PGR for made dependencies and pgr for legacy

ccv.journal.up.yaml: biography/ccvpubs.2020.newyear.pgr journal.tmp pgry.py
	$(PITH)
## ccv.journal.XML: 

######################################################################

## Not implemented, but implement if you have auth or connection problems
Sources += dataset-cv.xml
dataset-cv.xml:
	curl -Lko $@ https://ccv-cvc.ca/schema/$@

######################################################################

## Both the sections below were hand built. It would be fun to move them to biography and let them be cooler. But it also seems plausible to hand-truncate them for expiry date and just stay here.

######################################################################

## Collaborations
## Could be moved to biography/ but also seems kind of fine.
## time truncation is a reason to move it

## collab.up.yaml: collab.pgr collab.tmp pgry.py
## collab.XML: collab.pgr

## This was used to pull and set up template
## collab = "Activities/International Collaboration Activities"
Ignore += earn ## used to be a mirror

######################################################################

## Importing sections from a CCV download (should be rare)
## <download>.<sec>.down.PGR uses <download>.xml, <sec>.tmp and ccvsec.<sec>
## Made .PGRs are for comparing and harvesting into the hand-edited .pgrs

## download.journal.down.PGR: download.xml journal.tmp
## download.present.down.PGR: download.xml present.tmp
## download.collab.down.PGR: download.xml collab.tmp
ccvsec.present = Contributions/Presentations
ccvsec.journal = Contributions/Publications/Journal Articles
ccvsec.collab = Activities/International Collaboration Activities

.SECONDEXPANSION:
Ignore += *.down.yaml
%.down.yaml: $$(basename $$*).xml | ccv_generator.lpip
	$(generator) -i $< -f "$(ccvsec$(suffix $*))" $@

%.down.PGR: %.down.yaml $$(subst .,,$$(suffix $$*)).tmp ypgr.py
	$(PITH)

######################################################################

## Presentations

## present.pgr is the ONLY presentations pgr (edit by hand)
## (current, jd and new .present.pgr were merged into it and removed)

## Uploadable products are filtered from it via %.present.filter.txt
## nserc.present.XML: nserc.present.filter.txt present.pgr
Sources += $(wildcard *.filter.txt)
Ignore += *.PGR
.PRECIOUS: %.present.PGR %.present.up.yaml
%.present.PGR: present.pgr %.present.filter.txt pgrfilter.py
	$(PITH)

%.present.up.yaml: %.present.PGR present.tmp pgry.py
	$(PITH)

######################################################################

## Publications (journal articles)

## publications.pgr is the hand-edited source (was first.journal.pgr)
## It was made from biography/ (see Pubs, above); curate here from now on
## nserc.journal.XML: nserc.journal.filter.txt publications.pgr
.PRECIOUS: %.journal.PGR %.journal.up.yaml
%.journal.PGR: publications.pgr %.journal.filter.txt pgrfilter.py
	$(PITH)

%.journal.up.yaml: %.journal.PGR journal.tmp pgry.py
	$(PITH)

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

## jd.present.new.up.xml: jd.present.pgr
Ignore += *.up.xml
%.up.xml: %.yaml | ccv_generator.lpip
	$(generator) -i $< $@

Sources += $(wildcard *.tmp)
Sources += $(wildcard *.pgr)
## Ignore += *.pgr
## Made new .present.pgr files from downloads; we now keep only present.pgr
## Imports are now %.down.PGR (see Importing, above)
## current.present.pgr: current.present.yaml present.tmp ypgr.py
## %.present.pgr: %.present.yaml present.tmp ypgr.py
## 	$(PITH)

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

### Makestuff

Sources += Makefile

Ignore += makestuff
msrepo = https://github.com/dushoff

## ln -s ../makestuff . ## Do this first if you want a linked makestuff
Makefile: makestuff02.stamp
makestuff%.stamp: | makestuff
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
