# Slice checklist — hard gates contextuais

> Usado pelo slash command `/verify-slice` para validar uma fatia (feature ou subset) antes de PR/merge. Sempre lido junto com o diff atual.

## Gates universais (sempre rodar)

- [ ] `bun run lint` — zero issues em todos workspaces
- [ ] `bun run typecheck` — zero issues
- [ ] `bun run test` — todos os testes verdes
- [ ] Commit messages do diff seguem Conventional Commits + scope-enum
- [ ] Nenhuma menção a `OkCamera` ou `Ok Camera` em código novo (exceto `docs/decisions/0009-*` que explica a regra)
- [ ] Nenhum `.env`, `keystore.jks`, `google-services.json`, `GoogleService-Info.plist` no diff
- [ ] Nenhum `--no-verify` no histórico do branch

## Gates condicionais (rodar se aplicável)

### 🔵 Tocou `lib/app.dart` ou rotas (`go_router` config)
- [ ] Integration test em device físico/simulador real (não só `flutter test`)
- [ ] Cobertura de deep link manual
- [ ] State preserva em hot-reload e cold start

### 🔵 Tocou tela com baseline golden em `test/.../goldens/`
- [ ] `flutter test --update-goldens` rodado
- [ ] Diff visual aprovado humanamente (PR review com screenshots)
- [ ] Golden regerado em CI também (não só local)

### 🔵 Tocou Method Channel (`apps/mobile/lib/core/native_bridges/`)
- [ ] Contract test passa em iOS (xcodebuild ou device físico)
- [ ] Contract test passa em Android (gradle ou emulator)
- [ ] Contrato JSON em `<bridge>_contract.md` reflete o código
- [ ] Erro paths testados (permission denied, hardware absent, session timeout)

### 🔵 Tocou tela que existe no protótipo (P01–P10, M01–M03)
- [ ] Invocar agent `design-fidelity-checker` passando screen ID
- [ ] Cores batem com tokens (Blueprint Seção 4)
- [ ] Tipografia: Space Grotesk / Inter / JetBrains Mono nos lugares certos
- [ ] Microinterações implementadas (recPulse, gradShift, logoBreathe, bufferFill se aplicável)
- [ ] Copy literal corresponde ao protótipo (atenção: trial = 30 dias, não 15)

### 🔵 Mudou dep ou stack (`pubspec.yaml`, `package.json`, monorepo tooling)
- [ ] Invocar agent `adr-guardian` com diff
- [ ] ADR aberto e referenciado no commit body
- [ ] Versão validada via Context7 ou `curl pub.dev/api/...`
- [ ] `flutter pub outdated` sem regressão

### 🔵 Adicionou `@riverpod` annotation
- [ ] Codegen rodado: `bun --filter @raro/mobile run codegen`
- [ ] `*.g.dart` em diff e não em `.gitignore`
- [ ] `part '*.g.dart'` declarado no top do arquivo
- [ ] Provider testado com `ProviderScope` override em widget test

### 🔵 Adicionou string de UI
- [ ] String em `.arb` (não inline no Dart)
- [ ] `pt-BR` (default), `en`, `es` todos têm a chave
- [ ] `flutter gen-l10n` rodado, classe Dart gerada
- [ ] Imports usam a classe gerada, não string literal

### 🔵 Adicionou evento de analytics
- [ ] Nome em `packages/shared/lib/src/events/analytics_events.dart`
- [ ] `firebase_analytics` chamado via use case, não direto no widget
- [ ] Sem PII no payload

### 🔵 Mudou native Swift/Kotlin
- [ ] Compilação iOS OK (`flutter build ios --no-codesign --simulator`)
- [ ] Compilação Android OK (`flutter build apk --debug`)
- [ ] SwiftLint / ktlint zero issues no diff
- [ ] Symbolic stack traces ainda funcionam (`--split-debug-info` se ativo)

## Como o `/verify-slice` decide quais gates rodar

1. `git diff main..HEAD --name-only` lista arquivos mudados.
2. Para cada gate condicional, regex/glob nos paths:
   - `lib/app.dart|lib/router/*` → gate de navegação
   - `test/**/goldens/*` → gate de golden
   - `lib/core/native_bridges/*|ios/Runner/Native/*|android/**/*.kt` → gate de bridge
   - `lib/features/*/presentation/*` → gate de fidelidade (compara com tela do protótipo)
   - `pubspec.yaml|package.json|turbo.json|biome.json|lefthook.yml|commitlint.config.cjs` → gate de stack
   - `@riverpod` em diff → gate de codegen
   - `lib/l10n/*.arb` → gate de i18n
   - `analytics_events.dart` em diff → gate de analytics
   - `*.swift|*.kt` em diff → gate de native

3. Reporta no formato:

```markdown
# Slice verify — <branch> (<date>)
## Universal gates: ✅
## Conditional gates ativos:
- 🔵 design-fidelity (tocou camera_screen.dart) — ✅
- 🔵 stack-change (mudou pubspec.yaml) — ❌ ADR ausente
## Manual still needed: integration test em iPhone 15 Pro
```
