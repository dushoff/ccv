
import re
from sys import argv
script, infile, template = argv

# Read template and build mapping of keys to defaults and pgr names
# Now explicitly ignore header/section lines: lines with <=2 spaces, no leading dash,
# and not a "key: value" field (after stripping comments).
tmpl_defaults = {}
pgr_map = {}
used_names = set()

with open(template, 'r', encoding='utf-8') as f:
    for raw in f:
        line_nl = raw.rstrip('\n')

        # Detect and ignore section/header lines BEFORE stripping comments
        leading = re.match(r'^([ \t]*)', line_nl).group(1)
        space_count = leading.count(' ')
        tab_count = leading.count('\t')
        no_cmt = re.sub(r'\s*#.*$', '', line_nl)
        if (tab_count == 0) and (space_count <= 2) and (not line_nl.lstrip().startswith('-')) and no_cmt.strip() and (':' not in no_cmt):
            # Ignore section line
            continue

        # Strip comments to parse actual fields
        line = re.sub(r'\s*#.*$', '', line_nl).strip()
        if not line or ':' not in line:
            continue
        if line.startswith('-'):
            line = line[1:].strip()

        key, val = [x.strip() for x in line.split(':', 1)]

        # Normalize default value for comparison (case-insensitive)
        if val.lower() == 'null':
            val = ''
        if (len(val) >= 2) and ((val[0] in "'\"") and (val[-1] == val[0])):
            val = val[1:-1]
        tmpl_defaults[key] = val.lower()

        # Build pgr key: take start words until unique (punct removed, spaces -> underscores)
        words = re.sub(r'[^A-Za-z0-9]+', ' ', key).strip().split()
        if not words:
            continue
        i = 1
        while i <= len(words):
            cand = '_'.join(words[:i])
            if cand not in used_names:
                pgr_map[key] = cand
                used_names.add(cand)
                break
            i += 1
        if key not in pgr_map:
            base = '_'.join(words)
            cand = base
            n = 2
            while cand in used_names:
                cand = f'{base}__{n}'
                n += 1
            pgr_map[key] = cand
            used_names.add(cand)

# First pass over input: parse into records, collecting only non-default template fields
records = []
current = []
with open(infile, 'r', encoding='utf-8') as f:
    for raw in f:
        line = re.sub(r'\s*#.*$', '', raw.rstrip('\n'))
        if not line.strip():
            continue

        # Record separator on opening '-'
        if line.lstrip().startswith('-'):
            if current:
                records.append(current)
                current = []
            line = line.lstrip()[1:].strip()
            if not line:
                continue

        # Drop exactly one leading tab if present
        if line.startswith('\t'):
            line = line[1:]

        content = line.strip()
        if ':' not in content:
            continue

        key, val = [x.strip() for x in content.split(':', 1)]

        # Only accept keys present in the template (header lines are already ignored in template)
        if key not in tmpl_defaults:
            continue

        # Clean value for output; normalize for default comparison
        if val.lower() == 'null':
            val_clean = ''
        else:
            val_clean = val
            if (len(val_clean) >= 2) and ((val_clean[0] in "'\"") and (val_clean[-1] == val_clean[0])):
                val_clean = val_clean[1:-1]
            val_clean = val_clean.strip()

        # Skip if matches template default (case-insensitive)
        if val_clean.lower() == tmpl_defaults[key]:
            continue

        pgr_key = pgr_map[key]
        current.append((pgr_key, val_clean, key))

# Append last record if any
if current:
    records.append(current)

# Collect used fields for header (order of first appearance across records)
used_order = []
seen_pgr = set()
for rec in records:
    for pgr_key, val, yaml_key in rec:
        if pgr_key not in seen_pgr:
            used_order.append((pgr_key, yaml_key))
            seen_pgr.add(pgr_key)

# Output header paragraph (mapping), then a blank line, then the records
if used_order:
    for pgr_key, yaml_key in used_order:
        print(f'{pgr_key}: {yaml_key}')
    print()

# Emit each record as its own paragraph
first_record = True
for rec in records:
    if not first_record:
        print()
    first_record = False
    for pgr_key, val, yaml_key in rec:
        print(f'{pgr_key}: {val}')
