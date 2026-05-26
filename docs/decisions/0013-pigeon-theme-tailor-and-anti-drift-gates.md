# 0013 — Pigeon + Theme Tailor + gates anti-drift como contrato canônico

- **Data:** 2026-05-26
- **Status:** Accepted
- **Spec:** docs/superpowers/specs/2026-05-25-api-contract-shared-design.md
- **Supersedes:** parcialmente ADR-0002 (descrição original dos Method Channels como strings JSON manuais)

## Contexto

O Blueprint 2026-05-25 listou 4 Method Channels (`com.rarocamera/{camera,replay_buffer,voice,volume}`) descritos como contratos JSON-serializáveis manuais (Seção 2.2). Após brainstorming da spec `api-contract-shared` (2026-05-26), ficou evidente que:

1. Strings de namespace duplicadas em Dart + Swift + Kotlin são fonte garantida de drift por alucinação de agentes Claude/Codex.
2. Design tokens (cores, gradients, tipografia) declarados como constantes soltas permitem `Color(0xFFFF2D55)` literal em widget, fugindo da fonte canônica.
3. Identificadores de domínio (event names, screen IDs, storage keys, SKUs, wake word) precisam de gates automáticos que falhem o build na primeira divergência.

## Decisão

Adotamos três mecanismos complementares:

1. **Pigeon ^26.3.2** para Method Channels — schemas Dart únicos em `apps/mobile/pigeons/*.dart` geram código tipado em Dart + Swift + Kotlin sincronizado. Elimina por construção o drift de namespace e assinaturas. Versão fixada em `26.3.2` (não `26.3.4`) por conflito de `analyzer` constraint com `riverpod_lint 3.1.3`; pigeon 26.3.3+ exige `analyzer >=10.0.0`. Cada bridge usa **sub-package Kotlin distinto** (`com.rarocamera.raro_mobile.generated.{camera,replay_buffer,voice,volume}`) — Pigeon gera `class FlutterError` em cada `.g.kt` e pacote comum causa redeclaration. iOS side: cada `.g.swift` declara `PigeonError` `final` mas Pigeon usa `fileprivate`-like scoping via diferentes nomes prefixados; sem conflito em Swift module.
2. **Theme Tailor ^3.1.3** (+ `theme_tailor_annotation ^3.1.3`) para design tokens — classes `@TailorMixin` em `apps/mobile/lib/core/theme/raro_theme.dart` geram `ThemeExtension` tipadas. Consumo via `Theme.of(context).extension<RaroColors>()!`. `Color(0xFF...)` fora de `core/theme/` vira erro de teste.
3. **Triple-gate anti-drift** para invariantes de marca e identificadores:
   - (a) Hook PreToolUse `.claude/hooks/block-forbidden-terms.sh` bloqueia `OkCamera`, `Ok Camera`, `hey OkCamera` em qualquer Write/Edit/MultiEdit.
   - (b) Suite `apps/mobile/test/contract/` (6 testes mínimos) varre o repo com regex e falha em drift.
   - (c) `lefthook` pre-push roda `bun --filter @raro/mobile run test:contract`.

Versões fixadas via pub.dev API consulta em 2026-05-26.

## Consequências

**Positivo:**
- Drift de namespace de bridge fica impossível (codegen).
- Drift de cor/gradient fica impossível (ThemeExtension tipada).
- Drift de event name, screen ID, storage key, SKU detectado em CI antes do merge.
- Specs de bridges subsequentes (camera, replay, voice, volume) só editam schema Pigeon — nunca strings de channel.

**Negativo:**
- Adiciona Pigeon + Theme Tailor + build_runner ao stack (deps + tempo de codegen).
- Arquivos gerados commitados aumentam volume de PR (decisão consciente: visibilidade > ruído).
- Reorganização de `packages/shared` (constants/ → identity/voice/subscription/) exige atualizar imports.

**Neutro:**
- Renovate/dependabot fora de escopo desta ADR. Versões revisadas manualmente em specs futuras de upgrade.

## Alternativas consideradas

- **MethodChannel cru com strings** — rejeitado por ser exatamente o que esta ADR resolve.
- **`json_serializable` puro para payloads** — não cobre cross-platform; Pigeon faz ambos.
- **`custom_lint` package** — overhead de codegen extra; `dart test` estático cobre os mesmos casos com menor custo. Reabrir se algum gate virar ruidoso em IDE.
- **Geração de tokens via Figma Tokens** — overkill; protótipo HTML é a fonte e migra 1x.

## Referências

- spec: `docs/superpowers/specs/2026-05-25-api-contract-shared-design.md`
- plan: `docs/superpowers/plans/2026-05-26-api-contract-shared.md`
- https://docs.flutter.dev/platform-integration/platform-channels
- https://pub.dev/packages/pigeon
- https://pub.dev/packages/theme_tailor
- https://api.flutter.dev/flutter/material/ThemeExtension-class.html
