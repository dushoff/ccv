xmldiff works well and seems to confirm that there is _no_ selection data in the XML!

The way to work around this is to select by simply not uploading what you don't want to show, but keep it safe elsewhere.

What to do about colons in fields? I guess that's what the backquotes are for.

##### 2025 Nov 06 (Thu)

Let's try this:
* Call my downloads xml (and track them in case of disaster)
* Use them to make make down.yaml, and then PGR
* Edit pgr by hand (track)
* Use them to make up.yaml and XML

For the future we can do branching, but for now just have a single download.xml? But shouldn't really download again now that we've started truncated updates.

No collab (so far) in downloads.xml, so can't play with that pipeline

##### 2026 Jul 26 (Sun)

Trying to figure out what's going on… 

Try not to download from CCV anymore. We should be building here and uploading. This means that we need to rebuild every section that we want to update.

Try to build a pubs something??

Current pubs stuff process whole CCV, lives in nsercMixing repo

No clear trace of what was done. Things are built from current.xml and tmp.xml, but only download.xml exists (including in log history).

##### 2026 Jul 28 (Tue)

Patched a bunch of ccvpatch logic, seems to kind of work now, try on siX

##### 2026 Jul 30 (Thu)

Making up.yaml now. What is actually in CCV? How do I curate and add things going forward?
