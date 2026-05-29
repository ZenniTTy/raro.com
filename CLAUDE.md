# CLAUDE.md — RARO (manual autoritativo)

> Authoritative manual para Claude Code e agentes equivalentes. AGENTS.md aponta pra cá. Qualquer instrução em outro arquivo é subordinada a este.

---

## 1. Karpathy 4 princípios (regem todo o trabalho)

1. **Think Before Coding** — antes de tocar código, faça surface das suposições, apresente trade-offs explícitos e pergunte se algo está unclear. Se a tarefa puder ter 2+ interpretações, escolha não inferir.
2. **Simplicity First** — o código mínimo que resolve o problema, nada especulativo. Sem abstrações para "futuro uso". Três linhas similares é melhor que uma abstração prematura.
3. **Surgical Changes** — toque só no que precisa. Cada linha alterada precisa rastrear até um pedido explícito (do usuário, do briefing, do Blueprint, de um ADR). Sem refactor "de passagem".
4. **Goal-Driven Execution** — defina critérios de sucesso antes de começar. Loop até verificar que os critérios estão atendidos. Sem declarar "pronto" sem evidência.

Detalhe complementar: este projeto também segue as **15 práticas Karpathy** para organização da memória (immutable sources em `docs/briefing/`, three-layer arch em `docs/01-10`, append-only log em sessions e CHANGELOG, schema config em AGENTS.md+CLAUDE.md).

---

## 2. Estado do projeto (versão e gates)

| Item | Estado |
|---|---|
| Blueprint | [docs/Blueprint.md](docs/Blueprint.md) Approved em 2026-05-25 |
| Fase atual do bootstrap | Spec-Driven (Fase 5) — 2 specs entregues (`api-contract-shared`/ADR-0013, `flutter-3.44-spm-migration`/ADR-0014) |
| Branch principal | `main` (devs em `develop` ou feature branches) |
| Bundle ID | `com.rarocamera` |
| Plataformas alvo | iOS 15+ / Android API 24+ |
| Wake word | `"Raro"` (NÃO `"OkCamera"`) |
| Free trial | 30 dias |
| Planos | Mensal R$ 9,90 + Anual R$ 89,90 |

---

## 3. Stack e versões fixadas

Ver [docs/Blueprint.md Seção 2](docs/Blueprint.md) para a tabela completa. Resumo:

- **Flutter** `>=3.44.0 <4.0.0` · **Dart** `^3.12.0`
- **Riverpod 3** com codegen (`@riverpod` annotation, `part '*.g.dart'`) — `flutter_riverpod ^3.3.1`
- **go_router** `^17.2.3`
- **purchases_flutter** `^10.1.1` (RevenueCat)
- **firebase_core** `^4.9.0` + analytics `^12.4.1` + crashlytics `^5.2.2`
- **shared_preferences** `^2.5.5`, **path_provider** `^2.1.5`, **permission_handler** `^12.0.1`, **share_plus** `^13.1.0`, **device_info_plus** `^13.1.0`, **intl** `^0.20.2`, **logger** `^2.7.0`
- **alchemist** `^0.14.0` (goldens) + **mocktail** `^1.0.5`
- **Native bridges** iOS (Swift/AVFoundation) + Android (Kotlin/CameraX) para camera, replay_buffer, voice, volume

Atualizar dep = abrir ADR. Sem exceção.

---

## 4. MCP precedence (resolução de docs)

Quando precisar de doc de lib externa, a ordem é:

1. **Context7 MCP** (`mcp__plugin_context7_context7__resolve-library-id` + `query-docs`) — sempre prioritário para libs com cutoff de training (Flutter, Riverpod, RevenueCat, Firebase, go_router, etc.)
2. **pub.dev API** (`curl https://pub.dev/api/packages/<lib>`) — fallback para descobrir versão `latest` quando Context7 não tem.
3. **Documentação oficial** via WebFetch — última opção, mas só com URL conhecida.
4. **Memória de treino** — proibido. Qualquer "eu acho que a versão é X" deve ser validado em 1, 2 ou 3 antes.

---

## 5. Convenções de código

### Dart / Flutter (apps/mobile)

- **Riverpod 3 com codegen.** Não use `Provider/ChangeNotifier` legados. Annotation `@riverpod` + `part 'file.g.dart'`. Codegen via `bun --filter @raro/mobile run codegen`.
- **Snake_case** em filenames Dart.
- **Strict lints** em [apps/mobile/analysis_options.yaml](apps/mobile/analysis_options.yaml): `strict-casts`, `strict-inference`, `strict-raw-types`, `require_trailing_commas`, `prefer_const_constructors`, `avoid_print`, `avoid_relative_lib_imports`.
- **Feature folder layout:** `lib/features/<feature>/{application,data,domain,presentation}/`.
- **Imports absolutos** via `package:raro_mobile/...` (não relativos).
- **Sem comentários em production code.** Nomes explicam WHAT; se precisar de WHY, ADR ou doc.

### Native (Swift/Kotlin)

- Swift: SwiftLint, line length 120.
- Kotlin: ktlint default.
- Method Channels: namespace `com.rarocamera/<feature>`.
- Contrato JSON-serializável documentado em `apps/mobile/lib/core/native_bridges/<bridge>_contract.md` ANTES da implementação (spec dedicada na Fase 5).

### Shared (packages/shared)

- Dart puro (sem Flutter).
- Só constantes, enums, event names, types compartilháveis. Sem lógica.
- Hard rule: `wakeWord` em `VoiceConfig` é `'Raro'`. Qualquer PR que mude isso é bloqueado.

### Commits — Conventional Commits 1.0.0

- Format: `<type>(<scope>): <description>`
- Types permitidos: `feat`, `fix`, `refactor`, `docs`, `style`, `test`, `chore`, `perf`, `build`, `ci`, `revert`.
- Scope-enum em [commitlint.config.cjs](commitlint.config.cjs).
- Subject **lowercase**, ≤100 chars, sem ponto final.
- Header ≤100 chars, body lines sem limite.
- **Nunca** `--no-verify`. Falha em hook = corrigir causa, não bypassar.

---

## 6. Workflow de feature (TLC Spec-Driven 4 fases)

4 fases adaptativas: **Specify** → **Design** → **Tasks** → **Execute**. Auto-sizing decide quantas fases rodar.

### Auto-sizing

| Tamanho | Quando | Workflow |
|---|---|---|
| **Quick** (≤3 arquivos, sem mudança arquitetural) | Bugfix, copy tweak, ajuste visual | Specify direto na conversa → Execute → `/commit`. Pula Design e Tasks. |
| **Medium** (1 feature, multi-file, sem novo bridge) | Tela completa, lógica de UI | `/new-spec <slug>` → `superpowers:brainstorming` → implement com `implementer` → `/verify-slice` |
| **Large** (novo bridge, novo ADR, multi-feature) | Native bridge, mudança de stack | `/new-spec` → `brainstorming` → `/new-plan` → `superpowers:writing-plans` → `implementer` → `validator` → `design-fidelity-checker` (se UI) → ADR commit → `/verify-slice` |

### Arquivos canônicos

- Templates: [`docs/superpowers/specs/0000-template.md`](docs/superpowers/specs/0000-template.md) + [`docs/superpowers/plans/0000-template.md`](docs/superpowers/plans/0000-template.md)
- Specs criadas: `docs/superpowers/specs/<YYYY-MM-DD>-<slug>-design.md`
- Plans criados: `docs/superpowers/plans/<YYYY-MM-DD>-<slug>.md`

### Sinais que escalam a fatia

Mesmo começando como Quick, escala para Medium/Large se:

- Tocar Method Channel (native bridge)
- Tocar `pubspec.yaml`, `package.json`, `turbo.json` ou qualquer config root
- Tocar `Blueprint.md` em decisão técnica
- Adicionar dep nova
- Mudar wake word, free trial, SKUs (não negociáveis sem ADR)
- Mudar 3+ telas
- Tocar > 5 arquivos

Se algum sinal disparar mid-flight, **pare**, abra spec/plan e retome.

### Primeira spec sugerida

`feat/camera-native-bridge` (Roadmap prioridade 1). Valida pipeline native bridge crítico cedo, conforme [Blueprint Seção 11](docs/Blueprint.md).

---

## 7. Subagents disponíveis (Fase 4)

Configurados em `.claude/agents/` (a serem criados na Fase 4). Lista canônica:

| Agent | Tools | Quando usar |
|---|---|---|
| **implementer** | `Write, Edit, MultiEdit, Bash` | Implementar features seguindo plan |
| **validator** | `Read, Grep, Glob, Bash` (zero write) | Verificar implementação contra spec, sem alterar código |
| **adr-guardian** | `Read, Grep` | Antes de mudança de stack, valida se há ADR |
| **flutter-test-author** | `Write, Edit, Read, Bash` (TDD) | Escrever testes red-before-green para use cases |
| **flutter-perf-auditor** | `Read, Grep, Bash` (read-only) | Auditar performance: rebuild count, memory, jank |
| **design-fidelity-checker** | `Read, Grep, Bash` | Comparar tela implementada vs protótipo (cores, gradients, copy, microinterações) |
| **researcher** | `Context7 MCP, WebFetch, Read` | Pesquisa de libs e padrões antes de Blueprint update |

---

## 8. Hooks (Fase 4)

Em `.claude/hooks/`. 6 hooks registrados em eventos + 1 utilitário invocável manualmente:

| Hook | Evento | Comportamento |
|---|---|---|
| `block-env.sh` | PreToolUse Write/Edit/MultiEdit | Bloqueia escrita em `.env`, `key.properties`, `keystore.jks`, `GoogleService-Info.plist`, `google-services.json` |
| `block-secrets.sh` | PreToolUse Write/Edit/MultiEdit | Bloqueia content com api_key, private_key, BEGIN PEM, etc. |
| `warn-adr-drift.sh` | PreToolUse Write/Edit/MultiEdit | Avisa (não bloqueia) se mudança toca pubspec/Blueprint/native_bridges sem ADR novo no branch |
| `format-dart.sh` | PostToolUse Write/Edit/MultiEdit | Roda `dart format` em `*.dart` editado (ignora `*.g.dart`, `*.freezed.dart`) |
| `run-riverpod-codegen.sh` | PostToolUse Write/Edit/MultiEdit | Detecta `@riverpod` e sinaliza necessidade de codegen (não roda inline) |
| `reinject-roadmap.sh` | SessionStart | Ecoa locked invariants + estado de sessions/0001-INDEX.md |
| `verify-task.sh` | (utilitário, sem evento) | Invocável manualmente via `/verify-slice`. Roda `bun run lint && bun run test`. NÃO em Stop event porque seria executado a cada turno do agente. |

---

## 9. Slash commands (Fase 4)

Em `.claude/commands/`. 8 commands:

- `/commit` — guided flow de commit conventional
- `/session-end` — fecha session log
- `/docs-lint` — verifica broken links e orphans em docs/
- `/prime` — re-lê manual completo (Blueprint + ADRs ativos)
- `/new-spec <feature>` — scaffold de spec
- `/new-plan <feature>` — scaffold de plan
- `/verify-slice` — orquestra checagem pre-PR (analyze + test + design-fidelity)
- `/ingest-source` — extrai conteúdo de fonte externa para `docs/`

---

## 10. Hard gates contextuais

Antes de declarar feature pronta:

| Toque | Gate |
|---|---|
| Tocou `lib/app.dart` ou navegação | Integration test passa em device real |
| Tocou tela com baseline golden | Regenerar goldens via `alchemist` e diff visual aprovado |
| Tocou Method Channel | Contract test do bridge passa em ambas plataformas |
| Tocou tela que existe no protótipo | Design-fidelity-checker compara cores, gradients, copy, microinterações |
| Mudou dep ou stack | ADR aberto e mergeado antes |

---

## 11. Anti-patterns proibidos

- ❌ Mencionar `OkCamera`, `Ok Camera`, ou variações em qualquer lugar do repo
- ❌ Hardcoded de valores que devem estar em `raro_shared` (wake word, SKUs, free trial dias)
- ❌ `Provider` ou `ChangeNotifier` legados — só Riverpod 3 codegen
- ❌ Imports relativos `../../../`
- ❌ Comentários explicando WHAT em código de produção
- ❌ `setState` em tela que já usa Riverpod (escolha um)
- ❌ Catch-all `try { } catch (_) {}` sem log + rethrow ou tratamento explícito
- ❌ Strings literais de UI fora de `.arb` (i18n)
- ❌ Asset path absoluto (sempre `assets/` relativo)
- ❌ `print()` em produção (usar `logger`)
- ❌ Codificar enum tipado em `String(<enum>.rawValue)` ao cruzar Pigeon (perde semântica). Use `"\(code)"` (nome simbólico) ou route via `FlutterApi` callback tipado.
- ❌ `expect(state, isA<T>())` sem assertions de campo. TDD requer pin de comportamento: cada branch da implementação deve ter ≥1 teste que falha se a branch for removida.
- ❌ Swallow de erros via `do { try ... } catch {}` sem log (Swift) ou `try { } catch (_) {}` sem log (Dart/Kotlin). Sempre logar via `logger` ou rethrow com contexto.
- ❌ Assumir que arquivo `Generated. Do not edit.` respeita configuração externa (ex: `IPHONEOS_DEPLOYMENT_TARGET` do `project.pbxproj`). Sempre ler o code que gera antes de tentar fix. Ex: Flutter 3.44 hardcoda iOS 13 em `darwin.dart:71` independente do pbxproj — fix é Xcode Build Phase (ver memória `raro-pattern-flutter-spm-ios-13-hardcoded` + ADR-0015 addendum).
- ❌ Editar arquivo gerado e esperar persistência. Se precisar patchar gerado, faça-o via Build Phase / hook / pre-commit que reaplica em todo build.
- ❌ Improvisar workaround antes de WebSearch + docs oficiais. Para qualquer problema de SDK/framework, **primeiro** consultar (a) docs oficial, (b) issue tracker do projeto, (c) Context7 — só então inventar. Ex: bug Flutter SPM iOS 13 tinha solução documentada em `docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers` o tempo todo.
- ❌ Usar Xcode **Build Phase** para fix de SPM. Build Phases rodam DEPOIS de SPM Package Resolution. Para qualquer hook que precise mexer em SPM antes do build, usar **Scheme Pre-action** (`xcshareddata/xcschemes/<Scheme>.xcscheme` → `<PreActions>`).
- ❌ Chamar `flutter build`, `pod install`, ou qualquer comando que regenere `project.pbxproj`/`xcworkspace` **dentro** de Xcode Scheme Pre-action. Modifica o workspace durante o build e o Xcode aborta silenciosamente (status falso "succeeded", zero Build Phases executadas). Pre-actions devem ser instantâneas (<1s), read-only ou patches mínimos via `sed`. Roda `flutter build ios --config-only` offline via `bun run pub:get` ou terminal — nunca dentro do build. Ver `raro-pattern-xcode-preaction-modifies-workspace`.
- ❌ Confiar no status "BUILD SUCCEEDED" do Xcode sem inspecionar `.xcactivitylog`. Pre-actions que abortam build não falham o status do scheme. Use `xclogparser parse --reporter flatJson` em `~/Library/Developer/Xcode/DerivedData/<Proj>-*/Logs/Build/*.xcactivitylog` para verificar que Build Phases (Compile/Link/Sources) efetivamente rodaram, não só Pre-actions.
- ❌ Adicionar plugin Flutter iOS no `pubspec.yaml` sem ler o **README de setup iOS** do plugin. Plugins com flag-based compilation (`permission_handler`, `firebase_messaging` background mode, `flutter_local_notifications` etc.) exigem macros no `Podfile post_install` (ex: `PERMISSION_CAMERA=1`) — sem isso, o plugin retorna estados sintéticos (`denied`, `unavailable`) silenciosamente, **sem stack trace e sem chamar APIs nativas**. Diagnosticar via `grep PERMISSION_ ios/Pods/Pods.xcodeproj/project.pbxproj` — vazio = macros ausentes. Ver `raro-pattern-permission-handler-ios-podfile-macros`.
- ❌ Inventar fix para bug em device físico sem ler logs reais primeiro. Build: `xclogparser parse --reporter flatJson`. Runtime: instrumentar `os_log` estratégico + pedir conteúdo do Xcode Console ao usuário. **`idevicesyslog` da libimobiledevice NÃO captura logs de apps de terceiros em iOS 18+** — só sistema. Ver `feedback_device_debug_use_real_logs_not_assumptions`.
- ❌ Tratar a tela "iOS 14+ debug mode Flutter apps can only be launched from Xcode" como bug. **É restrição arquitetural Apple+Flutter** (debug usa JIT, JIT exige conexão Xcode). Para testar lifecycle (background→foreground, permission denied → openAppSettings → volta): usar Control Center / multitasking parcial (não fecha app). Para release no device físico real precisa Apple Developer Program ($99/ano) — free tier não basta. Ver `raro-pattern-flutter-debug-vs-release-on-device`.
- ❌ Assumir que "Clean Build Folder" do Xcode resolve erro `firebase requires 15.0 but target supports 13.0`. **Não resolve** — esse erro vem de combinação de 3 estados desincronizados: (a) `ios/Flutter/Generated.xcconfig` + `Debug.xcconfig` + `Release.xcconfig` ausentes (gitignored, regenerados por `flutter pub get`); (b) `Package.swift` ephemeral regerado em iOS 13 (`darwin.dart:71` hardcoda); (c) `DerivedData/Runner-*` cacheado contra estado antigo. Fix correto: quit Xcode → `bun --filter @raro/mobile run pub:get` → `rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*` → reabrir Xcode → aguardar Package Resolution → build. Triggers: `flutter clean`, `git clean -fd`, Xcode `Reset Package Caches`, troca de destino do build. Plans iOS-touching incluem `bun pub:get` na Phase 0 pre-flight. Ver `raro-pattern-flutter-ios-regen-xcconfig-spm-recovery`.

---

## 12. Onde está o quê

| Pergunta | Local |
|---|---|
| Decisões arquiteturais | [docs/Blueprint.md](docs/Blueprint.md) + [docs/decisions/](docs/decisions/) |
| Por que dep X tem versão Y? | ADR em `docs/decisions/` + Blueprint Seção 2 |
| Como ficou a tela P05 (Câmera)? | Protótipo [docs/briefing/prototype/Prototipo-RARO.html](docs/briefing/prototype/Prototipo-RARO.html) (linha 824+ no HTML) + Blueprint Seção 5 |
| Quais eventos analytics? | `packages/shared/lib/src/events/analytics_events.dart` |
| Como rodar codegen? | `bun --filter @raro/mobile run codegen` |
| O que entrou neste release? | [docs/10-CHANGELOG.md](docs/10-CHANGELOG.md) |
| Última session de trabalho? | [docs/sessions/0001-INDEX.md](docs/sessions/0001-INDEX.md) |
| Como retomar trabalho depois de pausa? | [docs/sessions/0001-INDEX.md#como-retomar](docs/sessions/0001-INDEX.md) (próxima sessão sugerida + prompt + recovery) + comando `/prime` |

---

## 13. Workflow iOS — terminal-first (anti-loop SPM)

**Build/run/test iOS sempre via terminal**, não via Xcode UI. Esse é o workflow sênior 2026 com agents (Claude/Cursor/Copilot) + iPhone físico.

| Operação | Comando | Por quê NÃO usar Xcode UI |
|---|---|---|
| Rodar app no iPhone 12 / Simulator | `bun --filter @raro/mobile run dev:ios -- -d "<device-id>"` | Encadeia `flutter pub get → fix-spm sed (Package.swift 13→15) → bootstrap-permissions → flutter run`. Xcode UI ⌘B pula o `fix-spm` (Pre-action só dispara em scheme actions, NÃO em SPM Resolve automático), causando regressão recorrente Firebase 15 vs 13. |
| Tests Flutter | `bun --filter @raro/mobile run test` | — |
| Native XCTest (RunnerTests) | `bun --filter @raro/mobile run test:ios` | Auto-detecta Simulator disponível (iPhone 17/16/15/14/13 fallback) + encadeia pub:get + fix-spm |
| Verify build compila para simulator | `cd apps/mobile && flutter build ios --simulator --no-codesign` | (pre-existe: `SUPPORTED_PLATFORMS = iphoneos` bloqueia release/profile, mas debug funciona) |
| Análise | `bun --filter @raro/mobile run analyze` | — |

**Xcode UI usado APENAS para**:
- Edit signing/capabilities (Bundle ID, entitlements, provisioning profile)
- Debug breakpoints quando attach a um processo iOS rodando
- Inspecionar storyboards/asset catalogs (raro)
- Configurar Scheme Pre-actions/Build Phases (excepcional)

**❌ NÃO usar Xcode UI para**:
- Build (⌘B) ou Run (⌘R) — usar terminal
- "Reset Package Caches" + "Resolve Package Versions" — terminal `bun pub:get` faz isso corretamente
- Trocar destination de build — terminal já passa via `-d <device-id>` ou `--simulator`

**Se o loop SPM iOS 13/15 voltar a aparecer:**
1. Quit Xcode completamente (⌘Q)
2. Rodar `bun --filter @raro/mobile run pub:get` (encadeia recovery)
3. Se persistir: `rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*`
4. Reabrir SOMENTE para signing/debug — não para build
5. Build via terminal

Memória: `raro-pattern-flutter-ios-regen-xcconfig-spm-recovery` (workflow recovery) + `feedback_ios_workflow_terminal_first_no_xcode_build` (esse anti-pattern).

---

## 14. Quando em dúvida

1. Re-leia esta seção (`CLAUDE.md`).
2. Re-leia o Blueprint.
3. Compare com o protótipo (HTML).
4. Pergunte ao usuário, NÃO infira.

Confronte ambiguidade antes de agir. Stress-test propostas. Nunca concorde por default.
