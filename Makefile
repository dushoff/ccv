## This is CCV -- for common CV stuff only!
current: target
-include target.mk
Ignore = target.mk

vim_session:
	bash -ic "vmt README.md todo.md notes.md"

Sources += $(wildcard *.md)

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

## Generic: hand-edited (or filtered) pgr -> up.yaml -> uploadable XML
## .tmp files are section templates; fields whose values may contain
## colons need '' after the field name

Sources += $(wildcard *.pgr *.tmp *.filter.txt)
Ignore += *.yaml *.PGR $(wildcard *.XML)

.PRECIOUS: %.up.yaml
%.up.yaml: %.pgr %.tmp pgry.py
	$(PITH)

%.XML: %.up.yaml | ccv_generator.lpip
	$(generator) -i $< tmp.xml && $(MV) tmp.xml $@

## Collaborations (hand-built; uses the generic rule)
## collab.XML: collab.pgr collab.tmp

######################################################################

## Schema reference (rule not normally needed)
Sources += dataset-cv.xml
dataset-cv.xml:
	curl -Lko $@ https://ccv-cvc.ca/schema/$@

######################################################################

## Importing sections from a CCV download (should be rare)
## <download>.<sec>.down.PGR uses <download>.xml, <sec>.tmp and ccvsec.<sec>
## Made .PGRs are for comparing and harvesting into the hand-edited .pgrs

## download.journal.down.PGR: download.xml journal.tmp
## download.present.down.PGR: download.xml present.tmp
## download.collab.down.PGR: download.xml collab.tmp
Sources += download.xml
ccvsec.present = Contributions/Presentations
ccvsec.journal = Contributions/Publications/Journal Articles
ccvsec.collab = Activities/International Collaboration Activities

.SECONDEXPANSION:
%.down.yaml: $$(basename $$*).xml | ccv_generator.lpip
	$(generator) -i $< -f "$(ccvsec$(suffix $*))" $@

%.down.PGR: %.down.yaml $$(subst .,,$$(suffix $$*)).tmp ypgr.py
	$(PITH)

######################################################################

## Presentations
## present.pgr is the hand-edited source
## Uploadable products are filtered from it via %.present.filter.txt

## nserc.present.XML: nserc.present.filter.txt present.pgr
.PRECIOUS: %.present.PGR %.present.up.yaml
%.present.PGR: present.pgr %.present.filter.txt pgrfilter.py
	$(PITH)

%.present.up.yaml: %.present.PGR present.tmp pgry.py
	$(PITH)

######################################################################

## Publications (journal articles)
## publications.pgr is the hand-edited source (originally made from biography/)
## Uploadable products are filtered from it via %.journal.filter.txt

## nserc.journal.XML: nserc.journal.filter.txt publications.pgr
.PRECIOUS: %.journal.PGR %.journal.up.yaml
%.journal.PGR: publications.pgr %.journal.filter.txt pgrfilter.py
	$(PITH)

%.journal.up.yaml: %.journal.PGR journal.tmp pgry.py
	$(PITH)

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
