We are going to build a system to manage ccv subsections. For each subsection, we will have a default format. For example, the presentations format looks like this: 

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
* ignores comments (\s*#.*)
* ignores fields that match the template
* drops the leading tab

----------------------------------------------------------------------

It's ok, just give me the script. I don't want it to run anyway, I want to embed it in a script which is setting the values of infile and template

----------------------------------------------------------------------

Please just write to stdout

----------------------------------------------------------------------


Map Title to Presentation Title, Venue to Conference


I would like a python script to convert records of type pgr:

Title: Transmission intervals in disease modeling
Venue: Math Ecology and Math Epidemiology Workshop
Date: May 2023
Address: Hong Kong Polytechnic U.

to records of type ccv.xml


----------------------------------------------------------------------

----------------------------------------------------------------------

Oops!!

----------------------------------------------------------------------


Lots of extra blank lines here. The first record looks like this:

```
- Presentation Title: 'Bridging between statistics and science: Some philosophical claptrap'  #  (Name of the presentation)

Conference / Event Name: Banff International Research Station workshop on Mathematical and Statistical Challenges in Bridging Model Development, Parameter Identification and Model Selection in the Biological Sciences #  (The name of the event in which the person gave the presentation)

Location: Canada # e.g., Afghanistan, Albania, Antarctica... Full list: https://ccv-cvc.ca/schema/dataset-cv-lov.xml (The country where the conference took place)

City: Banff #  (The city where the conference/event took place)

Presentation Year: '2018' # In format yyyy (The year the presentation was given  )
```

It should look like this (no initial dash, no extra words, underscores, no extra line breaks; trim comments); also, something new: I'd like to lose the bracketing single quotes:

```
Presentation_Title: Bridging between statistics and science: Some philosophical claptrap
Conference: Banff International Research Station workshop on Mathematical and Statistical Challenges in Bridging Model Development, Parameter Identification and Model Selection in the Biological Sciences
Location: Canada
City: Banff
Presentation_Year: 2018
```


----------------------------------------------------------------------

import re
from sys import argv
script, infile, template = argv


----------------------------------------------------------------------

You're not properly ignoring the early less-indented lines. You are parsing the first line in the paragraph as starting with "-". That dash should be thrown away after recognition.	

----------------------------------------------------------------------

The record paragraphs look pretty good, but you're no longer dropping the fields that are always default. You can drop those from the header paragraph too.

Let's remove dashes and question marks from our identifiers

The record paragraph still has issues. It looks like this
```
Field Mapping:
Presentation_Year:_'': Presentation Year: ''
Co-Presenters:: Co-Presenters: null
Keynote?:: Keynote?: No
URL:: URL: null
Conference: Conference / Event Name:
-: - Presentation Title: 'Title'
Contributions:: Contributions:
Description: Description / Contribution Value: null
Competitive?:: Competitive?: null
Presentations:: Presentations:
City:: City:
Main: Main Audience: Researcher
Location:: Location:
Invited?:: Invited?: Yes
```

There's something wrong with the Presentation Title line; you didn't pre-parse the initial "- "

There's a lot of extra stuff in the header paragraph. We don't need the first line, and we dont need the second colon on any line, nore the default values. Also, I didn't say it but if we don't drop any information, or only drop punctuation, let's skip the field altogether. So we don't need a Location field, and the Main field should read simply "Main: Main Audience".

----------------------------------------------------------------------

Remember to drop backticks at the beginning and end of scripts

Presentation Title is still parsed wrong in the header paragraph; also both that and Presentation_Year should not be there at all, since they do not “drop information”.

----------------------------------------------------------------------

Header paragraph is worse now. First field is still parsed wrong, and still not properly eliminated. Necessary fields are gone. 

----------------------------------------------------------------------

I think the code is all correct now except that you are still not stripping the initial (paragraph-separating) dash early enough.

----------------------------------------------------------------------

The identifiers that drop only punctuation are (improperly) back in the header, as is (mysteriously) one of the two should-be-identical Presentation_Year and Presentation_Title. The record paragraphs are back to using the yaml identifiers instead of the desired pgr identifiers.

