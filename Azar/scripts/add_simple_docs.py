import os
import re

root = os.path.join(os.getcwd(), 'azar_app', 'lib')
paths = []
for dirpath, dirnames, filenames in os.walk(root):
    for f in filenames:
        if f.endswith('.ex'):
            paths.append(os.path.join(dirpath, f))

MODULEDOC_RE = re.compile(r"^\s*@moduledoc\b", re.MULTILINE)
DEF_MODULE_RE = re.compile(r"^\s*defmodule\s+([A-Za-z0-9_.]+)\s+do", re.MULTILINE)
DEF_PUBLIC_RE = re.compile(r"^(\s*)def\s+([a-zA-Z0-9_?!]+)\b", re.MULTILINE)

changed = []
for p in paths:
    with open(p, 'r', encoding='utf-8') as fh:
        src = fh.read()

    original = src

    # Add moduledoc if missing
    if not MODULEDOC_RE.search(src):
        m = DEF_MODULE_RE.search(src)
        if m:
            modname = m.group(1)
            short = modname.split('.')[-1]
            doc = '\n  @moduledoc """\n  Módulo %s: lógica relacionada con %s.\n  """\n' % (modname, short.lower())
            insert_pos = m.end()
            src = src[:insert_pos] + doc + src[insert_pos:]

    # Add simple @doc for public functions that lack @doc/@impl/@spec above
    lines = src.splitlines(True)
    out_lines = []
    i = 0
    while i < len(lines):
        line = lines[i]
        # match public def
        m = DEF_PUBLIC_RE.match(line)
        if m:
            indent = m.group(1)
            fname = m.group(2)
            # look back up to 3 non-empty lines to see if @doc/@impl/@spec present
            has_doc = False
            j = len(out_lines)-1
            look_back = 0
            while j >= 0 and look_back < 6:
                prev = out_lines[j].strip()
                if prev == '':
                    j -= 1
                    look_back += 1
                    continue
                if prev.startswith('@doc') or prev.startswith('@impl') or prev.startswith('@spec'):
                    has_doc = True
                break
            if not has_doc:
                doc_line = indent + '@doc """\n' + indent + 'Breve: ' + fname + '.\n' + indent + '"""\n'
                out_lines.append(doc_line)
        out_lines.append(line)
        i += 1

    new_src = ''.join(out_lines)

    if new_src != original:
        with open(p, 'w', encoding='utf-8') as fh:
            fh.write(new_src)
        changed.append(p)

print('Processed', len(paths), 'files. Modified:', len(changed))
for c in changed:
    print(' -', c)
