
import re
from sys import argv
script, infile, template = argv

# Load template fields and their default values
template_fields = {}
with open(template, 'r') as f:
    for line in f:
        if line.strip() and not line.strip().startswith('#'):
            field_line = line.lstrip().split('#')[0].strip()
            if ':' in field_line:
                key, val = map(str.strip, field_line.split(':', 1))
                template_fields[key] = val

# Normalize field names
def normalize(field):
    return re.sub(r'[-?]', '', field)

# Generate friendly names
friendly_map = {}
used = set()
for full in template_fields:
    norm = normalize(full)
    words = norm.split()
    for i in range(1, len(words)+1):
        candidate = '_'.join(words[:i])
        if candidate not in used:
            friendly_map[full] = candidate
            used.add(candidate)
            break

# Read input and skip header lines with word chars in first 3 columns
with open(infile, 'r') as f:
    lines = f.readlines()
content_lines = [line for line in lines if not re.match(r'^\s{0,2}\w', line)]

# Split into records using lines starting with '-'
records = []
current = []
for line in content_lines:
    stripped = line.lstrip()
    if stripped.startswith('-'):
        if current:
            records.append(current)
            current = []
        stripped = stripped[1:].lstrip()  # remove dash BEFORE adding to record
    current.append(stripped)
if current:
    records.append(current)

# Collect actual fields used in records
used_fields = set()
for record in records:
    for line in record:
        if not line.strip() or line.strip().startswith('#'):
            continue
        field_part = line.split('#')[0].strip()
        if ':' not in field_part:
            continue
        key, val = map(str.strip, field_part.split(':', 1))
        if key in template_fields and val == template_fields[key]:
            continue
        used_fields.add(key)

# Print field mapping only for renamed fields that drop or transform information
for full, friendly in friendly_map.items():
    val = template_fields[full].strip("'").lower()
    norm_full = normalize(full).replace(' ', '_')
    if full in used_fields and (friendly != norm_full or val in ['', 'null', 'no', 'yes', 'researcher']):
        print(f"{friendly}: {full}")
print()

# Print each record as a paragraph
for record in records:
    paragraph = []
    for line in record:
        if not line.strip() or line.strip().startswith('#'):
            continue
        field_part = line.split('#')[0].strip()
        if ':' not in field_part:
            continue
        key, val = map(str.strip, field_part.split(':', 1))
        if key in template_fields and val == template_fields[key]:
            continue
        friendly = friendly_map.get(key, normalize(key))
        val = val.strip("'")
        paragraph.append(f"{friendly}: {val}")
    if paragraph:
        print('\n'.join(paragraph))
        print()

