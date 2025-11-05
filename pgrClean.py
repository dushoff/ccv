import re
from sys import argv
script, infile = argv

def read_pgr_records(pgr_filename):
    # Read the file and split into paragraphs separated by blank lines
    with open(pgr_filename, 'r', encoding='utf-8') as f:
        lines = [ln.rstrip('\n') for ln in f]

    paragraphs = []
    cur = []
    for ln in lines:
        if ln.strip() == '':
            if cur:
                paragraphs.append(cur)
                cur = []
        else:
            cur.append(ln)
    if cur:
        paragraphs.append(cur)

    # Parse each paragraph into a dict of {key: value}
    records = []
    for para in paragraphs:
        rec = {}
        for ln in para:
            if ':' not in ln:
                continue
            k, v = [x.strip() for x in ln.split(':', 1)]
            rec[k] = v
        if rec:
            records.append(rec)

    return records

# --- Inline: combine records with the same Presentation field and emit cleaned .pgr ---

# We assume read_pgr_records(pgr_filename) exists above and returns List[Dict[str, str]].

records = read_pgr_records(infile)

# Group by 'Presentation' (exact string). Records missing 'Presentation' are kept separate.
groups = []  # list of (group_key, [records]) preserving first-seen group order
group_index_by_key = {}
missing_pres_counter = 0

for rec in records:
    pres = rec.get('Presentation', None)
    if pres is None or pres == '':
        missing_pres_counter += 1
        key = f'__MISSING_PRESENTATION__#{missing_pres_counter}'
    else:
        key = pres
    if key not in group_index_by_key:
        group_index_by_key[key] = len(groups)
        groups.append((key, []))
    groups[group_index_by_key[key]][1].append(rec)

# Combine each group according to rules and print as .pgr (paragraph per combined record)
first_group = True
for group_key, group_recs in groups:
    # Collect unique values per field in first-seen order
    values_by_field = {}   # field -> list of unique values (strings) in encounter order
    field_order = []       # order fields by first appearance across the group's records (excluding Presentation)
    presentation_value = None

    for rec in group_recs:
        # Capture Presentation (first seen)
        if presentation_value is None and 'Presentation' in rec:
            presentation_value = rec['Presentation']
        # Visit fields in insertion order
        for k, v in rec.items():
            if k == 'Presentation':
                continue
            if k not in values_by_field:
                values_by_field[k] = []
                field_order.append(k)
            if v not in values_by_field[k]:
                values_by_field[k].append(v)

    # Start a new paragraph
    if not first_group:
        print()
    first_group = False

    # Ensure Presentation line appears first; if none captured, print empty
    if presentation_value is None:
        presentation_value = ''
    print(f'Presentation: {presentation_value}')

    # Emit other fields according to conflict rules
    for k in field_order:
        vals = values_by_field[k]
        if len(vals) <= 1:
            # Single unique value
            print(f'{k}: {vals[0]}')
        else:
            # Multiple distinct values: enumerate as k_F1, k_F2, ...
            for i, vv in enumerate(vals, start=1):
                print(f'{k}_F{i}: {vv}')
