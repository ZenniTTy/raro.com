# 03-CONVENTIONS — RARO

> Conversão de código e processo. Versão canônica em [CLAUDE.md Seção 5](../CLAUDE.md). Este doc é o resumo para devs humanos.

## Dart / Flutter

| Regra | Detalhe |
|---|---|
| State management | Riverpod 3 com codegen (`@riverpod` + `part '*.g.dart'`). Não usar `Provider` ou `ChangeNotifier` legados. |
| Filenames | `snake_case.dart` |
| Imports | Absolutos via `package:raro_mobile/...`. Sem relativos longos. |
| Strict lints | `analysis_options.yaml` da raiz de `apps/mobile`. `strict-casts`, `strict-inference`, `prefer_const_constructors`, `require_trailing_commas`. |
| Comentários | **Sem comentários** em código de produção. Nomes explicam WHAT; ADRs/docs explicam WHY. |
| Feature folder | `lib/features/<feature>/{application,data,domain,presentation}/` |

## Native

| Plataforma | Stack | Linter |
|---|---|---|
| iOS | Swift + AVFoundation | SwiftLint (line 120) |
| Android | Kotlin + CameraX | ktlint default |

Method Channels com namespace `com.rarocamera/<feature>`. Contrato JSON documentado em `<bridge>_contract.md` antes da implementação.

## Shared (packages/shared)

- Dart puro, sem Flutter.
- Só constantes, enums, event names.
- Hard rule: `VoiceConfig.wakeWord = 'Raro'`. PRs que mudam isso são bloqueados.

## Commits — Conventional Commits 1.0.0

```
<type>(<scope>): <description>

[body]

[footer]
```

- **type:** `feat`, `fix`, `refactor`, `docs`, `style`, `test`, `chore`, `perf`, `build`, `ci`, `revert`
- **scope:** [commitlint.config.cjs](../commitlint.config.cjs)
- **description:** lowercase, ≤100 chars no header, sem ponto final
- **regra:** um commit = uma mudança lógica
- **proibido:** `--no-verify`, `--no-gpg-sign`

## Tooling

```bash
./setup.sh              # bootstrap em clone novo (idempotente)
bun run lint            # turbo lint
bun run typecheck       # turbo typecheck
bun run test            # turbo test
bun run format          # biome format --write
bun run --filter '@raro/mobile' codegen   # dart run build_runner
cd apps/mobile && flutter run
```

Hooks (lefthook):

- **pre-commit (parallel):** dart-format em staged, biome format em staged json/md, block-secrets via regex.
- **pre-push:** `bun run lint && bun run test`.
- **commit-msg:** commitlint.

## i18n

- Strings de UI sempre via `.arb`. Nunca literais inline. **[ESTADO: i18n não implementada — 0 arquivos .arb, hoje hardcoded PT-BR; convenção é alvo, PLANO-MESTRE Bloco 4.6]**
- `pt-BR` é default e fallback. `en` e `es` cobertura completa.
- `flutter gen-l10n` gera classes Dart tipadas.

## Testes

| Tipo | Lib | Cobertura alvo |
|---|---|---|
| Unit (use cases, repositórios) | flutter_test + mocktail | 80% / 70% |
| Widget | flutter_test | 60% críticos |
| Golden | alchemist | screens com baseline do protótipo |
| Integration | integration_test | golden path por feature em device real |
