# 04-ROADMAP — RARO

> Roadmap de specs pós-bootstrap. Ordem orientada por **dependência técnica + risco** + **API contract first**. Cada spec referencia agents, hooks, gates e sizing do harness. Não é commitment de prazo.

## Princípios deste roadmap

1. **API Contract First** — toda type/enum/constant compartilhada vive em `packages/shared/` (single source of truth). Features importam; nunca duplicam. Spec `spec-001` define o contrato canônico antes de qualquer feature de produto começar.
2. **Sizing pré-classificado** — cada spec já vem rotulada como Quick / Medium / Large (ver [CLAUDE.md Seção 6](../CLAUDE.md)).
3. **Dependências explícitas** — toda spec lista pré-requisitos (ADR, outra spec, infra). Sem ambiguidade.
4. **Gates contextuais** — cada spec lista quais checks do `.claude/slice-checklist.md` se aplicam e quais subagents devem ser invocados.
5. **Validável em pipeline** — toda micro-sprint dentro de uma spec termina com gate executável (`flutter test`, `flutter analyze`, contract test, design-fidelity).

## DAG de execução

```
                    ┌─────────────────────────────────────────────┐
                    │  spec-001-api-contract-shared (Medium)       │
                    │  expande packages/shared com types canônicos │
                    └─────────────────────────────────────────────┘
                                       │
            ┌──────────────┬───────────┴───────────┬──────────────────┐
            ▼              ▼                       ▼                  ▼
    spec-002-firebase   spec-003-revenuecat   spec-004-theme    spec-005-fonts
    -init (Medium)      -init (Medium)        -tokens (Quick)   (Quick)
            │              │                       │                  │
            │              │                       └─────┬────────────┘
            │              │                             ▼
            │              │                       spec-006-splash (Quick)
            │              │                             │
            │              │                             ▼
            └──────────────┴──────► spec-007-camera-native-bridge (Large) 🔴
                                                │
                                                ▼
                                    spec-008-replay-buffer (Large) 🔴
                                                │
                                                ▼
                                    spec-009-voice-wake-word (Large) 🔴
                                                │
                          ┌─────────────────────┼─────────────────────┐
                          ▼                     ▼                     ▼
                spec-010-volume         spec-011-lock-mode    spec-012-i18n
                -control (Medium)       (Medium)              -scaffold (Quick)
                                                                      │
                          ┌───────────────────────────────────────────┘
                          ▼
                spec-013-subscription-paywall (Large)
                          │
                          ▼
                spec-014-checkout (Medium)
                          │
                          ▼
                spec-015-gallery (Medium) ─► spec-016-preview (Medium)
                          │
                          ▼
                spec-017-permissions (Quick)
                          │
                          ▼
                spec-018-onboarding (Medium)
                          │
                          ▼
                spec-019-xiaomi-onboarding (Quick)
                          │
                          ▼
                spec-020-settings (Medium) [agrega todas as configs]
```

## Critério de sizing aplicado

| Sizing | Quando |
|---|---|
| **Quick** (≤3 arquivos, sem mudança arquitetural) | Asset adição, copy/string em `.arb`, screen UI simples sem state complexo, splash, fontes, scaffold i18n |
| **Medium** (1 feature, multi-file, sem novo bridge) | Tela completa com state Riverpod, integração com SDK existente, modal com permissão, settings, gallery, preview |
| **Large** (novo bridge, novo ADR, multi-feature) | Native bridge (camera, replay, voice), paywall com 2 SKUs + checkout, integração de SDK novo no boot, expansão do API contract |

## Tabela completa de specs

| # | Spec | Sizing | Dependências | Telas/Componentes | Hooks/Agents críticos |
|---|---|---|---|---|---|
| 001 | api-contract-shared | Medium | Bootstrap | — (puro shared) | implementer + flutter-test-author + adr-guardian |
| 002 | firebase-init | Medium | 001 | — (config nativa) | implementer + adr-guardian (ADR de config); block-env protege configs |
| 003 | revenuecat-init | Medium | 001 | — (config nativa) | implementer + researcher (validar SDK 10.1.1); block-env |
| 004 | theme-design-tokens | Quick | 001 | tokens compartilhados | implementer + design-fidelity-checker |
| 005 | native-fonts | Quick | 004 | assets/fonts/ | implementer |
| 006 | splash (P01) | Quick | 004 + 005 | P01 | implementer + design-fidelity-checker (P01) + flutter-test-author |
| 007 | camera-native-bridge | Large 🔴 | 001 | P05 (core) | implementer + flutter-test-author + adr-guardian (ADR 0002 + contract) + design-fidelity-checker (P05) |
| 008 | replay-buffer | Large 🔴 | 007 | P05 (HUD) | implementer + flutter-test-author + adr-guardian (ADR 0003 + contract) + flutter-perf-auditor (RAM) |
| 009 | voice-wake-word | Large 🔴 | 007 | P05 (mic + hint) | implementer + adr-guardian (privacy manifest + contract); design-fidelity-checker se HUD muda |
| 010 | volume-control | Medium | 007 | P05 + M03 | implementer + adr-guardian (ADR 0011 + contract); design-fidelity-checker (M03 modal) |
| 011 | lock-mode | Medium | 007 | P05a | implementer + design-fidelity-checker (P05a) + flutter-perf-auditor (consumo bateria) |
| 012 | i18n-scaffold | Quick | 001 | l10n/ | implementer; design-fidelity-checker valida copy contra protótipo |
| 013 | subscription-paywall | Large | 001 + 003 + 012 | P09 + M01 popup | implementer + design-fidelity-checker (P09 + M01) + researcher (validar SKUs no RevenueCat dashboard) |
| 014 | checkout | Medium | 013 | P10 | implementer + design-fidelity-checker (P10) |
| 015 | gallery | Medium | 007 + 008 | P07 | implementer + design-fidelity-checker (P07) + flutter-perf-auditor (grid 3-cols) |
| 016 | preview | Medium | 015 | P08 | implementer + design-fidelity-checker (P08) |
| 017 | permissions | Quick | 001 | P04 | implementer + design-fidelity-checker (P04) |
| 018 | onboarding | Medium | 017 + 012 | P02 + P03 | implementer + design-fidelity-checker (P02 + P03) |
| 019 | xiaomi-onboarding | Quick | 018 + 012 | M02 | implementer + design-fidelity-checker (M02) + researcher (detect MIUI heurística) |
| 020 | settings | Medium | 010 + 011 + 012 + 013 | P06 | implementer + design-fidelity-checker (P06) |

> **P11 (Termos de Uso) e P12 (Política de Privacidade)** não estão no roadmap porque dependem de conteúdo legal fornecido pelo cliente, não de implementação. Quando o cliente entregar os textos, criar `spec-021-legal-pages` (Quick) referenciada a partir de `settings` (P06 → Sobre).

## Caminho crítico

3 paths bloqueiam ⅔ do app:

1. **Path do API Contract:** 001 → tudo. Sem `packages/shared/` expandido, todas as features duplicariam tipos.
2. **Path do native bridge:** 001 → 007 → 008 → 009. Sem câmera funcionando, nem replay buffer nem voice fazem sentido.
3. **Path do paywall:** 001 → 003 → 013 → 014. Sem RevenueCat configurado, paywall não funciona; sem paywall, gate de salvar vídeo não funciona.

Paths 2 e 3 podem ser paralelizados após 001 + 003.

## Gates contextuais aplicados por spec

Cada micro-sprint dentro de uma spec deve passar **antes** de avançar:

### Gates universais (toda spec)

- `bun run lint` zero issues
- `bun run typecheck` zero issues
- `bun run test` tudo verde
- Commit Conventional Commits 1.0.0 com scope do scope-enum
- Sem menção a `OkCamera` em código novo
- Sem `.env`/`keystore.jks`/`google-services.json` no diff

### Gates condicionais (do `.claude/slice-checklist.md`)

| Spec toca... | Gate disparado |
|---|---|
| Tela do protótipo (qualquer P0X/M0X) | `design-fidelity-checker` invocado com screen ID + tokens contra `Prototipo-RARO.html` |
| Method Channel novo | Contract test em iOS + Android + `<bridge>_contract.md` publicado |
| `pubspec.yaml` ou `package.json` | `warn-adr-drift` dispara; ADR novo obrigatório |
| `@riverpod` annotation | `run-riverpod-codegen` hook sinaliza; codegen rodado antes do commit |
| String UI nova | Inserida em `.arb` (pt-BR + en + es); `flutter gen-l10n` rodado |
| Evento analytics novo | Nome em `packages/shared/lib/src/events/analytics_events.dart`; sem PII |
| Native Swift/Kotlin | Compilação iOS + Android passa; SwiftLint/ktlint zero issues |
| Tela com baseline golden | `flutter test --update-goldens` + diff visual revisado |
| Mudança em navegação (`lib/app.dart`/router) | Integration test em device físico |

## Definition of Done por release

### v1.0.0 (release inicial)

- Todas as 20 specs concluídas e mergeadas
- 100% das 13 telas + 3 modais navegáveis
- Wake word `"Raro"` com taxa de detecção > 90% em ambiente silencioso (testado)
- Replay Buffer estável em iOS + Android (sem perda de frames, sem crashes em 4K)
- Lock mode reduz consumo de bateria ≥ 50% vs tela acesa (medido)
- App testado em ≥ 1 device Xiaomi/MIUI real
- i18n completa nos 3 idiomas (pt-BR / en / es)
- Free trial 30 dias confirmado funcional via RevenueCat (com pré-requisitos de loja configurados — ver memory `raro-pattern-revenuecat-trial-app-store-connect`)
- Salvar vídeo exige entitlement `premium` ativo
- Builds release `.ipa` + `.aab` com signing
- App aprovado e publicado em App Store + Google Play
- ADRs criados para todas as decisões arquiteturais novas (0013-0021)
- CHANGELOG atualizado a cada spec mergeada

Ver também [Blueprint Seção 11](Blueprint.md) e [docs/09-DOD.md](09-DOD.md).

## ADRs previstos durante o roadmap

| # | Tema | Quando | Memory relacionada |
|---|---|---|---|
| 0013 | API Contract sealed classes + SemVer do shared | spec-001 µ-sprint 1.7 | — |
| 0014 | Firebase bootstrap strategy + 3 error handlers | spec-002 µ-sprint 2.4 | `raro-pattern-crashlytics-3-handlers` |
| 0015 | RevenueCat strategy + StoreKit 2 + trial setup | spec-003 µ-sprint 3.4 | `raro-pattern-revenuecat-trial-app-store-connect`, `raro-pattern-revenuecat-error-handling` |
| 0016 | Contrato JSON `com.rarocamera/camera` Method Channel | spec-007 µ-sprint 7.1 | `raro-pattern-ios-avcapture-multicam-not-needed`, `raro-pattern-android-camerax-ultra-wide-unreliable` |
| 0017 | Contrato JSON `com.rarocamera/replay_buffer` | spec-008 µ-sprint 8.1 | `raro-pattern-ios-cvpixelbufferpool`, `raro-pattern-android-mediacodec-buffer-management` |
| 0018 | Contrato JSON `com.rarocamera/voice` + Privacy Manifest iOS | spec-009 µ-sprint 9.1 | `raro-pattern-ios-wake-word-no-native-api` |
| 0019 | Contrato JSON `com.rarocamera/volume` + App Store review notes | spec-010 µ-sprint 10.1 | `raro-pattern-ios-volume-button-kvo-app-store-review` |
| 0020 | Tema sem ColorScheme.fromSeed | spec-004 µ-sprint 4.2 | `raro-pattern-theme-no-color-scheme-from-seed` |
| **0021** | **Storage strategy: sandbox app vs MediaStore** | **spec-017 µ-sprint 17.1** (bloqueante para spec-015/016) | `raro-pattern-android-13-media-permissions` |

Total: 9 ADRs novos previstos (0013–0021), adicionados aos 12 existentes (0001–0012) = **21 ADRs no fim do v1.0**.

## Memories que devem ser lidas antes de implementar cada spec

Quando spec for executada via `/new-spec`, agente deve ler memories relevantes do diretório `~/.claude/projects/<projeto>/memory/`. Mapeamento por spec:

| Spec | Memories obrigatórias |
|---|---|
| 001 api-contract | todas — define types consumidos por todas |
| 002 firebase-init | `raro-pattern-crashlytics-3-handlers` |
| 003 revenuecat-init | `raro-pattern-revenuecat-error-handling`, `raro-pattern-revenuecat-trial-app-store-connect` |
| 004 theme-design-tokens | `raro-pattern-theme-no-color-scheme-from-seed` |
| 005 native-fonts | `raro-lib-google-fonts-vs-bundled` |
| 007 camera-native-bridge | `raro-pattern-ios-avcapture-multicam-not-needed`, `raro-pattern-android-camerax-ultra-wide-unreliable` |
| 008 replay-buffer | `raro-pattern-ios-cvpixelbufferpool`, `raro-pattern-android-mediacodec-buffer-management` |
| 009 voice-wake-word | `raro-pattern-ios-wake-word-no-native-api` |
| 010 volume-control | `raro-pattern-ios-volume-button-kvo-app-store-review` |
| 012 i18n-scaffold | `raro-pattern-flutter-i18n-synthetic-package-false` |
| 013 paywall | `raro-pattern-revenuecat-trial-app-store-connect`, `raro-pattern-revenuecat-error-handling` |
| 015 gallery | `raro-pattern-flutter-video-player-disposal` |
| 016 preview | `raro-pattern-flutter-video-player-disposal` |
| 017 permissions | `raro-pattern-android-13-media-permissions` |
| 019 xiaomi-onboarding | `raro-pattern-xiaomi-miui-hyperos-detection` |

## Como executar uma spec

Fluxo padrão (TLC Spec-Driven, [CLAUDE.md Seção 6](../CLAUDE.md)):

1. `/new-spec <slug>` — scaffold em `docs/superpowers/specs/`
2. `superpowers:brainstorming` — preencher conteúdo da spec
3. Avaliar sizing — confirmar Quick/Medium/Large
4. Se Medium ou Large: `/new-plan <slug>` + `superpowers:writing-plans`
5. `implementer` agent executa atomic tasks
6. `flutter-test-author` agent escreve testes red-first onde aplicável
7. Hooks PreToolUse/PostToolUse rodam automaticamente
8. `validator` agent confirma cumprimento da spec
9. `design-fidelity-checker` se tocou tela do protótipo
10. `adr-guardian` se mudou stack ou contrato
11. `/verify-slice` para gates universais + contextuais
12. `/commit` segue conventional + scope-enum
13. `/session-end` registra trabalho em `docs/sessions/`

## Próxima ação concreta

`/new-spec api-contract-shared` — primeira spec, expansão de `packages/shared/` com types canônicos. Spec detalhada em `docs/04-ROADMAP-SPECS/spec-001-api-contract-shared.md` (criada no µ-sprint RM-2).

## Detalhamento por bloco

- [RM-2: API Contract](04-ROADMAP-SPECS/spec-001-api-contract-shared.md) — spec única bloqueante
- [RM-3: Infra chores (002-005)](04-ROADMAP-SPECS/block-infra.md) — firebase, revenuecat, theme, fonts
- [RM-4: Native bridges (007-009)](04-ROADMAP-SPECS/block-bridges.md) — camera, replay, voice
- [RM-5: Features de produto (010, 013-016)](04-ROADMAP-SPECS/block-features.md) — volume, paywall, checkout, gallery, preview, lock
- [RM-6: Acabamento (006, 011, 012, 017-020)](04-ROADMAP-SPECS/block-polish.md) — splash, lock, i18n, permissions, onboarding, xiaomi, settings
