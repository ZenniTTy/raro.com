# Session 0002 — api-contract-shared

- **Date:** 2026-05-26
- **Branch:** `feat/api-contract-shared`
- **Spec:** `docs/superpowers/specs/2026-05-25-api-contract-shared-design.md`
- **Plan:** `docs/superpowers/plans/2026-05-26-api-contract-shared.md`
- **ADR:** `docs/decisions/0013-pigeon-theme-tailor-and-anti-drift-gates.md`

## Summary

Implementou o contrato anti-drift do projeto materializando 12 famílias em fonte única (`packages/shared` barrel), adicionando Pigeon (4 schemas vazios — Dart + Swift + Kotlin gerados) e Theme Tailor (4 `ThemeExtension` tipados), criando 6 testes contract em `apps/mobile/test/contract/`, hook PreToolUse `block-forbidden-terms.sh`, step pre-push `contract-tests` no lefthook, e corrigindo drift do `Info.plist`.

A ordem das tasks 14 e 16 foi invertida em relação ao plan para manter o pipeline harness verde a cada commit (correção do drift antes dos gates de parity).

## Commits

Gerados via `git log --oneline develop..HEAD` (16 commits, do mais antigo ao mais recente):

- `2783166` docs(docs): adr-013 pigeon + theme tailor + anti-drift gates
- `9316411` docs(blueprint): reference adr-013 in sections 2.2, 2.10, 9
- `aecfb10` refactor(shared): move app_identity to identity/ with abstract final class
- `0ae9af2` refactor(shared): move voice + subscription, formalize as abstract final class
- `6277930` feat(shared): export enums via raro_shared barrel
- `7d5d398` feat(analytics): move events + add typed payloads
- `4c0958d` feat(shared): add app_screen + app_modal enums (family 8)
- `a8dd182` feat(shared): add storage keys, bridge channels, permissions, forbidden terms
- `1f57fab` build(deps): add pigeon, theme_tailor, xml for anti-drift codegen
- `91fcf92` feat(bridge): add 4 pigeon schemas with codegen pipeline
- `f95e132` feat(theme): add theme tailor tokens (colors, radii, spacing, durations)
- `b4f893a` test(shared): add forbidden_literals gate (terms, channels, skus, hex)
- `cbdfa14` fix(permissions): correct ios display name + ensure permission keys
- `2d5c409` test(shared): add info_plist + android_manifest parity gates
- `1bcb80e` test(shared): add screen + bridge + analytics gates
- `f30bb1b` feat(harness): add block-forbidden-terms hook + pre-push contract gate

## Verification

- `bun --filter=@raro/shared run test`: 28 verdes (10 famílias cobertas)
- `bun --filter=@raro/mobile run analyze`: zero issues
- `bun --filter=@raro/mobile run test`: 19 verdes (14 contract + 5 smoke)
- `bun --filter=@raro/mobile run test:contract`: 14 contract verdes
- `grep -r "Raro Mobile" apps/ packages/`: vazio
- `grep -rE "OkCamera|Ok Camera|hey OkCamera|okCamera" apps/ packages/`: vazio (apenas docs e hooks/agents legítimos)
- Hook `block-forbidden-terms.sh`: bloqueia OkCamera (exit 1), permite Raro (exit 0)

## Desvios documentados

1. Pigeon fixado em `^26.3.2` (não `^26.3.4`) por conflito de analyzer constraint com riverpod_lint.
2. ADR-013 commit usou scope `docs` em vez de `decisions` (não no scope-enum).
3. `forbidden_literals_test.dart` reescrito sem embeddar literais proibidos (usa `String.fromCharCodes` e leitura de `ForbiddenTerms.all`).
4. Tasks 14 e 16 reordenadas para manter harness verde a cada commit.
5. `bun --filter=@raro/mobile` (com `=`) — sintaxe exigida pelo Bun 1.3.13; sem `=` falha com "No packages matched the filter".

## Próxima sessão sugerida

- **0003** — Primeira feature concreta: `feat/camera-native-bridge` (Roadmap prioridade 1). Já existe contrato; basta preencher métodos do `CameraHostApi`/`CameraFlutterApi` em `pigeons/camera_api.dart` e implementar lado nativo.
