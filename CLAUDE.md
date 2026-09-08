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
| Fase atual do bootstrap | Finalização para entrega (PLANO-MESTRE, 6 blocos). Bloco 0 fechado 2026-06-22 (Android compila — appbundle ✓; App ID alinhado; label "Raro Camera"; ONNX dormente). Bloco 1 (Firebase) FECHADO 2026-07-14 (0034 código+build, 0035 provado no iPhone 12: initializeApp + 3 handlers Crashlytics + analytics ligado; crash chegou no painel + dSYM; ADR-0025). Sprint 2 iOS done-com-drift (RevenueCat ainda mock); wake-word background STANDBY (ONNX reprovado 0029, aguarda Sensory), foreground SFSpeech funciona. Sessão 0036 (2026-07-15/16, 1º teste em Android físico — Galaxy M54): Android DESTRAVADO — INTERNET no manifest release, SafeArea edge-to-edge em 4 telas, câmera sobrevive a Config (`bindIfReady`; PR #3 merged em develop); câmera FULL-BLEED nas 2 plataformas (ADR-0027; `PreviewView COMPATIBLE` obrigatório; PR #4 merged). Sessão 0037 (2026-07-17): pacote pré-APK decomposto em 4 fatias (Gravação → Foco → Voz → i18n; 4 specs escritas, validadas em Context7). **Fatia 1 (gravação Android) FECHADA — PR #5 merged:** CameraX `VideoCapture<Recorder>` (ADR-0030, Blueprint atualizado; dep `camera-video:1.6.1`); grava MP4+áudio, provado no M54 via ffprobe (h264 3840×2160 + aac 48kHz estéreo); thumbnail via MediaMetadataRetriever; vault/sidecar já eram Dart. Fixes de device: thumbnail no vault (não cacheDir), botões preview respeitam navbar. Auditoria 3-lentes corrigiu 3 bugs silenciosos (áudio degradado, FallbackStrategy p/ não derrubar Preview, thumbnail parcial) + mic-negado→PermissionDenied. **Gravação Android REAL agora funciona** (era stub). Sessão 0038 (2026-07-18): **Fatia 2 (tap-to-focus Android) FECHADA — PR #7 MERGEADO:** tap no NATIVO (`GestureDetector.onSingleTapUp` + `previewView.meteringPointFactory`), ring nativo, `onFocusChanged` honesto (`isFocusSuccessful` real via `onFocusResult`, paridade iOS); ring animado por `Choreographer` (o M54 tem `animator_duration_scale=0` → ValueAnimator/AnimatorSet pulam pro fim; só o log revelou); auditoria 3-lentes: 3 achados corrigidos. **Fatia 3 (voz Android) — PR #8 ABERTO, provada no M54:** ADR-0029 (fonte primária: `checkRecognitionSupport`=API33 não 31, Vosk AAR **0.3.75** / ADR-0034 — **0.3.50** é tag C++ não AAR, FGS microphone while-in-use). Spike-gate provou `installed=[pt-BR]` on-device. **Arquitetura = Vosk MOTOR ÚNICO** (foreground+background, um só `AudioRecord`, ZERO handoff) — 3 passadas de auditoria provaram que 2 motores de mic (SpeechRecognizer nativo + Vosk) com handoff por tempo é frágil (double-mic, inBackground travado, FGS async); dono decidiu motor único, -213 linhas, `ForegroundVoiceRecognizer` REMOVIDO (nativo fica p/ otimização futura via spike-gate). **Debug no device (voz não reconhecia):** vosk-small em reconhecimento LIVRE não ouve "raro" e transcreve aproximado ("parar"→"para"); fix = `Recognizer` com **gramática restrita** + parser por **radical** (grav/par, prefixo, wake word opcional) + debounce 2000ms + `reset()` (memória `raro-pattern-vosk-small-needs-restricted-grammar`). Prova: `[raro gravar]→START`/`[raro parar]→STOP`, **dono confirmou câmera gravou por voz**; sem transcript bruto em log (privacidade). Próximo: **Fatia 4 (i18n PT/EN/ES)** — última do pacote; depois o APK do cliente. Build APK: usar JBR 21 do Android Studio como `JAVA_HOME` (Homebrew JDK 26 quebra o Kotlin). |
| Branch principal | `main` (devs em `develop` ou feature branches) |
| Bundle ID | `com.rarocamera` (iOS + Android `applicationId` alinhados — Bloco 0.3 resolvido 2026-06-22; `namespace` Kotlin segue `com.rarocamera.raro_mobile`, ok divergir). Imutável pós-publicação |
| Plataformas alvo | iOS 15+ / Android API 24+ |
| Wake word | `"Raro"` (NÃO `"OkCamera"`) — FOREGROUND SFSpeech funciona ('raro gravar'/'raro parar'); BACKGROUND ONNX inviável (sessão 0029) em STANDBY (Sensory). NÃO reabrir treino ONNX sem ADR. |
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

- **Riverpod 3 com codegen.** Não use `Provider/ChangeNotifier` legados. Annotation `@riverpod` + `part 'file.g.dart'`. Codegen via `bun run --filter '@raro/mobile' codegen`.
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

## 6. Workflow de feature (1 sessão = 1 entregável fechado)

### Regras não-negociáveis (vigentes a partir de Sprint 1)

1. **1 sessão = 1 entregável fechado declarado upfront.** "Entregável fechado" = (a) UI fiel ao prototype, (b) navegação in/out funciona, (c) estado persiste se aplicável, (d) testes não regridem. Mid-flight tangents proibidas — viram backlog de Sessão+1.
2. **Toda sessão começa com `/prime`** + audit do Sprint MD vigente (usuário invoca).
3. **Toda sessão termina com `/session-end`** que: appenda em `docs/sessions/`, define objetivo da próxima sessão em 1 linha, commit `docs(docs): close session N` (scope `session` não existe no scope-enum — usar `docs`).
4. **Workflows multi-agent são opt-in via `/audit`**, nunca default. Se necessidade de audit adversarial surgir mid-feature, isso é SINAL pra parar e criar spec dedicada — não interromper a sessão atual.

### Sprint MDs ativos

Roadmap vigente: `docs/superpowers/plans/PLANO-MESTRE-finalizacao-entrega-cliente.md` (6 blocos). sprint-1 fechado; sprint-2 done-com-drift; sprint-3 reindexado pelo Bloco 3 do PLANO-MESTRE.

### Spec/plan templates (uso de exceção, não rotina)

Pra mudança fora dos Sprint MDs (ex: nova lib externa, mudança arquitetural não-roadmap):
- `docs/superpowers/specs/0000-template.md` + `docs/superpowers/plans/0000-template.md`

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

Em `.claude/hooks/`. 10 hooks registrados em eventos + 1 utilitário invocável manualmente:

| Hook | Evento | Comportamento |
|---|---|---|
| `block-env.sh` | PreToolUse Write/Edit/MultiEdit | Bloqueia escrita em `.env`, `key.properties`, `keystore.jks`, `GoogleService-Info.plist`, `google-services.json` |
| `block-secrets.sh` | PreToolUse Write/Edit/MultiEdit | Bloqueia content com api_key, private_key, BEGIN PEM, etc. |
| `warn-adr-drift.sh` | PreToolUse Write/Edit/MultiEdit | Avisa (não bloqueia) se mudança toca pubspec/Blueprint/native_bridges OU contrato Pigeon source (`apps/mobile/pigeons/*.dart`) sem ADR novo no branch |
| `block-forbidden-terms.sh` | PreToolUse Write/Edit/MultiEdit | Bloqueia termos de marca proibidos (`OkCamera`, `Ok Camera`, `hey OkCamera`, `okCamera`, `ok_camera`); wake word é `"Raro"` (ADR-0009). Lista espelha `packages/shared/lib/src/contract/forbidden_terms.dart` |
| `block-pigeon-error-rawvalue.sh` | PreToolUse Write/Edit/MultiEdit (`.swift`/`.kt`) | Bloqueia `String(<enum>.rawValue)` / `.rawValue.toString()` dentro de `PigeonError()`/`FlutterError()` — preserva semântica do enum na fronteira Pigeon |
| `warn-gesturedetector-over-platformview.sh` | PreToolUse Write/Edit/MultiEdit (`.dart`) | Avisa (não bloqueia) se `GestureDetector` envolve `UiKitView`/`AndroidView` com `EagerGestureRecognizer` — tap vai pro nativo, `onTapDown` do pai não dispara (causou focus ring sumir). Detectar tap no nativo. Memória `raro-pattern-flutter-platformview-tap-must-be-native` |
| `warn-sfspeech-recycle-per-error.sh` | PreToolUse Write/Edit/MultiEdit (`.swift`) | Avisa (não bloqueia) se edit mexe no ciclo de `SFSpeechRecognitionTask` perto de erro/cancel — NÃO reciclar a cada `1110` benigno (no-speech); on-device finaliza em silêncio por design, reciclo agressivo deixa o request nil na janela morta e o comando some ("raro parar" caía no vão; quase custou migração p/ OpenWakeWord na S2.C). Padrão: token de ciclo + ring buffer + refresh proativo 50s. Memória `raro-pattern-sfspeech-continuous-no-recycle-per-error` |
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
| Tocou hot path de focus/zoom/exposure (CameraPlatformView, AVCaptureDevice config, Method Channel de câmera) | Perceived latency validation manual em iPhone físico (não Simulator): rodar `bun run --filter '@raro/mobile' dev:ios -- -d <udid>` e validar tap→ring visível <50ms, tap→focus locked <300ms; instrumentar `os_log` com subsystem dedicado (ex: `com.rarocamera/focus`) em entry/exit dos handlers e anexar trecho do Xcode Console no PR. Em Sessão 2+ substituído por `integration_test --machine` + Pigeon `CameraDebugHostApi` lendo `AVCaptureDevice.focusPointOfInterest` (ADR-0016, harness E2E híbrido) |
| Tocou animação `CALayer`/`CATransaction` em `PlatformView` | Smoke test em device físico: ring visível em sub-frame (<16ms); XCTest com expectation valida que `layer.animation(forKey:)` retorna não-nil após `showFocusRing`; opcionalmente gravar tela 240fps para validar percepção real |
| Tocou caminho que decide resolução/fps/codec gravado (`selectDevice`, `applyFormat`/`setFormat`, `discoverCapabilities`, `AVAssetWriter` settings, `FormatCapability`/`CameraCapabilities` no Pigeon) | Prova objetiva de formato em iPhone físico (não Simulator): gravar 1 clipe por formato afetado, puxar o `.mp4` do vault via `xcrun devicectl device copy from --domain-type appDataContainer ...` e rodar `ffprobe -v error -select_streams v:0 -show_entries stream=width,height,r_frame_rate` — anexar a saída no PR comprovando dimensões+fps reais (ex: `3840×2160 @ 60`). Teste Dart/widget não detecta fallback silencioso de formato (ADR-0021, bug 4K60 sessão 0020) |
| Tocou reconhecimento de voz contínuo (`VoiceManager.swift`, ciclo `SFSpeechRecognitionTask`/`recognitionTask`, handling de `kAFAssistantErrorDomain`) | **(1) Confirmar install ANTES de pedir teste:** `flutter build ios --profile` + `xcrun devicectl device install app` e ler `App installed:` + container UUID novo (debug não roda standalone — memória `feedback_verify_device_install_before_test`). **(2) Prova de log do device** via `pymobiledevice3 syslog live --match Runner`: contar reciclos (`benign, refreshing`) « N e múltiplos `wake matched` (start E stop) — métrica idêntica ao teste anterior = binário velho. NÃO reciclar a recognitionTask a cada erro `1110` benigno (no-speech); usar token de ciclo + ring buffer de áudio (ADR-0022, memória `raro-pattern-sfspeech-continuous-no-recycle-per-error`, sessão 0024) |
| Vai concluir "framework/lib X é incapaz" e abrir ADR de troca de stack | Provar a incapacidade com **log LIMPO do device + fonte primária** ANTES do ADR — não com "N análises convergiram" sobre a mesma suposição. N fixes empilhados = questionar o NOSSO uso da API, não a capacidade dela. S2.C declarou SFSpeech beco-sem-saída e quase migrou p/ OpenWakeWord (semanas); a 0024 achou a causa real (reciclo surdo) em minutos e resolveu sem trocar de engine (memória `feedback_many_native_fixes_means_reread_logs_not_abandon_framework`) |

---

## 11. Anti-patterns proibidos

> **Critério (Sprint 1 Task B, 2026-05-29):** um anti-pattern fica aqui só se (a) impacto não-recuperável, (b) aplicável a >1 feature, ou (c) não cabe em memória. Padrões hyper-específicos (iOS/AVFoundation/CALayer/SPM/Pigeon/TDD/perf) foram movidos pra memória local + hooks (§8). Reduzido 29 → 11. Índice completo das memórias: `MEMORY.md` no diretório de memória do projeto.

- ❌ Mencionar `OkCamera`, `Ok Camera`, ou variações em qualquer lugar do repo
- ❌ Hardcoded de valores que devem estar em `raro_shared` (wake word, SKUs, free trial dias)
- ❌ `Provider` ou `ChangeNotifier` legados — só Riverpod 3 codegen
- ❌ Imports relativos `../../../`
- ❌ Comentários explicando WHAT em código de produção
- ❌ `setState` em tela que já usa Riverpod (escolha um)
- ❌ Swallow de erro sem log — `try { } catch (_) {}` (Dart/Kotlin) ou `do { try ... } catch {}` (Swift). Sempre logar via `logger` ou rethrow com contexto.
- ❌ Strings literais de UI fora de `.arb` (i18n)
- ❌ Asset path absoluto (sempre `assets/` relativo)
- ❌ `print()` em produção (usar `logger`)
- ❌ Improvisar workaround antes de WebSearch + docs oficiais. Para qualquer problema de SDK/framework, **primeiro** consultar (a) docs oficial, (b) issue tracker do projeto, (c) Context7 — só então inventar.

---

## 12. Onde está o quê

| Pergunta | Local |
|---|---|
| Decisões arquiteturais | [docs/Blueprint.md](docs/Blueprint.md) + [docs/decisions/](docs/decisions/) |
| Por que dep X tem versão Y? | ADR em `docs/decisions/` + Blueprint Seção 2 |
| Como ficou a tela P05 (Câmera)? | Protótipo [docs/briefing/prototype/Prototipo-RARO.html](docs/briefing/prototype/Prototipo-RARO.html) (linha 824+ no HTML) + Blueprint Seção 5 |
| Quais eventos analytics? | `packages/shared/lib/src/events/analytics_events.dart` |
| Como rodar codegen? | `bun run --filter '@raro/mobile' codegen` |
| O que entrou neste release? | [docs/10-CHANGELOG.md](docs/10-CHANGELOG.md) |
| Última session de trabalho? | [docs/sessions/0001-INDEX.md](docs/sessions/0001-INDEX.md) |
| Como retomar trabalho depois de pausa? | [docs/sessions/0001-INDEX.md#como-retomar](docs/sessions/0001-INDEX.md) (próxima sessão sugerida + prompt + recovery) + comando `/prime` |

---

## 13. Workflow iOS — terminal-first (anti-loop SPM)

**Build/run/test iOS sempre via terminal**, não via Xcode UI. Esse é o workflow sênior 2026 com agents (Claude/Cursor/Copilot) + iPhone físico.

> **⚠️ Forma do `bun` (bun 1.3.13):** usar **`bun run --filter '@raro/mobile' <script>`** (filter DEPOIS de `run`). A forma `bun --filter X run <script>` falha com `error: No packages matched the filter`. Memória `raro-pattern-bun-filter-arg-order`.
>
> **⚠️ Build iOS neste sandbox exige 2 git overrides do SPM.** O sandbox injeta `safe.bareRepository=explicit` + bloqueia `protocol.file.allow`, fazendo o SwiftPM falhar em `Could not resolve package dependencies` ("Couldn't get the list of tags" / "Couldn't check out revision"). Prefixar qualquer `flutter build`/`flutter run`/`dev:ios` com:
> ```bash
> GIT_CONFIG_COUNT=2 \
>   GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all \
>   GIT_CONFIG_KEY_1=protocol.file.allow GIT_CONFIG_VALUE_1=always \
>   bun run --filter '@raro/mobile' dev:ios -- -d <udid>
> ```
> NÃO apagar o cache SPM (não está corrompido). Memória `raro-pattern-spm-safe-bare-repository-sandbox`.
>
> **⚠️ Modo debug não roda standalone no device** (tela "iOS 14+ debug mode can only be launched from Xcode"). Para validação perceptual em iPhone físico via terminal, usar **`flutter build ios --profile`** + `xcrun devicectl device install/launch` (roda standalone, sem JIT). `flutter run` em Xcode 26/CoreDevice tem bug conhecido (Flutter issue #179234 — erro 74 no deploy). Memória `raro-pattern-flutter-debug-vs-release-on-device`.

| Operação | Comando | Por quê NÃO usar Xcode UI |
|---|---|---|
| Rodar app no iPhone 12 / Simulator | `bun run --filter '@raro/mobile' dev:ios -- -d "<device-id>"` | Encadeia `flutter pub get → fix-spm sed (Package.swift 13→15) → bootstrap-permissions → flutter run`. Xcode UI ⌘B pula o `fix-spm` (Pre-action só dispara em scheme actions, NÃO em SPM Resolve automático), causando regressão recorrente Firebase 15 vs 13. |
| Tests Flutter | `bun run --filter '@raro/mobile' test` | — |
| Native XCTest (RunnerTests) | `bun run --filter '@raro/mobile' test:ios` | Auto-detecta Simulator disponível (iPhone 17/16/15/14/13 fallback) + encadeia pub:get + fix-spm |
| Verify build compila para simulator | `cd apps/mobile && flutter build ios --simulator --no-codesign` | (pre-existe: `SUPPORTED_PLATFORMS = iphoneos` bloqueia release/profile, mas debug funciona) |
| Análise | `bun run --filter '@raro/mobile' analyze` | — |
| Integration tests com timeline parseável (Sessão 2+) | `bun run --filter '@raro/mobile' test:integration -- -d <device-id>` (a criar) — wrapper sobre `flutter test integration_test --machine` | Emite eventos timeline JSON estruturados consumíveis por hook de CI; futuro gate `/verify-slice` pode comparar P95 com baseline e falhar PR se regressão >10%. Combinar com Pigeon `CameraDebugHostApi` (ADR-0016) lendo `AVCaptureDevice.focusPointOfInterest` para asserts deterministas em vez de subjetividade visual |

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
2. Rodar `bun run --filter '@raro/mobile' pub:get` (encadeia recovery)
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
