We are going to build a system to manage subsections from the Canadian common CV. For each subsection, we will have a default format. For example, the presentations format looks like this: 

  - Presentation Title: 'Title'  #  (Name of the presentation)
    Conference / Event Name: #  (The name of the event in which the person gave the presentation)
    Location: # e.g., Afghanistan, Albania, Antarctica... Full list: https://ccv-cvc.ca/schema/dataset-cv-lov.xml (The country where the conference took place)
    City: #  (The city where the conference/event took place)
    Main Audience: Researcher # One of: Researcher, Knowledge User, Decision Maker, General Public (The nature of the audience)
    Invited?: Yes # One of: Yes, No (Indicate whether the person was invited to present this information)
    Keynote?: No # One of: Yes, No (Indicate whether the person gave the keynote address at this event)
    Competitive?: null # One of: Yes, No (Indicate if participation in this event involved a competitive process.)
    Presentation Year: '' # In format yyyy (The year the presentation was given  )
    Description / Contribution Value: null #  (Provide a concise description of this contribution and its value to the area of research for which you are applying for funding)
    URL: null #  (The web address, if relevant )
    Co-Presenters: null #  (The names of other persons co-presenting this topic, if relevant)

Our first step will be to write a python script that takes a template file (filename stored in the variable template) and an input file (variable infile) and makes a .pgr file which:
* Treats the opening - in the record format as a record separator
* ignores comments started with # (and preceding whitespace)
* ignores fields that match the template default values
* drops the leading tab
* ignores lines which are indented with only 0 or 2 spaces and not 

The script should start like this:
```
import re
from sys import argv
script, infile, template = argv
```

and be tab-indented. Remember to drop backticks at the beginning and end of scripts

It should be inline for now (no functions) and should write to stdout

The output should be newline-separated paragraphs that look like this:
```
Title: Transmission intervals in disease modeling
Venue: Math Ecology and Math Epidemiology Workshop
Date: May 2023
Address: Hong Kong Polytechnic U.
```

You should construct pgr field names which uniquely identify field names from the template by: removing punctuation; dropping words not needed for disambiguation; replacing remaining necessary spaces with underscores. Drop bracketing single quotes from the values.

----------------------------------------------------------------------

Also, your script seems way too complicated. We don't need dropwords, just use words at the beginning as many as necessary. We don't need field keys that aren't in the template, and we don't need record keys at all...

----------------------------------------------------------------------

Thanks. Can we also have a header paragraph that:
* Uses only fields that appear in the record paragraphs
* Shows the mapping between the pgr field name and the yaml field name
* follows the same style as the record paragraphs

----------------------------------------------------------------------

Great. Now I want a script that will go reverse this. This is assuming that the original records match the template file. It will need to
* reconstruct original field ids (using the template file)
* replace defaults for fields not shown in each record
* replace the dashes that indicate new records (and lose the paragraph breaks)

----------------------------------------------------------------------

These are great. A couple of small changes. The lines with <=2 spaces and no initial dash at the beginning of the template files are section indicators.

The reconstruction script should echo these verbatim, and ignore them for the purposes of reconstructing the records.

----------------------------------------------------------------------

This script somehow does not print anything!

(Lots of directly typed NOISE)

----------------------------------------------------------------------

Header lines are incorrect (improperly indented, should be verbatim). They are also apparently not being ignored after echoing; their content is showing up in the records!


Almost perfect. The bracketing single quotes are not being reconstructed. And default values are being taken from the template only sometimes; they should be taken for any field that is missing from any record.

----------------------------------------------------------------------

Thanks, that all worked well. Now, I want to clean up my .pgr file. 
Do you remember the .pgr format?

I want a python script that starts with a function to read the records in a pgr file into a list of dictionaries, we will be using that again. 

Then I want an inline part of the script that goes through the list and combines records with the same Presentation field and lists all different values for any other field in the combined record:
* if two fields have different names, they should be preserved independently
* if two fields have the same name and same value, one can be ignored
* if two fields have the same name and different values I want them listed as separate fields using <fn>_F1, <fn>_F2, etc, where <fn> is the field name

The script should start like this:
```
import re
from sys import argv
script, infile, template = argv
```
