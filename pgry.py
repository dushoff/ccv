import re
from sys import argv
script, infile, template = argv

# --- Parse template: ignore section/header lines for mapping/order; capture them verbatim ---
# Capture per-field exact prefix (spaces/tabs and "- " if present) to reproduce indentation.
section_lines = []          # verbatim section indicators (<=2 spaces indent, no tabs, no leading dash)
tmpl_keys = []              # YAML field keys in order (excluding section indicators)
tmpl_default_literal = {}   # YAML key -> literal default as in template (kept exactly)
pgr_map = {}                # YAML key -> pgr key (from start words until unique)
used_pgr = set()

field_prefix = {}           # YAML key -> exact prefix before the key (includes '- ' if present)
field_has_dash = {}         # YAML key -> bool (template line had a dash before the key)
global_dash_prefix = None   # first dashed prefix encountered in template (e.g., "  - ")
single_quote_field = {}     # YAML key -> bool (template default literal is enclosed in single quotes)

# Regex preserves exact whitespace, optional dash, then key:
keyline_re = re.compile(r'^([ \t]*)(-)?([ \t]*)([^:]+?):(.*)$')

with open(template, 'r', encoding='utf-8') as f:
    for raw in f:
        line_nl = raw.rstrip('\n')

        # Detect section/header lines BEFORE stripping comments:
        # <=2 spaces indent, no tabs, no leading dash (content may contain ':'), and non-empty ignoring comments.
        leading = re.match(r'^([ \t]*)', line_nl).group(1)
        space_count = leading.count(' ')
        tab_count = leading.count('\t')
        no_cmt = re.sub(r'\s*#.*$', '', line_nl)
        if (tab_count == 0) and (space_count <= 2) and (not line_nl.lstrip().startswith('-')) and no_cmt.strip():
            section_lines.append(line_nl)  # VERBATIM echo later
            continue

        # Strip trailing comments for parsing fields, but preserve indentation/dash via regex
        line_nc = re.sub(r'\s*#.*$', '', line_nl)
        if not line_nc.strip():
            continue
        m = keyline_re.match(line_nc)
        if not m:
            continue

        lead_ws, dash_char, after_dash_ws, key_text, val_text = m.groups()
        key = key_text.strip()
        val_lit = val_text.strip()  # keep literal default exactly as written

        # Record exact prefix and whether it had a dash
        prefix = lead_ws + (dash_char if dash_char else '') + after_dash_ws
        field_prefix[key] = prefix
        field_has_dash[key] = bool(dash_char)
        if dash_char and global_dash_prefix is None:
            global_dash_prefix = prefix  # first dashed prefix we saw

        # Keep field order and default literal as written
        tmpl_keys.append(key)
        tmpl_default_literal[key] = val_lit

        # Track whether the template default uses bracketing single quotes (e.g., 'X' or '')
        if re.fullmatch(r"\s*'.*'\s*", val_lit):
            single_quote_field[key] = True
        else:
            single_quote_field[key] = False

        # Build pgr key from start words (add words until unique)
        words = re.sub(r'[^A-Za-z0-9]+', ' ', key).strip().split()
        if not words:
            continue
        i = 1
        chosen = None
        while i <= len(words):
            cand = '_'.join(words[:i])
            if cand not in used_pgr:
                chosen = cand
                break
            i += 1
        if chosen is None:
            base = '_'.join(words) if words else 'Field'
            cand = base
            n = 2
            while cand in used_pgr:
                cand = f'{base}__{n}'
                n += 1
            chosen = cand
        pgr_map[key] = chosen
        used_pgr.add(chosen)

# Invert mapping for record lines: pgr -> yaml
pgr_to_yaml = {v: k for k, v in pgr_map.items()}
tmpl_key_set = set(tmpl_keys)

# --- Read the .pgr file: optional header paragraph, then record paragraphs (blank-line separated) ---

# Load all lines (defensively strip trailing comments)
lines = []
with open(infile, 'r', encoding='utf-8') as f:
    for raw in f:
        ln = raw.rstrip('\n')
        ln = re.sub(r'\s*#.*$', '', ln)
        lines.append(ln)

# Split into paragraphs by blank lines
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

# Detect header paragraph: must be entirely "pgr_key: yaml_key" where both sides match template-based mapping
header_map = {}
if paragraphs:
    first = paragraphs[0]
    is_header = True
    for ln in first:
        if ':' not in ln:
            is_header = False
            break
        k, v = [x.strip() for x in ln.split(':', 1)]
        if (k not in pgr_to_yaml) or (v not in tmpl_key_set):
            is_header = False
            break
    if is_header:
        for ln in first:
            k, v = [x.strip() for x in ln.split(':', 1)]
            header_map[k] = v
        paragraphs = paragraphs[1:]  # drop header

# Parse records from remaining paragraphs
records = []  # list of dict(yaml_key -> value)
for para in paragraphs:
    rec = {}
    for ln in para:
        if ':' not in ln:
            continue
        k, v = [x.strip() for x in ln.split(':', 1)]
        # Resolve YAML key from template-derived mapping; fallback to header map if provided
        yaml_key = pgr_to_yaml.get(k)
        if yaml_key is None and k in header_map:
            yaml_key = header_map[k]
        if yaml_key is None:
            continue
        rec[yaml_key] = v  # keep exactly as in .pgr (unquoted)
    if rec:
        records.append(rec)

# --- Emit output: echo section indicators verbatim, then records with template-respecting indentation ---
# Rules:
# - For each record: print all template fields in order.
# - If the field is present in the record, use its value; otherwise use the template's literal default.
# - If the template default is single-quoted, wrap present record values with single quotes (unless already quoted).

# Echo section/header lines VERBATIM (exactly as in template, including indentation)
for sline in section_lines:
    print(sline)

# Print each record
for rec in records:
    first_line = True
    for key in tmpl_keys:
        if key in rec:
            val_out = rec[key]
            # Reconstruct bracketing single quotes if the template default used them
            if single_quote_field.get(key, False):
                # Add single quotes if not already enclosed in single quotes
                if not re.fullmatch(r"\s*'.*'\s*", val_out):
                    val_out = f"'{val_out}'"
        else:
            # Missing in record: use template literal default exactly as written
            val_out = tmpl_default_literal[key]

        if first_line:
            prefix = field_prefix.get(key, '')
            if not field_has_dash.get(key, False):
                # Ensure a dashed prefix for the first line
                if global_dash_prefix is not None:
                    prefix = global_dash_prefix
                else:
                    # Inject "- " after leading whitespace of this key's prefix
                    m_ws = re.match(r'^([ \t]*)', prefix)
                    lead_ws = m_ws.group(1) if m_ws else ''
                    prefix = lead_ws + '- '
            print(f'{prefix}{key}: {val_out}')
            first_line = False
        else:
            # Subsequent lines: use the exact template prefix (no changes)
            prefix = field_prefix.get(key, '')
            print(f'{prefix}{key}: {val_out}')
