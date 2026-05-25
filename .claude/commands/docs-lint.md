---
description: Audita docs/ para broken links, orphans, TBD/TODO e drift contra AGENTS.md/CLAUDE.md
---

Lint da documentação do RARO. Read-only — apenas reporta.

## Passos

1. **Broken links** — rode em Python:

```python
import re
from pathlib import Path
ROOT = Path('.').resolve()
broken = []
for f in list(ROOT.glob('*.md')) + list(ROOT.glob('docs/**/*.md')):
    text = f.read_text()
    for m in re.finditer(r'\[[^\]]+\]\(([^)]+)\)', text):
        path = m.group(1).split('#')[0].split(' ')[0]
        if path.startswith(('http', 'mailto:', '#')) or not path or 'NNNN' in path:
            continue
        resolved = (f.parent / path).resolve()
        try: resolved.relative_to(ROOT)
        except ValueError: continue
        if not resolved.exists():
            broken.append(f"{f.relative_to(ROOT)} → {path}")
print('\n'.join(broken) if broken else '✅ no broken links')
```

2. **Orphans** — para cada `*.md` em `docs/` e na raiz: o arquivo é referenciado em pelo menos 1 outro `*.md`? Se não → orphan.
3. **TBD/TODO** — `grep -rn "TBD\|TODO\|FIXME" docs/ AGENTS.md CLAUDE.md` (ignorar `docs/briefing/` que é imutável).
4. **Drift** — checagens semânticas:
   - `grep -rn "OkCamera\|Ok Camera" docs/ AGENTS.md CLAUDE.md` exceto `docs/briefing/`, `docs/decisions/0009-*`, e contexto de comparação histórica
   - `grep -rn "15 dias" docs/ exceto docs/briefing/ docs/Blueprint.md docs/decisions/0010-*` (trial canônico é 30)
   - Versões de libs citadas devem bater com `pubspec.yaml` (Flutter, Riverpod, RevenueCat, etc.)
5. Reportar tudo em markdown:

```markdown
# docs-lint report (<data>)

## 🔴 Broken links (N)
## 🟠 Orphans (N)
## 🟡 TBD/TODO (N)
## 🟠 Drift (N)
## ✅ Health: <pass/fail>
```

## Anti-patterns

- ❌ Modificar arquivos (este comando é read-only)
- ❌ Reportar broken link em URL externa (não verificamos HTTP)
- ❌ Reportar TODO em código (`apps/mobile/lib/...`) — esse é problema de outro lint
