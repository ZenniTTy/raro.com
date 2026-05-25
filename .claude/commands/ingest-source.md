---
description: Ingere conteúdo de fonte externa (URL, arquivo local) em docs/ com proveniência registrada
argument-hint: "<URL ou caminho> + <destino dentro de docs/>"
---

Ingerir conteúdo externo no repositório, preservando origem e impedindo alucinação.

## Passos

1. **Identifique a fonte:** URL pública, arquivo local, ou colado pelo usuário.
2. **Fetch:**
   - URL pública: `WebFetch` (se ≤10MB) ou peça ao usuário para salvar local
   - Arquivo local: `Read`
   - Colado: receber via prompt do usuário
3. **Decida o destino:**
   - Documento técnico longo → `docs/<adequado>.md` (criar com header de proveniência)
   - Asset binário (PNG, JPG, PDF) → `docs/briefing/prototype/assets/` ou pasta dedicada
   - Especificação de terceiro (Apple, Firebase, RevenueCat) → `docs/references/<provider>/<arquivo>.md`
4. **Header de proveniência obrigatório** no topo do arquivo ingestido:

```markdown
> **Source:** <URL ou caminho original>
> **Fetched:** YYYY-MM-DD
> **Ingested by:** /ingest-source command
> **Status:** verbatim | summarized | adapted
```

5. **Não modifique o conteúdo** salvo se for `summarized` ou `adapted` — sempre registre o status.
6. **Não engula erros** — se fetch falhou, reporte ao usuário e pare.
7. **Não commit automático** — usuário revisa antes.

## Quando o destino é briefing/prototype/

Lembre: `docs/briefing/` é **imutável** (Karpathy immutable sources). Ingerir lá só com permissão explícita do usuário.

## Anti-patterns

- ❌ Ingerir sem header de proveniência
- ❌ Resumir e marcar como `verbatim`
- ❌ Adicionar ao `.gitignore` para "ocultar"
- ❌ Modificar `docs/briefing/` sem aprovação
