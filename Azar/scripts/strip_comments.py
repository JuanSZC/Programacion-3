import os
import re

root = os.path.join(os.getcwd(), 'azar_app', 'lib')
paths = []
for dirpath, dirnames, filenames in os.walk(root):
    for f in filenames:
        if f.endswith('.ex'):
            paths.append(os.path.join(dirpath, f))

changed = []
for p in paths:
    with open(p, 'r', encoding='utf-8') as fh:
        lines = fh.readlines()
    new_lines = []
    for line in lines:
        if re.match(r'^\s*#', line):
            continue
        new_lines.append(line)
    if new_lines != lines:
        with open(p, 'w', encoding='utf-8') as fh:
            fh.writelines(new_lines)
        changed.append(p)

print('Processed', len(paths), 'files. Modified:', len(changed))
for c in changed:
    print(' -', c)
