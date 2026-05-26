# Session 0003 — flutter-3.44-spm-migration

- **Date:** 2026-05-26
- **Branch:** `feat/flutter-3.44-spm-migration`
- **Spec:** `docs/superpowers/specs/2026-05-26-flutter-3.44-spm-migration-design.md`
- **Plan:** `docs/superpowers/plans/2026-05-26-flutter-3.44-spm-migration.md`
- **ADR:** `docs/decisions/0014-flutter-3.44-spm-ios-15.md`

## Summary

Migrou plataforma iOS de CocoaPods para Swift Package Manager, com upgrade Flutter 3.41.9 → 3.44.0 + Dart 3.11 → 3.12 + iOS deployment target 13 → 15. Sem regressão Android — `flutter build apk --debug` continua PASS (`Built app-debug.apk`). Os 6 contract gates da spec anterior mantidos verdes.

A sessão começou com pesquisa moderna (Context7 + WebSearch + pub.dev API) validando que CocoaPods entra em read-only em 2026-12-02, Firebase parou de publicar lá em out/2026, e Flutter 3.44 (released 2026-05-12) torna SPM default oficial. Decisão tríplice (Flutter+SPM+iOS) integrada em ADR-014.

Brainstorming + plan + execução seguiram fluxo TLC Spec-Driven com user review entre fases. Per-task harness validation (analyze + tests shared + tests mobile) verde antes de cada commit, conforme feedback persistente em memória.

## Desvios documentados

- Task 1 capturou mudanças intermediárias do workspace (Podfile deletado pelo usuário no `flutter upgrade` + pubspec.lock regenerado) em commit limpo antes de prosseguir.
- Task 3 e Task 4 saltadas porque estado pós-upgrade já estava limpo (Podfile.lock não existia, project.pbxproj sem refs CocoaPods).
- Task 5: baseline real do iOS deployment target era `13.0` (não `14.0` como o plan afirmava). Bumpado para `15.0`.
- Task 7 (pigeon attempt): tentou `pigeon ^26.3.4`, falhou com `version solve` por causa de `theme_tailor 3.1.3` + `riverpod_lint 3.1.3` pinarem `analyzer ^9.0.0`. Revertido para `^26.3.2`. Task 14 (ADR-013 update) skipada.
- Scope `mobile` rejeitado pelo commitlint scope-enum. Usado `bridge` (cobre nativo iOS/Android) para commits relacionados.
- Task 9: APK build PASS em ~10min.
- Task 10: iOS build progrediu via SPM com sucesso (`Adding Swift Package Manager integration... 227s` + `Running pod install... 5.4s` + `Xcode build done. 40s`). Build final falhou por **ambiente local**: Xcode 26.5 sem iOS 26.5 platform instalado. Usuário baixou via Xcode > Settings > Components. **Migração SPM em si funcionou** — gate técnico fechado, gate de execução aguarda SDK do ambiente.
- Podfile auto-gerado pelo Flutter para `permission_handler_apple` — gitignored em `apps/mobile/.gitignore`.

## Commits

(gerado por `git log --oneline develop..HEAD` — preencher após Task 16)

## Verification

- `flutter --version`: `Flutter 3.44.0 • channel stable` + `Dart 3.12.0`
- `bun --filter=@raro/shared run test`: 28 verdes
- `bun --filter=@raro/mobile run analyze`: zero issues (warning sobre permission_handler_apple sem SPM aceitável)
- `bun --filter=@raro/mobile run test`: 19 verdes (5 smoke + 14 contract — sem regressão)
- `bun --filter=@raro/mobile run pigeon`: PASS (Caso B, pigeon ficou em 26.3.2)
- `bun --filter=@raro/mobile run codegen`: PASS, idempotente
- `flutter build apk --debug`: PASS, `Built app-debug.apk` (155 MB, 603s)
- `flutter build ios --no-codesign --debug`: SPM integration + pod install + Xcode build PASS técnico. Build final aguarda iOS 26.5 platform no Xcode.
- iOS deployment target = 15.0 em `project.pbxproj` (3x) e `AppFrameworkInfo.plist`

## Próxima sessão sugerida

- **0004** — Primeira spec de feature real: `feat/camera-native-bridge` (Roadmap prioridade 1). Plataforma agora moderna (Flutter 3.44 + SPM + iOS 15), bridges Pigeon vazios prontos, contrato anti-drift policiando, harness verde.
