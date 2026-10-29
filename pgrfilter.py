import re
import sys
from sys import argv
script, infile, filterfile = argv

# Filter a .pgr file (blank-line separated records of "Field: value" lines)
# using rules from a human-readable filter file. See nserc.present.filter.txt.
#
# Rule lines:   drop|keep <Field> <test>
#   drop: remove any record that passes the test
#   keep: remove any record that fails the test
# Tests:
#   is <value>        exact match (case-insensitive)
#   is not <value>
#   has <text>        substring (case-insensitive)
#   matches <regex>   Python regex, searched anywhere in the value
#   missing           field absent or empty
#   present           field has a value
#   before <number>   numeric value < number (e.g., a year)
#   from <number>     numeric value >= number
# When the field is missing, only "missing" and "is not" are true.
# Records are written out verbatim (comments included); order is preserved.
# A leading header paragraph (field names mapped to their template names,
# as made by ypgr.py, e.g. "Page: Page Range") is passed through unfiltered.

rule_re = re.compile(
    r'^(drop|keep)\s+(\S+)\s+'
    r'(is not|is|has|matches|missing|present|before|from)\b\s*(.*)$'
)

rules = []
with open(filterfile, encoding='utf-8') as f:
    for n, raw in enumerate(f, 1):
        line = raw.strip()
        if not line or line.startswith('#'):
            continue
        m = rule_re.match(line)
        if not m:
            sys.exit(f'{filterfile}:{n}: cannot parse rule: {line}')
        action, field, test, arg = m.groups()
        if test in ('missing', 'present') and arg:
            sys.exit(f'{filterfile}:{n}: "{test}" takes no value')
        if test not in ('missing', 'present') and not arg:
            sys.exit(f'{filterfile}:{n}: "{test}" needs a value')
        if test in ('before', 'from'):
            try:
                arg = float(arg)
            except ValueError:
                sys.exit(f'{filterfile}:{n}: "{test}" needs a number')
        if test == 'matches':
            arg = re.compile(arg)
        rules.append((action, field, test, arg))

def fields(para):
    rec = {}
    for ln in para.splitlines():
        ln = re.sub(r'\s*#.*$', '', ln)
        if ':' in ln:
            k, v = ln.split(':', 1)
            rec.setdefault(k.strip(), v.strip())
    return rec

def passes(rec, field, test, arg):
    val = rec.get(field, '')
    if test == 'missing':
        return val == ''
    if test == 'present':
        return val != ''
    if test == 'is not':
        return val.lower() != arg.lower()
    if val == '':
        return False
    if test == 'is':
        return val.lower() == arg.lower()
    if test == 'has':
        return arg.lower() in val.lower()
    if test == 'matches':
        return bool(arg.search(val))
    try:
        num = float(val)
    except ValueError:
        return False
    return num < arg if test == 'before' else num >= arg

def is_header(rec):
    # Each value names the field: pgr keys are the leading words of the value
    def words(s):
        return re.sub(r'[^A-Za-z0-9]+', ' ', s).split()
    return all(
        v and words(v)[:len(words(k))] == words(k)
        for k, v in rec.items()
    )

with open(infile, encoding='utf-8') as f:
    paras = re.split(r'\n[ \t]*\n+', f.read().strip('\n'))

kept = []
header = paras and fields(paras[0]) and is_header(fields(paras[0]))
if header:
    kept.append(paras.pop(0))

for para in paras:
    rec = fields(para)
    if not rec:
        continue
    ok = all(
        passes(rec, fld, t, a) != (act == 'drop')
        for act, fld, t, a in rules
    )
    if ok:
        kept.append(para)

print('\n\n'.join(kept))
nrec = len(kept) - bool(header)
print(f'pgrfilter: kept {nrec} of {len(paras)} records'
      + (' (plus header)' if header else ''), file=sys.stderr)
