from pathlib import Path
import re

files = [
    'lib/azar_app/auditoria.ex',
    'lib/azar_app_web/components/core_components.ex',
    'lib/azar_app_web/live/cliente/perfil_live.ex',
    'lib/azar_app_web/live/admin/index.ex',
    'lib/azar_app/models/cliente.ex',
    'lib/azar_app/models/billete.ex',
    'lib/azar_app/models/premio.ex'
]

sig_re = re.compile(r"^\s*def\s+([\w_!?]+)\s*\((.*)\)\s*(?:do|, do|->)?")


def signature(line):
    m = sig_re.match(line)
    if not m:
        return None
    name = m.group(1)
    args = m.group(2)
    if args.strip() == '':
        arity = 0
    else:
        arity = args.count(',') + 1
    return f'{name}/{arity}'

for relative in files:
    path = Path(relative)
    if not path.exists():
        continue
    text = path.read_text(encoding='utf-8')
    lines = text.splitlines()
    result = []
    seen = set()
    i = 0
    while i < len(lines):
        line = lines[i]
        if line.strip() == '@doc """':
            doc_block = [line]
            i += 1
            while i < len(lines) and '"""' not in lines[i]:
                doc_block.append(lines[i])
                i += 1
            if i < len(lines):
                doc_block.append(lines[i])
                i += 1
            while i < len(lines) and lines[i].strip() == '':
                doc_block.append(lines[i])
                i += 1
            sig = None
            if i < len(lines):
                sig = signature(lines[i])
            if sig and sig in seen:
                continue
            if sig:
                seen.add(sig)
            result.extend(doc_block)
            continue
        sig = signature(line)
        if sig and sig not in seen:
            seen.add(sig)
        result.append(line)
        i += 1
    path.write_text('\n'.join(result) + '\n', encoding='utf-8')

cuentas_path = Path('lib/azar_app/cuentas/cuentas.ex')
text = cuentas_path.read_text(encoding='utf-8')
text = re.sub(
    r"\n\s*\{:ok, resultado\} ->\n(?:.*\n)*?AzarApp\.AuditoriaJSON\.limpiar\(\)\n(?:.*\n)*?\{:ok, resultado\}\n",
    "\n      {:ok, resultado} ->\n      File.rm(\"log/auditoria.log\")\n\n      AzarApp.Auditoria.log(:sistema_limpiado, %{\n        tickets: resultado.tickets |> elem(0),\n        sorteos: resultado.sorteos |> elem(0),\n        usuarios: resultado.usuarios |> elem(0)\n      })\n\n      AzarApp.Backup.limpiar_todo()   # vacía los JSON\n      {:ok, resultado}\n",
    text,
    flags=re.MULTILINE
)
cuentas_path.write_text(text, encoding='utf-8')
print('ok')
