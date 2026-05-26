# 10-CHANGELOG — RARO

> Append-only. Header `## [YYYY-MM-DD] — version` para cada entry. Versões seguem semver.

## [2026-05-26] — 0.2.0 (api-contract-shared)

### Adicionado

- **packages/shared 0.2.0**: reorganizado em 12 famílias anti-drift sob `lib/src/{identity,voice,subscription,enums,screens,analytics,storage,bridges,permissions,contract}/` com barrel único `raro_shared.dart`. ADR-0013.
- `apps/mobile`: Pigeon `^26.3.2` com 4 schemas vazios em `pigeons/` gerando código Dart + Swift + Kotlin para os bridges canônicos (`com.rarocamera/{camera,replay_buffer,voice,volume}`).
- `apps/mobile`: Theme Tailor `^3.1.3` com `RaroColors`, `RaroRadii`, `RaroSpacing`, `RaroDurations` como `ThemeExtension` em `lib/core/theme/`. `buildRaroDarkTheme()` aplicado em `MaterialApp`.
- `apps/mobile`: suite `test/contract/` com 6 gates (forbidden literals, info_plist parity, android_manifest parity, screen uniqueness, bridge parity, analytics gate). Total 14 contract tests.
- `.claude/hooks/block-forbidden-terms.sh` bloqueando `OkCamera`/variantes em Write/Edit/MultiEdit.
- `lefthook.yml`: step `contract-tests` no `pre-push` rodando `bun --filter=@raro/mobile run test:contract`.
- `apps/mobile/package.json`: script `test:contract` e `pigeon` (codegen 4 schemas).

### Corrigido

- `ios/Runner/Info.plist`: `CFBundleDisplayName` corrigido de `"Raro Mobile"` para `"Raro Camera"` (alinha com `AppIdentity.displayName`).
- `ios/Runner/Info.plist`: chaves `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription` declaradas com mensagens canônicas (espelham `PermissionsContract.ios`).
- `android/app/src/main/AndroidManifest.xml`: permissions `CAMERA` e `RECORD_AUDIO` declaradas (espelham `PermissionsContract.android`).
- `apps/mobile/lib/app.dart`: removidas cores hardcoded `Color(0xFF000000)`/`Color(0xFFFFFFFF)`; passa a usar `RaroColors.dark` via ThemeExtension.

### Decidido

- ADR-0013: Pigeon + Theme Tailor + gates anti-drift (triple gate: hook PreToolUse + suite test/contract/ + lefthook pre-push) como contrato canônico para 12 famílias de identificadores duplicáveis. Veja `docs/decisions/0013-pigeon-theme-tailor-and-anti-drift-gates.md`.
- Pigeon fixado em `^26.3.2` (não `26.3.4` como originalmente planejado) por conflito de constraint com `riverpod_lint 3.1.3` que exige `analyzer ^9.0.0`. Pigeon 26.3.3+ requer `analyzer >=10.0.0`. Funcionalmente idêntico; revisar em spec futura de upgrade.

### Atualizado

- `docs/Blueprint.md` Seções 2.2 (nota Pigeon após tabela Method Channels), 2.10 (3 deps em monorepo tooling), 9 (linha ADR-0013).

## [2026-05-25] — 0.1.0 (bootstrap)

### Adicionado

- Briefing imutável em `docs/briefing/original-briefing.md`
- Protótipo navegacional em `docs/briefing/prototype/Prototipo-RARO.html` + asset `raro-logo.png`
- Blueprint aprovado em `docs/Blueprint.md` com versões fixadas via Context7 + pub.dev
- Monorepo Bun + Turborepo + Biome
- `apps/mobile` Flutter 3.41 com Riverpod 3 codegen, go_router 17, RevenueCat 10, Firebase 4/12/5, alchemist + mocktail
- `packages/shared` Dart puro com constantes, enums, event names
- lefthook + commitlint (Conventional Commits, scope-enum derivado do Blueprint)
- `setup.sh` idempotente
- `AGENTS.md` + `CLAUDE.md` (manual autoritativo, 13 seções, Karpathy 4 princípios)
- `docs/01-PROJECT.md` até `09-DOD.md` (wiki base)

### Decidido

- Wake word `"Raro"` (não `"OkCamera"`)
- Free trial 30 dias
- Planos: Mensal R$ 9,90 + Anual R$ 89,90 com badge "MELHOR OFERTA"
- Native bridges custom (sem plugin `camera` oficial)
- Replay Buffer 100% nativo
- Client-only (sem backend próprio)
- Controle por botões de volume implementado; controle BT customizado fora
- Tradução em tempo real fora de escopo v1.0
- Onboarding Xiaomi híbrido (auto MIUI + manual em Settings)

### Adicionado (continuação)

- 13 ADRs em `docs/decisions/` (0000 template + 0001-0012)
- 1 session log: `docs/sessions/0001-bootstrap.md` + 0001-INDEX
- Harness completo em `.claude/`:
  - 7 subagents com `tools:` allowlist (implementer, validator,
    adr-guardian, researcher, flutter-test-author, flutter-perf-auditor,
    design-fidelity-checker)
  - 8 slash commands (commit, session-end, docs-lint, prime, new-spec,
    new-plan, verify-slice, ingest-source)
  - 7 hooks (block-env, block-secrets, format-dart, run-riverpod-codegen,
    warn-adr-drift, reinject-roadmap registrados em settings.json +
    verify-task como utilitário invocável manualmente)
  - `settings.json` com 30 entries em allow + 9 em deny + 6 hook entries
    em 3 eventos (PreToolUse, PostToolUse, SessionStart)
- Templates TLC Spec-Driven: `docs/superpowers/specs/0000-template.md`
  e `docs/superpowers/plans/0000-template.md`
- `CLAUDE.md` Seção 6 com workflow auto-sizing (quick/medium/large) +
  sinais que escalam fatia + primeira spec sugerida

### Corrigido (sprints retroativos)

- Sprint 2.7-fixes: 5 fixes pós-Fase 3 (trial 30d direto, hook
  dart-format sem cd quebrado, warning 14 packages explicado em ADR,
  smoke test com guards reais, README.md)
- Sprint 4.7-fixes: 5 fixes pós-Fase 4 (`$schema` URL inexistente
  removido, Stop event teatral removido, analyze-changed-dart
  redundante removido, warn-adr-drift sem blacklist hardcoded,
  setup.sh valida python3)

### Bootstrap status

**v0.1.0 bootstrap completo em 30 commits.** Próximo passo: criar
primeira spec via `/new-spec camera-native-bridge` (Roadmap prioridade 1).
