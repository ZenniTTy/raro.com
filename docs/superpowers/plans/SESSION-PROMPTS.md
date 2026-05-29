# Session Prompts — Copy-paste para iniciar cada sessão

> **Uso**: cole o prompt apropriado no início de uma nova sessão Claude Code. Substitua placeholders entre colchetes `[ASSIM]`. Cada kickoff é **self-contained, rigoroso e exaustivo** — preferência pelo custo do audit uma vez agora vs rework depois.

---

## Como usar este arquivo

1. **Primeira sessão de um Sprint** → use o prompt "**X.0 — Kickoff**" (audit completo: contextualização + mecânico + WebSearch/Context7 em TODOS pontos externos do Sprint + cross-conflict). Espera-se ~20-40min só de audit ANTES de qualquer execução. Custo aceito pra evitar rework.
2. **Sessão seguinte dentro do mesmo Sprint** → use "**X — Sessão de execução**" substituindo `[TASK]` pela letra (A, B, C…) da próxima task. Audit mais leve (Sprint já foi auditado no Kickoff).
3. **Sessão que algo quebrou** → "**Recovery**" no final.
4. **Quando o Sprint terminar** → "**X — Sessão de closure**".

**Princípio**: o Kickoff paga o custo do audit completo upfront. Sessões subsequentes herdam o audit já feito e só validam delta da task específica.

---

## Sprint 1 — Foundation + Walking Skeleton iOS

### 1.0 — Kickoff (primeira sessão Sprint 1)

Cole este prompt EXATO, sem modificar:

```
Sessão Sprint 1 KICKOFF — Foundation + Walking Skeleton iOS.

═══════════════════════════════════════════════════════════════
CONTEXTO PROJETO (carregue antes de qualquer execução)
═══════════════════════════════════════════════════════════════

Projeto RARO: app Flutter (iOS + Android) de câmera pro consumidor final. Desenvolvedor único (não-engenheiro, dev 100% via Claude Code). Stack opinativa em docs/Blueprint.md §2. Após 6 sessões e 144+ commits, branch feat/camera-native-bridge tem 73 commits non-merged. Sprint 0 (sessão anterior) entregou: master plan v2 em ~/.claude/plans/glimmering-dancing-pnueli.md + 3 sprint MDs em docs/superpowers/plans/ + SESSION-PROMPTS.md. Nenhum código de produção tocado.

Estratégia 3-Sprint: Sprint 1 (walking skeleton + cleanup) → Sprint 2 (backend real iOS) → Sprint 3 (Android parity + TestFlight + cliente). Sprint 1 entrega: cleanup memórias/CLAUDE.md/docs, branch camera merged em develop, 12 telas Flutter navegáveis no iPhone 12, Riverpod 3 providers swap-able (implementação hard-coded mas signature real pra Sprint 2 substituir sem mudar UI). FREE Apple ID (Xcode rebuild 7-day refresh). NÃO toca Android. NÃO paga $99.

PRINCÍPIO Karpathy #4 (Goal-Driven Execution): 1 sessão = 1 entregável fechado declarado upfront. Mid-flight detours viram backlog de nova sessão.

═══════════════════════════════════════════════════════════════
FASE 1 — Contextualização (read-only, ~5 min)
═══════════════════════════════════════════════════════════════

1. Rode /prime (re-injeta Blueprint + INDEX + invariants locked).
2. Leia INTEIRO, na ordem:
   a) docs/Blueprint.md — atenção §2 (stack pinada), §5 (telas), §11 (roadmap 3-sprint)
   b) CLAUDE.md (manual autoritativo, todas seções)
   c) docs/superpowers/plans/sprint-1-foundation-walking-skeleton.md (executável desta sessão)
   d) docs/superpowers/plans/sprint-2-backend-logic-ios.md (validar consistência cross-sprint)
   e) docs/superpowers/plans/sprint-3-android-parity-testflight-client.md (validar consistência cross-sprint)
   f) docs/sessions/0001-INDEX.md (último estado)
   g) docs/sessions/0006-camera-task-19-focus-perf.md + docs/sessions/0007-sprint0-* se existir (estado mais recente)
3. Liste em ≤200 palavras: estado entrada ESPERADO pelo Sprint 1 MD (pre-flight checklist) vs estado REAL observado agora. Se há gap NOMEIE explicitamente (e.g., "pre-flight pede iPhone 12 conectado, não foi confirmado").

═══════════════════════════════════════════════════════════════
FASE 2 — Audit mecânico (1 agente Explore, ~5 min)
═══════════════════════════════════════════════════════════════

4. Despache 1 agente Explore com este prompt EXATO:

"Audit mecânico do docs/superpowers/plans/sprint-1-foundation-walking-skeleton.md. Para cada Task (A, B, C, D, E, F, G, H), validar:

(a) FILE PATHS: todos paths citados existem (apps/mobile/lib/features/*, apps/mobile/pubspec.yaml, CLAUDE.md, docs/Blueprint.md, etc.) OU são paths válidos pra criação nova (sem typo, sem diretório-pai inexistente).

(b) SHELL COMMANDS: sintáticos pra macOS zsh + bun + flutter. Especificamente validar:
    - bun --filter @raro/mobile run dev:ios -- -d <udid>
    - bun --filter @raro/mobile run codegen
    - flutter analyze, flutter test, flutter build ios
    - xcrun xctrace list devices
    - cp -r, rm, git status, git commit, git merge --no-ff, git push, git branch -d

(c) PLACEHOLDERS: nenhuma task contém TBD, TODO, 'implement later', 'similar to Task X' sem detalhe, 'add appropriate', 'fill in', '...'.

(d) REFERÊNCIAS:
    - Specs: docs/superpowers/specs/2026-05-28-camera-task-19-closure-design.md, docs/superpowers/specs/2026-05-26-camera-native-bridge-design.md
    - ADRs: docs/decisions/0010-dual-subscription-plans.md, docs/decisions/0015-camera-native-bridge-strategy.md
    - Memórias: listar quais memórias o MD cita E confirmar existência em /Users/eduardorodrigues/.claude/projects/-Users-eduardorodrigues-Documents-Projetos-Clientes-vitor-workana-app-raro/memory/

(e) CROSS-MD CONFLITO: ler também sprint-2-backend-logic-ios.md e sprint-3-android-parity-testflight-client.md. Há decisão técnica em Sprint 1 que será CONTRADITA por Sprint 2 ou 3? (e.g., Sprint 1 define provider signature que Sprint 2 não vai conseguir implementar; Sprint 1 cria estrutura que Sprint 3 quebra).

(f) GOALS BINÁRIOS: cada G1-G6 do Sprint 1 é mensurável objetivamente (não 'app funciona melhor' mas 'app abre splash, navega pra onboarding 1, exibe widget X')?

(g) DONE CRITERIA POR TASK: cada Task A-H tem DONE criteria observável (não interpretativo)?

(h) CONSISTÊNCIA TIPO: signatures/types/method names citados em Task posteriores (E, F, G) batem com o que foi definido em Tasks anteriores (D)?

Reporte em ≤500 palavras estruturado: PASS por critério (a-h) ou holes específicos (cite arquivo + linha + descrição do hole)."

═══════════════════════════════════════════════════════════════
FASE 3 — Audit best-practices 2026 via WebSearch + Context7 (1 agente Explore, ~15-20 min)
═══════════════════════════════════════════════════════════════

5. Despache 1 agente Explore com este prompt EXATO:

"Audit best-practices 2026 do Sprint 1 MD. Para cada item EXTERNO abaixo (dependência, API, padrão), valide via Context7 (preferência) OU WebSearch focado em maio 2026 best practices. Reporte: VERSÃO CURRENT? BREAKING CHANGES desde a versão pinada? RECOMMENDED ALTERNATIVE em 2026? Cite URLs.

Lista exaustiva de items pra validar (NÃO ignore nenhum):

1. **Flutter SDK 3.44+** ainda current em maio 2026? Há 3.45 ou 3.46 com breaking changes que afetariam walking skeleton (widgets, navigator, Material 3)?

2. **Riverpod 3 (flutter_riverpod ^3.3.1) com codegen (@riverpod annotation + part 'file.g.dart' + riverpod_annotation ^4.0.2 + riverpod_generator)** ainda canonical em 2026? Riverpod 4 foi lançado com breaking? Pattern `@riverpod class Foo extends _$Foo { @override Foo build() {} }` ainda recomendado?

3. **go_router ^17.2.3** ainda current ou há 18.x com migration obrigatória? Pattern com GoRouter routes + builder ainda recomendado?

4. **freezed_annotation ^3.1.0 + freezed (dev) ^3.x** ainda canonical em 2026 pra data classes / unions? Pattern @freezed class X with _$X ainda atual?

5. **permission_handler ^12.0.1** ainda current? Memória raro-pattern-permission-handler-ios-podfile-macros ainda aplicável (Podfile macros GCC_PREPROCESSOR_DEFINITIONS PERMISSION_CAMERA=1)?

6. **shared_preferences ^2.5.5** ainda current ou foi superseded por outra API (e.g., flutter_secure_storage padrão pra non-sensitive setting)?

7. **path_provider ^2.1.5** ainda current?

8. **video_player package (Flutter SDK)** ainda recomendado em 2026? Memória raro-pattern-flutter-video-player-disposal sobre dispose rigoroso ainda aplica?

9. **share_plus ^13.1.0** ainda current?

10. **device_info_plus ^13.1.0** ainda current?

11. **intl ^0.20.2** ainda current? Em Sprint 1 NÃO usado mas listed em pubspec — verificar se é dep ativa ou pode mover pra deps Phase 2.

12. **logger ^2.7.0** ainda canonical em 2026 pra logging Flutter?

13. **alchemist ^0.14.0** ainda current pra golden tests Flutter 3.44+?

14. **mocktail ^1.0.5** ainda canonical em 2026 vs mockito ou nova alternativa?

15. **Pigeon ^26.3.2** ainda current (Sprint 1 NÃO modifica Pigeon contracts mas Sprint 2/3 modificam — validar pra cross-sprint)?

16. **Bun como package manager pra monorepo Flutter** ainda padrão moderno em 2026 ou voltou pra npm/yarn/pnpm? Pattern `bun --filter @raro/mobile run X` ainda válido?

17. **lefthook** pre-commit ainda canonical vs husky/pre-commit (Python) em 2026?

18. **commitlint Conventional Commits 1.0.0** ainda padrão indústria 2026?

19. **biome** (ao invés de prettier/eslint) — config atual ainda canonical?

20. **iOS free Apple ID + Xcode 7-day cert refresh** workflow ainda funciona pra debug build em iOS 17/18/19 sem Apple Dev Program $99? Memória raro-pattern-flutter-debug-vs-release-on-device ainda válida?

21. **iOS 26 (se aplicável ao iPhone 12)** tem mudanças que quebrariam algo do walking skeleton (debug mode restriction, sandbox changes)? Memória relacionada existe?

22. **Flutter wireless debug iPhone** ainda funcional em maio 2026 ou Apple bloqueou (ver Flutter issues #135380, #119493)?

23. **CocoaPods → SPM migration ADR-0014** ainda recomendado em 2026 ou Apple/Flutter mudaram direção? Memória raro-pattern-flutter-spm-ios-13-hardcoded ainda relevante (Flutter 3.44 darwin.dart:71 issue)?

24. **Method Channels via Pigeon** vs alternative (e.g., FFI direto, Dart-Native interop nova) — Pigeon ainda canonical em 2026?

25. **Padrão feature folder layout** (lib/features/<feature>/{application,data,domain,presentation}) ainda canonical em 2026 pra Flutter+Riverpod ou comunidade migrou pra outro (e.g., flat lib/, ou DDD strict)?

26. **iPhone 12 hardware**: ainda recebe iOS updates em 2026? Memória raro-pattern-ios-avcapture-iphone12-dualwide-zoom-mapping ainda válida com firmware atual?

Reporte em ≤1200 palavras estruturado por item (1-26):
- Item: [nome]
- Status: CURRENT / DEPRECATED / SUPERSEDED
- Versão atual maio 2026: [vX.Y.Z]
- Breaking changes desde versão pinada no MD: [sim/não + detalhe]
- Recomendação: KEEP / UPGRADE / REPLACE com [alternativa]
- Source: [URL]

Para itens 20-26 (workflow + memórias), reporte: AINDA APLICÁVEL / OBSOLETO + evidência."

═══════════════════════════════════════════════════════════════
FASE 4 — Consolidação + Gate (você decide)
═══════════════════════════════════════════════════════════════

6. Consolide reports FASE 2 + FASE 3 num único relatório estruturado. Categorize cada finding:
   - **BLOQUEANTE**: file path inexistente, comando quebrado, dep DEPRECATED com migration obrigatória, contradição cross-MD, memória obsoleta que invalida task, breaking change desde versão pinada.
   - **WARNING**: API mudou mas é compatível, recomendação evoluiu mas atual ainda funciona, dep tem nova major mas não obrigatória.
   - **INFORMATIVE**: contexto histórico, opção alternativa.

7. Reporte pra mim em formato:
   - "BLOQUEANTES (X):" lista
   - "WARNINGS (Y):" lista
   - "INFORMATIVE (Z):" lista
   - "DECISÃO PROPOSTA: [executar | corrigir MD primeiro | escalar dúvida]"

8. AGUARDE minha confirmação explícita ANTES de FASE 5.
   - Se 0 BLOQUEANTES: posso aprovar "executar"
   - Se ≥1 BLOQUEANTE: corrigir MD primeiro com commit `docs(docs): sprint 1 md audit fixes` (lefthook GREEN, sem --no-verify)
   - Se dúvida estratégica (e.g., Riverpod 3 deprecated, refatorar todo Sprint?): escalar pra mim, eu decido

═══════════════════════════════════════════════════════════════
FASE 5 — Execução (APENAS após gate clean)
═══════════════════════════════════════════════════════════════

9. Execute Sprint 1 Task A inteira (A1 backup memórias → A2 auditar cada memória → A3 deletar critério-based → A4 merges → A5 CLAUDE.md §8 align → A6 commit 1 `chore(cleanup): align claude.md §8 hooks`).

10. Para cada step destrutivo (rm, git push, git branch -d, git checkout .), confirme comigo ANTES de executar. Mostre o comando proposto, espere meu OK.

11. Lefthook GREEN obrigatório em commits. Se falhar: pare, diagnose causa-raiz, NÃO use --no-verify.

═══════════════════════════════════════════════════════════════
FASE 6 — Closure
═══════════════════════════════════════════════════════════════

12. Rode /session-end:
    - registra entrada em docs/sessions/0008-sprint1-task-a-cleanup.md
    - define próximo objetivo "Sprint 1 Task B (workflow refactor)"
    - commit `chore(session): close 0008`

13. Reporte final em ≤200 palavras: tasks done, commits criados, blueprint §11 checkbox atualizado se aplicável, próxima sessão = "Sprint 1 Task B".

═══════════════════════════════════════════════════════════════
GUARDRAILS VIGENTES (não-negociáveis)
═══════════════════════════════════════════════════════════════

- "FORA DE ESCOPO" pra qualquer drift mid-task. Backlog vira nota.
- 1 sessão = Task A fechado. NÃO avance pra Task B sem nova sessão.
- Sem --no-verify em commits.
- Confirme destrutivos.
- Workflows multi-agent só FASE 2 + FASE 3 audits. Sem outros workflows adversariais.
- Se em qualquer momento sentir necessidade de "vamos auditar de novo", SINAL pra parar a sessão e abrir spec dedicada — não interromper Task A.
```

### 1 — Sessão de execução (Task subsequente, após Kickoff feito)

Cole substituindo `[TASK]` pela letra (B, C, D, E, F, G, H):

```
Sessão Sprint 1 — Task [TASK].

CONTEXTO: Sprint 1 já passou pelo Kickoff completo (audit FASE 1-4) em sessão anterior. Esta sessão executa apenas Task [TASK].

Setup (~3 min):
1. /prime
2. git log --oneline -10 + git status → confirme commits Tasks anteriores (A até [TASK-1]) presentes, branch limpa.
3. Leia docs/superpowers/plans/sprint-1-foundation-walking-skeleton.md APENAS seção "Task [TASK]" + "Riscos conhecidos" + "Out of scope".
4. Mini-audit (sem WebSearch — herda do Kickoff): file paths citados em Task [TASK] existem? Memórias citadas existem? DONE criteria observável? Cite holes em ≤100 palavras ou "Mini-audit clean".
5. Se holes mecânicos: corrigir MD primeiro com commit `docs(docs): sprint 1 task [TASK] md fixes`.

Execução:
6. Execute Task [TASK] step-by-step conforme MD. Confirme destrutivos comigo antes.
7. flutter analyze + flutter test GREEN antes de commit. Sem --no-verify.

Closure:
8. /session-end → entrada em docs/sessions/, próximo objetivo "Sprint 1 Task [PRÓXIMA]".
9. Reporte: tasks done, commits, blueprint § atualizado.

Guardrails idem Kickoff. 1 sessão = Task [TASK] fechado, não avance.
```

### 1 — Sessão de closure (Task H smoke test final)

```
Sessão de closure Sprint 1.

1. /prime
2. Verifique Blueprint §11 — todos checkboxes Sprint 1 Tasks A-G ✅ (exceto Task H que é esta sessão)? Se aberto, nomeie.
3. Smoke test fim-a-fim manual no iPhone 12: splash (1.5s) → onboarding 1 → "Próximo" → onboarding 2 → "Próximo" → permissions → "Permitir" → camera UI shell → tap REC (timer roda) → tap REC (para) → tap settings → mudar quality + replay duration → voltar → tap gallery → tap thumbnail → preview play/pause → voltar → camera com popup subscription (mockado pra não-subscribed) → tap CTA → paywall → selecionar plano → checkout → confirm → camera volta → trial countdown visível em Settings → About.
4. Sem crash. Sem regressão camera nativa (focus, lens 0.5x/1x, format).
5. Marcar Blueprint §11 Sprint 1 todos ✅.
6. Criar docs/sessions/<NNNN>-sprint1-closure.md + atualizar INDEX.
7. Commit final: `docs(blueprint): mark sprint 1 telas + cleanup done`.

Próxima sessão: Sprint 2 Kickoff (apenas se Sprint 1 todos ✅ E você confirmar disponibilidade pra backend logic real).
```

---

## Sprint 2 — Backend/Lógica Real iOS

### 2.0 — Kickoff (primeira sessão Sprint 2)

Cole este prompt EXATO:

```
Sessão Sprint 2 KICKOFF — Backend/Lógica Real iOS.

═══════════════════════════════════════════════════════════════
CONTEXTO PROJETO
═══════════════════════════════════════════════════════════════

Projeto RARO já em Sprint 2 (Sprint 1 closed). Estado entrada: develop tem merge feat/camera-native-bridge + walking skeleton 12 telas com Riverpod providers signature real mas implementação hard-coded. Sprint 2 substitui implementações mock por REAIS, mantendo UI intacta. Free Apple ID ainda em uso (rebuild 7-day refresh). NÃO toca Android. NÃO paga $99 ainda.

Sprint 2 entrega:
- Recording real (MP4 H.264/H.265 → vault path_provider)
- Replay buffer 15s/30s native (AVAssetWriter circular iOS)
- Wake word "Raro" iOS (SFSpeechRecognizer + restart loop)
- Volume button iOS (KVO AVAudioSession.outputVolume)
- RevenueCat sandbox paywall (workaround sem $99 Apple Dev)
- Share via share_plus
- Vault encryption + gallery filesystem real

PRINCÍPIO: NÃO mexer em UI Sprint 1 a menos que swap exija (e.g., paywall pode precisar update se RevenueCat retornar metadata diferente).

═══════════════════════════════════════════════════════════════
FASE 1 — Contextualização (~5 min)
═══════════════════════════════════════════════════════════════

1. Rode /prime
2. Pre-flight: confirme comigo
   - Sprint 1 closed (Blueprint §11 todos ✅)? Cite linha do Blueprint.
   - Apple Sandbox Tester account criada em App Store Connect? (necessária Task E paywall)
   - iPhone 12 conectado (USB ou wireless pareado)?
3. Leia INTEIRO, na ordem:
   a) docs/Blueprint.md §2 (stack) + §11 (roadmap sprint 2)
   b) CLAUDE.md (manual atualizado pós-Sprint 1)
   c) docs/superpowers/plans/sprint-2-backend-logic-ios.md (executável)
   d) docs/superpowers/plans/sprint-3-android-parity-testflight-client.md (consistência cross-sprint)
   e) docs/sessions/0001-INDEX.md + último session log Sprint 1
   f) docs/decisions/0003-replay-buffer-native.md (ADR replay)
   g) docs/decisions/0010-dual-subscription-plans.md (ADR paywall)
   h) docs/decisions/0011-volume-control-not-bluetooth.md (ADR volume)
   i) docs/decisions/0015-camera-native-bridge-strategy.md (ADR camera bridge)
4. Liste em ≤200 palavras: estado entrada esperado vs real. Gap explícito.

═══════════════════════════════════════════════════════════════
FASE 2 — Audit mecânico (1 agente Explore, ~5 min)
═══════════════════════════════════════════════════════════════

5. Despache agente Explore com este prompt EXATO:

"Audit mecânico do docs/superpowers/plans/sprint-2-backend-logic-ios.md. Para cada Task (A, B, C, D, E, F), validar:

(a) FILE PATHS: paths Swift (ios/Runner/Native/Camera/, ios/Runner/Native/Voice/, ios/Runner/Native/Volume/, ios/RunnerTests/), Dart (lib/features/camera/data/, lib/features/voice/, lib/features/volume/, lib/features/paywall/data/, lib/core/billing/), Pigeon (apps/mobile/pigeons/camera_api.dart, voice_api.dart, volume_api.dart) existem ou são paths válidos pra criação.

(b) PIGEON CONTRACTS: methods propostos sintáticos pra Pigeon ^26.3.2 (HostApi, FlutterApi, primitive types Dart-Swift mapping, class declarations).

(c) SWIFT APIS citadas em maio 2026 ainda existem:
    - AVCaptureMovieFileOutput, AVAssetWriter, AVAudioSession, SFSpeechRecognizer, SFSpeechAudioBufferRecognitionRequest
    - AVAssetWriter.expectsMediaDataInRealTime, AVAudioSession.outputVolume KVO
    - MPVolumeView.setVolume (private API still works iOS 17/18?)
    - AVCaptureDevice.lockForConfiguration, focusPointOfInterest

(d) DART APIS: Riverpod 3 @riverpod patterns (build, ref.read, ref.invalidate, family), Future/Stream async usage, dart:io File operations, path_provider.getApplicationDocumentsDirectory.

(e) PLACEHOLDERS: nenhuma task contém TBD, TODO, etc.

(f) REFERÊNCIAS válidas:
    - ADRs 0003, 0010, 0011, 0015 existem
    - Memórias: raro-pattern-ios-wake-word-no-native-api, raro-pattern-revenuecat-trial-app-store-connect, raro-pattern-revenuecat-error-handling, raro-pattern-ios-volume-button-kvo-app-store-review, raro-pattern-ios-cvpixelbufferpool, raro-pattern-crashlytics-3-handlers — todos em ~/.claude/projects/.../memory/

(g) CROSS-MD CONFLITO: validar contra sprint-1 (mesmas signatures de providers swap?) e sprint-3 (Android terá API equivalente Dart-side?). Se Sprint 1 provider X tem signature Y, Sprint 2 swap precisa retornar Y. Se Sprint 3 Android implementa mesma feature, Pigeon contract precisa platform-agnostic.

(h) GOALS BINÁRIOS G1-G7 mensuráveis?

(i) DONE CRITERIA por Task observável?

(j) CONSISTÊNCIA: Pigeon contracts Sprint 2 (camera_api, voice_api, volume_api) serão usados PARA AMBAS iOS (esta sprint) E ANDROID (Sprint 3) — verificar Pigeon contract é platform-agnostic (não usa types iOS-specific).

Reporte em ≤500 palavras: PASS (a-j) ou holes específicos."

═══════════════════════════════════════════════════════════════
FASE 3 — Audit best-practices 2026 via WebSearch + Context7 (1 agente Explore, ~20-25 min)
═══════════════════════════════════════════════════════════════

6. Despache agente Explore com este prompt EXATO:

"Audit best-practices 2026 do Sprint 2 MD. Para cada item EXTERNO (dependência, API nativa, serviço pago), validar via Context7 (preferência) OU WebSearch focado em maio 2026. Reporte: STATUS, BREAKING CHANGES desde versão MD, RECOMMENDED. Cite URLs.

Lista exaustiva (NÃO ignore nenhum):

# Frameworks + SDKs

1. **purchases_flutter ^10.1.1 (RevenueCat)**: ainda current em maio 2026? RevenueCat v11/v12 lançado com breaking? PurchasesErrorHelper.getErrorCode pattern (memória raro-pattern-revenuecat-error-handling) ainda canonical?

2. **share_plus ^13.1.0**: ainda current? Share.shareXFiles + XFile pattern ainda válido em 2026?

3. **path_provider ^2.1.5**: ainda current? getApplicationDocumentsDirectory ainda canonical pra vault?

4. **Pigeon ^26.3.2**: ainda current ou tem 27+? HostApi/FlutterApi patterns ainda canonical?

5. **Riverpod 3 @riverpod com Future/Stream**: pattern `Future<T> build()` retornando dados async ainda canonical em 2026? `ref.invalidate(provider)` pra force-refresh ainda works?

# iOS native APIs (CRÍTICO)

6. **AVCaptureMovieFileOutput** pra recording de vídeo iOS: ainda canonical em iOS 17/18/19/20 ou Apple deprecou em favor de novo (e.g., AVAssetWriter direto, ou AVCaptureVideoDataOutput + custom muxer)? Memória raro-pattern-ios-avcapture-iphone12-dualwide-zoom-mapping ainda válida?

7. **AVAssetWriter pra circular replay buffer**: ainda canonical em iOS 17+ ou deprecou pra alternative? Pattern de 2 writers rotativos (descrito no Sprint 2 MD Task B) ainda recomendado?

8. **CVPixelBufferPool**: ainda canonical pra reciclar IOSurface em iOS 2026? Memória raro-pattern-ios-cvpixelbufferpool ainda válida (não usar CVPixelBufferCreate direto em hot path)?

9. **SFSpeechRecognizer** pt-BR em iOS 17/18/19+ ainda tem:
   - quota 1000 req/h?
   - limite 1 min por sessão?
   - SEM wake word API custom (memória raro-pattern-ios-wake-word-no-native-api)?
   - SFSpeechAudioBufferRecognitionRequest pattern ainda canonical?
   - Apple introduziu nova API (e.g., on-device speech, ML.framework speech)?

10. **AVAudioSession.outputVolume KVO** (memória raro-pattern-ios-volume-button-kvo-app-store-review):
    - ainda funcional em iOS 17/18/19?
    - AVAudioSessionCategoryAmbient ainda evita audio ducking?
    - MPVolumeView.setVolume ainda funciona (private API que Apple às vezes bloqueia)?
    - App Store review aceita uso pra captura mídia em 2026?

11. **AVCaptureDevice configuração** (lockForConfiguration, focusPointOfInterest, isSmoothAutoFocusEnabled): patterns iOS 17+ ainda canonical? Memórias raro-pattern-avfoundation-smoothautofocus-cinematic-ramp + raro-pattern-avfoundation-kvo-permanent-vs-per-tap ainda válidas?

12. **CALayer + CATransaction** pra focus ring nativo: patterns descritos em sessão 0006 (memória raro-pattern-cashapelayer-catransaction-disables-explicit-animations) ainda aplicáveis iOS 17+?

13. **CMSampleBuffer + AVCaptureVideoDataOutput** delegate pra append frame em buffer: pattern canonical 2026 ou superseded por ScreenCaptureKit/equivalente?

# Pattern de Dart-iOS bridge

14. **Pigeon @HostApi** vs **method_channel direto**: Pigeon ainda recomendado em 2026 vs FFI ou nova Dart-native interop? Para o nosso caso (camera, voice, volume), Pigeon ainda fits?

15. **EventChannel** (não usado Sprint 2 mas considerar): vs Stream sobre FlutterApi callback — Sprint 2 usa Flutter callback API pra wake word events; ainda canonical?

# Serviços externos (CRÍTICO — política muda)

16. **RevenueCat sandbox SEM Apple Dev Program $99**: workaround Task E2 (config produtos só em RevenueCat Web dashboard, sem criar em App Store Connect) AINDA FUNCIONA em maio 2026? RevenueCat mudou política? Apple mudou sandbox?

17. **App Store Connect Sandbox Tester accounts**: ainda gratuito de criar sem Apple Dev pago? Processo do app's Settings → App Store → sign out + sandbox sign-in ainda canonical iOS 17+?

18. **RevenueCat StoreKit 2** (vs StoreKit 1 deprecado WWDC 2024 — memória raro-pattern-revenuecat-trial-app-store-connect): purchases_flutter ^10.1.1 usa StoreKit 2 ou ainda 1? Migration obrigatória em 2026?

# Workflow

19. **flutter run + hot reload em iPhone 12 com free Apple ID + Xcode 7-day refresh**: ainda funcional iOS 17/18/19 em maio 2026? Memória raro-pattern-flutter-debug-vs-release-on-device ainda válida?

20. **integration_test --machine flag** (Sprint 2 NÃO usa, Sprint 3 usa — validar pra cross-sprint): ainda canonical pra parsable timeline events Flutter 3.44+?

21. **flutter test em XCTest native (RunnerTests)**: pattern bun run test:ios + run-ios-native-tests.sh ainda recomendado vs xcodebuild direto em 2026?

# Performance + Memory

22. **AVAssetWriter memory pressure iPhone 12 (4GB RAM)** em buffer 30s @ 1080p30: estimativa Sprint 2 (~150MB raw) ainda razoável? Apple/Flutter mudaram low-memory warnings handling iOS 18+?

23. **MetricKit / XCTClockMetric** (não usar conforme memória feedback_infra_observability_before_known_fix_is_inversion, mas considerar Sprint 3): ainda canonical pra perf measurement 2026?

# Privacy + Permissions

24. **Info.plist permissions** (NSCameraUsageDescription, NSMicrophoneUsageDescription, NSSpeechRecognitionUsageDescription): textos atualizados pra App Store guidelines 2026?

25. **permission_handler iOS Podfile macros** (memória raro-pattern-permission-handler-ios-podfile-macros): GCC_PREPROCESSOR_DEFINITIONS PERMISSION_CAMERA=1 PERMISSION_MICROPHONE=1 PERMISSION_SPEECH_RECOGNIZER=1 ainda obrigatório em 2026 ou plugin auto-detecta?

26. **App Tracking Transparency (ATT)**: Sprint 2 não trackeia mas se Crashlytics/Analytics implementação Sprint 3 precisar — verificar política Apple atual.

Reporte em ≤1500 palavras estruturado por item (1-26):
- Item: [nome]
- Status: CURRENT / DEPRECATED / SUPERSEDED  
- Versão atual maio 2026: [vX.Y.Z]
- Breaking changes desde versão MD: [sim/não + detalhe]
- Recomendação: KEEP / UPGRADE / REPLACE com [alternativa]
- Source: [URL Context7 ou WebSearch]

Para itens 11-12, 19, 24-25 (memórias): AINDA APLICÁVEL / OBSOLETO / PRECISA UPDATE + evidência."

═══════════════════════════════════════════════════════════════
FASE 4 — Consolidação + Gate
═══════════════════════════════════════════════════════════════

7. Consolide FASE 2 + FASE 3 em report único. Categorize: BLOQUEANTE / WARNING / INFORMATIVE.

8. Reporte:
   - "BLOQUEANTES (X):" lista
   - "WARNINGS (Y):" lista  
   - "INFORMATIVE (Z):" lista
   - "DECISÃO PROPOSTA: [executar | corrigir MD | escalar]"

9. AGUARDE confirmação minha. Se ≥1 BLOQUEANTE: corrigir MD com commit `docs(docs): sprint 2 md audit fixes` antes de prosseguir.

═══════════════════════════════════════════════════════════════
FASE 5 — Execução
═══════════════════════════════════════════════════════════════

10. Execute Sprint 2 Task A inteira (A1 Pigeon recording API → A2 RecordingPipeline.swift + XCTest → A3 vault_service Dart + provider swap → A4 wire recording → vault → gallery).

11. Para cada step destrutivo, confirme antes. XCTest + flutter analyze + flutter test GREEN antes de cada commit. Sem --no-verify.

═══════════════════════════════════════════════════════════════
FASE 6 — Closure
═══════════════════════════════════════════════════════════════

12. /session-end → docs/sessions/<NNNN>-sprint2-task-a.md + próximo "Sprint 2 Task B".

13. Reporte final ≤200 palavras.

═══════════════════════════════════════════════════════════════
GUARDRAILS
═══════════════════════════════════════════════════════════════

- "FORA DE ESCOPO" pra drift
- 1 sessão = Task A fechado
- Sem --no-verify
- Confirme destrutivos
- Workflows multi-agent só FASE 2 + FASE 3
```

### 2 — Sessão de execução (Task subsequente)

Cole substituindo `[TASK]` (B, C, D, E, F):

```
Sessão Sprint 2 — Task [TASK].

CONTEXTO: Sprint 2 Kickoff feito em sessão anterior (audit FASE 1-4 completo). Esta sessão executa apenas Task [TASK].

Setup (~3 min):
1. /prime
2. git log + git status → confirme Tasks anteriores (A até [TASK-1]) commitadas, branch limpa.
3. Leia sprint-2-backend-logic-ios.md seção "Task [TASK]" + memórias citadas em "Memória relevante" da Task.
4. Pre-flight Task-specific:
   - Task B (replay buffer): iPhone 12 conectado pra smoke test 30s buffer?
   - Task C (wake word): mic permission grantada no iPhone? SFSpeechRecognizer authorization OK?
   - Task D (volume): AVAudioSession testável em foreground?
   - Task E (RevenueCat): Apple Sandbox Tester signed in no iPhone? RevenueCat dashboard config com Android API key adiada pra Sprint 3 OK?
   - Task F (share + polish): vault tem ≥1 vídeo gravado pra share?
5. Mini-audit (sem WebSearch — herda do Kickoff): file paths Task [TASK] existem? Pigeon contracts coerentes? Cite holes ≤100 palavras ou "clean".

Execução:
6. Execute step-by-step. Confirme destrutivos.
7. XCTest + integration_test smoke no iPhone 12 antes de commit final. GREEN.

Closure:
8. /session-end → próximo "Sprint 2 Task [PRÓXIMA]".
9. Reporte tasks done, commits, smoke result.

Guardrails idem Kickoff.
```

### 2 — Sessão de closure

```
Sessão de closure Sprint 2.

1. /prime
2. Smoke test fim-a-fim no iPhone 12:
   - Tap REC → grava 10s → tap REC → MP4 aparece em Gallery → tap → reproduz
   - Replay buffer ligado → após 30s tap "Salvar replay" → MP4 30s em Gallery
   - Dizer "Raro" → REC inicia (< 500ms detect → start)
   - Pressionar volume up → REC inicia → volume down → REC para
   - Paywall → tap plano → Subscribe sandbox → trial countdown 30d rodando
   - Share via preview → system sheet abre com MP4
3. Marcar Blueprint §11 Sprint 2 ✅.
4. docs/sessions/<NNNN>-sprint2-closure.md + INDEX update.
5. Commit final: `docs(blueprint): mark sprint 2 backend logic done`.

Próxima sessão: Sprint 3 Kickoff (apenas com confirmação de pagar Apple Dev $99 + Google Play $25).
```

---

## Sprint 3 — Android Parity + TestFlight + Cliente

### 3.0 — Kickoff (primeira sessão Sprint 3)

Cole este prompt EXATO:

```
Sessão Sprint 3 KICKOFF — Android Parity + TestFlight + Cliente.

═══════════════════════════════════════════════════════════════
CONTEXTO PROJETO
═══════════════════════════════════════════════════════════════

Sprint 1 + 2 closed. iOS app funcionalmente completo no iPhone 12 (free Apple ID). Sprint 3 entrega paridade Android + pagamento Apple Dev Program $99 + Google Play Console $25 + TestFlight build + Google Play Internal Testing + cliente convidado pra testar AMBAS plataformas. Esta é a entrega final do plano 3-Sprint.

Sprint 3 entrega:
- Android native bridges paridade (CameraX 1.6.1 + MediaCodec + SpeechRecognizer + AudioManager + BillingClient via RevenueCat)
- $99 Apple Dev Program pago + bundle ID config + provisioning + in-app products
- $25 Google Play Console pago + app registered + Internal Testing track
- i18n PT/ES/EN (ARB + intl + synthetic-package: false)
- Modais P12 Xiaomi + P13 Bluetooth + P14 Lock mode
- Crashlytics + Analytics events conforme ADR-0013
- Golden tests + integration_test E2E via Pigeon CameraDebugHostApi (ADR-0016)
- TestFlight build + Google Play Internal Testing + cliente convidado em ambas

═══════════════════════════════════════════════════════════════
FASE 1 — Contextualização (~5 min)
═══════════════════════════════════════════════════════════════

1. Rode /prime
2. Pre-flight CRÍTICO: pergunte e AGUARDE confirmação minha:
   - Sprint 2 closed (Blueprint §11 todos ✅)? Cite linha.
   - Apple Developer Program $99 PAGO? (recibo ou confirmação?)
   - Google Play Console $25 PAGO? (recibo ou confirmação?)
   - Device Android disponível (preferência Xiaomi MIUI/HyperOS + Samsung secundário)? Conectado via USB com USB debugging ativo?
   - Bundle ID `com.rarocamera` registrado em App Store Connect?
   - App `com.rarocamera` registrado em Google Play Console?
   - Privacy policy URL preparada (App Store + Play Store exigem)?
   - App icon 1024x1024 preparado?
   - Email do cliente pra invitar pronto?
3. Se QUALQUER pre-flight = não, PARE. Reporte gap, eu decido se prosseguimos limitado ou adiamos.

4. Leia INTEIRO:
   a) docs/Blueprint.md §2 (stack) + §11 (roadmap sprint 3)
   b) CLAUDE.md
   c) docs/superpowers/plans/sprint-3-android-parity-testflight-client.md (executável)
   d) docs/superpowers/plans/sprint-1 + sprint-2 (consistência cross-sprint)
   e) docs/sessions/0001-INDEX.md + último session log Sprint 2
   f) ADRs: 0002 (camera bridge), 0003 (replay buffer), 0010 (paywall), 0011 (volume), 0012 (xiaomi onboarding), 0015 (camera bridge strategy), 0016 (e2e harness hybrid)

5. Liste em ≤200 palavras: estado entrada esperado vs real.

═══════════════════════════════════════════════════════════════
FASE 2 — Audit mecânico (1 agente Explore, ~5 min)
═══════════════════════════════════════════════════════════════

6. Despache agente Explore com este prompt EXATO:

"Audit mecânico do docs/superpowers/plans/sprint-3-android-parity-testflight-client.md. Para cada Task (A-L), validar:

(a) FILE PATHS: paths Kotlin (apps/mobile/android/app/src/main/kotlin/com/rarocamera/), Gradle (apps/mobile/android/app/build.gradle.kts), Manifest (apps/mobile/android/app/src/main/AndroidManifest.xml), androidTest, l10n (apps/mobile/lib/l10n/, apps/mobile/l10n.yaml), goldens (apps/mobile/test/goldens/), integration_test (apps/mobile/integration_test/) — existem ou são paths válidos pra criação?

(b) SHELL COMMANDS: sintáticos pra macOS zsh + bun + flutter + adb (Android Debug Bridge) + xcrun. Especificamente: bun --filter @raro/mobile run dev:android, flutter build appbundle --release, flutter build ipa --release, xcrun altool --upload-app, adb logcat.

(c) KOTLIN APIs (validar contra CameraX 1.6.1 + Android API 24+): ProcessCameraProvider.getInstance, bindToLifecycle, Preview/VideoCapture/ImageAnalysis usage, FocusMeteringAction, FileOutputOptions, AudioManager.STREAM_MUSIC, SpeechRecognizer.createSpeechRecognizer, RecognitionListener, MediaCodec.createEncoderByType.

(d) PIGEON CONTRACTS Sprint 3 herdam Sprint 2 (camera_api, voice_api, volume_api): consistência verified? CameraDebugHostApi (ADR-0016) novo Pigeon contract spec'd?

(e) PLACEHOLDERS: nenhum TBD, TODO, etc.

(f) REFERÊNCIAS:
    - ADRs 0002, 0003, 0010, 0011, 0012, 0013, 0015, 0016 existem em docs/decisions/
    - Memórias: raro-pattern-android-camerax-ultra-wide-unreliable, raro-pattern-android-mediacodec-buffer-management, raro-pattern-android-13-media-permissions, raro-pattern-xiaomi-miui-hyperos-detection, raro-pattern-flutter-i18n-synthetic-package-false, raro-pattern-flutter-video-player-disposal, raro-pattern-crashlytics-3-handlers — todos em ~/.claude/projects/.../memory/

(g) CROSS-MD CONFLITO: Pigeon contracts Sprint 3 implementação Android usa MESMAS API surfaces de Sprint 2 implementação iOS? (e.g., enableReplayBuffer(seconds) tem mesma signature, mesmo retorno).

(h) GOALS BINÁRIOS G1-G10 mensuráveis?

(i) DONE CRITERIA por Task observável?

(j) PLATFORM-AGNOSTIC: Pigeon contracts não usam types iOS-only (e.g., Swift Bool wrapper) — só primitive Dart-Pigeon.

(k) BUILD CONFIG: Gradle Kotlin build.gradle.kts sintaxe atual (versão Kotlin DSL 2026), AndroidManifest permissions corretas (Android 13+ media permissions conforme memória), signing config keystore path em key.properties (gitignored).

Reporte em ≤500 palavras: PASS (a-k) ou holes específicos."

═══════════════════════════════════════════════════════════════
FASE 3 — Audit best-practices 2026 via WebSearch + Context7 (1 agente Explore, ~30 min)
═══════════════════════════════════════════════════════════════

7. Despache agente Explore com este prompt EXATO:

"Audit best-practices 2026 do Sprint 3 MD. Para cada item EXTERNO, validar via Context7 (preferência) OU WebSearch focado em maio 2026. Reporte: STATUS, BREAKING CHANGES, RECOMMENDED, URLs.

Lista exaustiva (NÃO ignore):

# Android frameworks + SDKs

1. **CameraX 1.6.1** (androidx.camera): ainda current em maio 2026 ou tem 1.7+ / 2.0 com breaking? ProcessCameraProvider + bindToLifecycle pattern ainda canonical? Memória raro-pattern-android-camerax-ultra-wide-unreliable (ultra-wide OEM unreliable) ainda válida?

2. **CameraX VideoCapture + Recorder API**: pattern atual pra MP4 recording Android? FileOutputOptions ainda canonical?

3. **MediaCodec circular replay buffer**: pattern em memória raro-pattern-android-mediacodec-buffer-management (dequeueInputBuffer + releaseOutputBuffer + deque circular) ainda canonical Android 14/15/16? Memória ainda aplicável?

4. **MediaMuxer**: ainda canonical pra mux H.264 + AAC → MP4 em Android 2026 ou Google introduziu replacement?

5. **Android SpeechRecognizer**: pt-BR ainda funcional sem Google Services workaround em Android 14+? SpeechRecognizer.createSpeechRecognizer + RecognitionListener pattern ainda atual? Quota / limitations changed?

6. **AudioManager.STREAM_MUSIC ContentResolver observer** (Settings.System.CONTENT_URI): ainda canonical em Android 14+ pra detectar volume button OU Google introduziu callback API nova (MediaSession volumeAdjustment)?

7. **BillingClient (Google Play Billing Library)**: versão atual em 2026? Sprint 3 usa via RevenueCat purchases_flutter — verificar RevenueCat suporta versão BillingClient atual.

8. **AndroidManifest permissions Android 13+** (memória raro-pattern-android-13-media-permissions): READ_MEDIA_VIDEO/IMAGES/AUDIO ainda corretas? Permission.videos/photos/audio (permission_handler) ainda canonical? Google Play Photo & Video Policy Oct 2024 ainda atual? Sprint 3 escolheu Option A (sandbox app, sem READ_MEDIA_*) — ainda recomendada em 2026?

9. **Android 13+ POST_NOTIFICATIONS permission**: Sprint 3 toca? Se sim, valida.

10. **Foreground Service Android 14+** (FOREGROUND_SERVICE_CAMERA): Sprint 3 background recording? Se sim, manifest declarations + runtime requirements.

# iOS Sprint 3 specific

11. **TestFlight external testing review SLA**: Apple ainda promete ~24h em 2026 ou subiu (ouvi falar de 7 dias em alguns blogs)?

12. **TestFlight requirements**: privacy policy URL obrigatória, app description, screenshots iOS (qual resolution mínima atual?), beta app review notes — lista 2026 atual.

13. **Apple Developer Program**: ainda $99/ano em 2026 ou subiu? Pra individual account em Brasil há restrições novas?

14. **iOS xcrun altool --upload-app**: ainda canonical em 2026 ou substituído (xcrun notarytool, xcodebuild)?

15. **App Store Connect in-app purchase setup**: trial 30d Apple ainda "1 month" fixo? Auto-Renewable Subscription pattern atual?

# Distribution

16. **Google Play Console**: taxa única $25 ainda atual em 2026 (subiu)?

17. **Google Play Internal Testing track**: setup atual (quantos testers, review SLA, app status requirements)?

18. **Google Play App Bundle (AAB)**: ainda padrão obrigatório vs APK em 2026? `flutter build appbundle --release` ainda canonical?

19. **Google Play signing**: Play App Signing ainda recomendado vs upload key local?

# i18n

20. **Flutter i18n synthetic-package: false** (memória raro-pattern-flutter-i18n-synthetic-package-false): ainda recomendado em Flutter 3.44+ ou padrão mudou em 3.45+?

21. **intl ^0.20.2**: ainda current em 2026? ARB format ainda canonical?

22. **flutter gen-l10n**: comando ainda canonical ou foi substituído?

# Testing

23. **integration_test --machine flag**: ainda funcional Flutter 3.44+ pra timeline parseável em CI?

24. **alchemist ^0.14.0**: golden tests ainda canonical em 2026 vs golden_toolkit + sucessor? Pattern alchemistsetup com runGoldenTests ainda atual?

25. **flutter_test widget tests**: testWidgets + ProviderScope ainda canonical em 2026?

26. **androidTest Kotlin** com Compose Camera Preview test runner: pattern atual pra teste de bridge nativo Android?

27. **XCTest Swift native**: padrão pra teste Pigeon bridge iOS ainda canonical?

# Firebase + Analytics

28. **firebase_core ^4.9.0 + firebase_analytics ^12.4.1 + firebase_crashlytics ^5.2.2**: ainda current em maio 2026? Breaking changes desde versão MD?

29. **GoogleService-Info.plist (iOS) + google-services.json (Android)** config files: ainda required em 2026? Path setup pattern Flutter ainda canonical?

30. **Crashlytics 3 handlers** (memória raro-pattern-crashlytics-3-handlers): FlutterError + PlatformDispatcher + Isolate listener ainda obrigatórios em Flutter 3.44+?

31. **firebase analytics events Dart ^12.4.1**: API atual? logEvent + setUserProperty patterns ainda canonical?

# Pigeon Debug Channel (ADR-0016)

32. **Pigeon @HostApi com #if DEBUG guard (Swift) / BuildConfig.DEBUG (Kotlin)**: pattern recomendado pra debug-only channels? Sprint 3 implementa CameraDebugHostApi via esse pattern.

# Performance

33. **iPhone 12 firmware atual (iOS 18/19)**: memórias raro-pattern-ios-avcapture-iphone12-dualwide-zoom-mapping ainda válidas com firmware atual em maio 2026? Apple mudou behavior do DualWide?

34. **Xiaomi MIUI/HyperOS detection** (memória raro-pattern-xiaomi-miui-hyperos-detection): manufacturer == 'Xiaomi' detection ainda funcional em maio 2026 ou HyperOS 2 mudou? Comportamento background kill ainda existe (justifica modal M02)?

# Workflow

35. **Flutter wireless debug Android** (similar a iOS): ainda funciona em maio 2026 ou Google introduziu restrictions?

36. **lefthook + commitlint pra Android-specific scopes**: scope-enum em commitlint.config.cjs precisa update pra Sprint 3 (e.g., 'android', 'i18n', 'testflight', 'play')?

# Privacy

37. **App Tracking Transparency (ATT) iOS**: Sprint 3 implementa Crashlytics/Analytics — exige IDFA? Verificar política atual.

38. **Google Play Data Safety form**: Sprint 3 submission exige declaração de quais dados coletamos. Templates atuais.

39. **GDPR + LGPD compliance**: Brasil-specific privacy policy requirements em maio 2026 atualizados?

Reporte em ≤2000 palavras estruturado por item (1-39):
- Item: [nome]
- Status: CURRENT / DEPRECATED / SUPERSEDED  
- Versão atual maio 2026: [vX.Y.Z]
- Breaking changes desde versão MD: [sim/não + detalhe]
- Recomendação: KEEP / UPGRADE / REPLACE com [alternativa]
- Source: [URL Context7 ou WebSearch]

Para itens 1, 3, 8, 20, 30, 33, 34 (memórias-based): AINDA APLICÁVEL / OBSOLETO / PRECISA UPDATE + evidência."

═══════════════════════════════════════════════════════════════
FASE 4 — Consolidação + Gate
═══════════════════════════════════════════════════════════════

8. Consolide FASE 2 + FASE 3 em report único.

9. Reporte:
   - "BLOQUEANTES (X):" lista
   - "WARNINGS (Y):" lista
   - "INFORMATIVE (Z):" lista
   - "DECISÃO PROPOSTA"

10. AGUARDE confirmação. Se BLOQUEANTES: corrigir MD com commit `docs(docs): sprint 3 md audit fixes`.

═══════════════════════════════════════════════════════════════
FASE 5 — Execução
═══════════════════════════════════════════════════════════════

11. Execute Task A inteira (A1 Apple Dev signup → A2 bundle ID + provisioning → A3 in-app products App Store Connect). Steps A1-A3 mistura CLI + UI externa (App Store Connect dashboard) — peça confirmação a cada UI step.

═══════════════════════════════════════════════════════════════
FASE 6 — Closure
═══════════════════════════════════════════════════════════════

12. /session-end → próximo "Sprint 3 Task B (Android Camera bridge)".

═══════════════════════════════════════════════════════════════
GUARDRAILS
═══════════════════════════════════════════════════════════════

- "FORA DE ESCOPO" pra drift
- 1 sessão = Task A fechado
- Sem --no-verify
- Confirme destrutivos
- Workflows multi-agent só FASE 2 + FASE 3
- Sem auto-rewrite de project.pbxproj (§13 terminal-first) — se Xcode UI precisar pra signing, commit antes/depois validando diff
```

### 3 — Sessão de execução (Task subsequente)

Cole substituindo `[TASK]` (B, C, D, E, F, G, H, I, J, K, L):

```
Sessão Sprint 3 — Task [TASK].

CONTEXTO: Sprint 3 Kickoff feito (audit FASE 1-4 completo) em sessão anterior. Esta sessão executa apenas Task [TASK].

Setup (~5 min):
1. /prime
2. git log + git status → Tasks anteriores commitadas, branch limpa.
3. Leia sprint-3-android-parity-testflight-client.md seção "Task [TASK]" + memórias citadas em "Memória relevante" da Task.
4. Pre-flight Task-specific:
   - Tasks B-E (Android code): device Android conectado USB + USB debugging? adb devices retorna o device?
   - Task F (Google Play): Play Console com app criado + Internal Testing track ativo?
   - Task G (i18n): ARB files preparados ou esta task cria?
   - Task H (modais P12/P13/P14 + Crashlytics + Analytics): Firebase configs presentes? Memória crashlytics-3-handlers aplicada?
   - Task I (golden + integration_test E2E): Pigeon CameraDebugHostApi spec'd em ADR-0016?
   - Task J (TestFlight): pre-flight de J no MD (privacy policy URL pronta, screenshots, app icon 1024x1024)?
   - Task K (Google Play Internal Testing): pre-flight de K (Data Safety form, AAB signed config)?
   - Task L (cliente smoke test): cliente já recebeu invite e instalou em iPhone E Android?
5. Mini-audit (sem WebSearch — herda Kickoff): file paths Task [TASK] existem? APIs nativas Android/iOS coerentes? Cite holes ≤100 palavras ou "clean".

Execução:
6. Execute step-by-step. Confirme destrutivos (incluindo TestFlight upload e Play Store upload). Para upload: validar versão incrementada em pubspec.yaml.
7. Lefthook GREEN. androidTest GREEN se B-E. XCTest GREEN se J. Smoke test device Android (B-E + G-K) ou iPhone (J).

Closure:
8. /session-end → próximo "Sprint 3 Task [PRÓXIMA]".
9. Reporte tasks done, commits, smoke iOS + Android.

Guardrails idem Kickoff.
```

### 3 — Sessão de closure (Task L — ENTREGA CLIENTE)

```
Sessão de closure Sprint 3 — ENTREGA CLIENTE.

1. /prime
2. Verifique:
   - Cliente recebeu email TestFlight + instalou em iPhone real? Smoke test fim-a-fim cliente PASSOU?
   - Cliente recebeu link Internal Testing Android + instalou? Smoke test fim-a-fim cliente PASSOU?
   - Lista de bugs cliente registrada (GitHub issues ou doc)?
3. Marcar Blueprint §11 Sprint 3 todos ✅.
4. Criar docs/sessions/<NNNN>-sprint3-closure.md descrevendo v1.0 candidata App Store + Play Store production submission. INDEX update.
5. Commit final: `docs(blueprint): v1.0 ready + cliente entregue em ambas plataformas`.

Próxima fase (FORA deste plano 3-sprint): pol nish + screenshots oficiais + privacy policy final + categoria + marketing → production submission.
```

---

## Templates auxiliares

### Audit-only (validar um Sprint MD sem executar)

Use se quer só validar o MD sem rodar nada.

```
Audit-only do MD docs/superpowers/plans/sprint-[N]-*.md.

Não execute Tasks. Apenas:
1. /prime
2. Leia o MD inteiro
3. Despache 2 agentes Explore em paralelo:
   - Agente 1: audit mecânico (file paths, comandos, placeholders, cross-MD, specs/ADRs, memórias). Mesmo prompt do FASE 2 do Kickoff Sprint [N] desse SESSION-PROMPTS.md.
   - Agente 2: audit best-practices 2026 via WebSearch + Context7. Mesmo prompt do FASE 3 do Kickoff Sprint [N].
4. Consolide reports em BLOQUEANTES / WARNINGS / INFORMATIVE.
5. AGUARDE minha decisão.

NÃO commita nada, NÃO altera código de produção.
```

### Recovery (algo quebrou)

```
Recovery session.

Sintoma: [descreva em 1-2 frases]

1. /prime
2. git status + git log --oneline -10
3. Identifique último commit estável (lefthook GREEN, analyze 0 issues, test PASS)
4. Reporte hipóteses do que quebrou + opções de recovery (revert vs fix forward)
5. NÃO faça reset destrutivo sem confirmação.

Se sintoma é "Firebase iOS 15 vs 13", aplique recovery flow da memória raro-pattern-flutter-ios-regen-xcconfig-spm-recovery:
  - quit Xcode → bun --filter @raro/mobile run pub:get → rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-* → reabrir Xcode → aguardar Package Resolution → build via terminal.

Se sintoma é "Build SUCCEEDED mas app não roda", aplique memória raro-pattern-xcode-preaction-modifies-workspace:
  - xclogparser parse --file <log>.xcactivitylog --reporter flatJson → inspect Build Phases executadas.
```

### Continuação (sessão anterior pausada mid-Task)

```
Continuação Sprint [N] Task [TASK].

Sessão anterior pausou mid-Task. Último estado conhecido:
[descreva]

1. /prime
2. git status + git log --oneline -5 (último commit)
3. Releia docs/superpowers/plans/sprint-[N]-*.md seção "Task [TASK]" identificando próximo step não-concluído.
4. Reporte: qual step faltava? Tem evidência de trabalho parcial não-commitado (arquivos não-staged)?
5. AGUARDE meu OK antes de prosseguir.
```

---

## Lembretes universais (vale pra TODA sessão)

- **`/prime` SEMPRE** no início — re-injeta Blueprint + INDEX + invariants. Não confiar em contexto pré-existente.
- **Kickoff SEMPRE faz audit completo FASE 1-4 ANTES de executar Task A**. Sessões subsequentes herdam o audit do Kickoff.
- **"FORA DE ESCOPO"** pra qualquer drift mid-task. Backlog vira nova sessão.
- **Sem `--no-verify`** em nenhum commit. Lefthook falhar = diagnose causa-raiz.
- **Confirme destrutivos**: `rm`, `git reset --hard`, `git push --force`, `git branch -d`, `git checkout .`, uploads TestFlight/Play Store. Pergunte antes.
- **`/session-end`** ao final — registra sessão + define próximo objetivo.
- **Workflows multi-agent (`/audit` adversarial)** só FASE 2 + FASE 3 do Kickoff, NÃO durante execução.
- **NUNCA mexa em `pubspec.yaml`, `Blueprint.md`, `native_bridges/`** sem ADR aberto primeiro (CLAUDE.md doctrine).
- **Wake word = "Raro"**, free trial = 30 dias, planos = R$ 9,90 mensal / R$ 89,90 anual, Bundle ID = `com.rarocamera` — locked invariants, NÃO mudar.

---

## Em palavras simples

Esse arquivo é teu cardápio de prompts. Cada vez que abrir uma sessão Claude Code pra trabalhar em alguma Sprint:

**Primeira sessão de uma Sprint (Kickoff)**: cola o prompt **"X.0 — Kickoff"**. O agente vai gastar ~30-50min auditando TUDO (lê os MDs, valida cada lib/API/serviço via WebSearch+Context7, checa contradições entre Sprints) ANTES de tocar em código. Você decide se "executar" ou "corrigir o MD primeiro". Custo: tokens + tempo upfront. Benefício: zero rework por dep deprecated ou conflito descoberto tarde.

**Sessões subsequentes da mesma Sprint**: cola "X — Sessão de execução" substituindo `[TASK]` pela letra. Audit muito mais leve (Sprint já foi auditado). Roda Task, commita, fecha.

**Quando Sprint terminar**: "X — Sessão de closure". Smoke test fim-a-fim manual, marca Blueprint, fecha Sprint.

**Princípio organizador**: pagar o audit caro UMA VEZ no início de cada Sprint > revisar e refatorar TODA sessão. Tua escolha consciente foi essa, esse arquivo materializa.

Não precisa entender o conteúdo técnico do audit — você acompanha pelo terminal + pelo report final que o agente te entrega antes de executar.

