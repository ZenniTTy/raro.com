# Sprint 2 — Prompts (Backend/Lógica Real iOS)

> ⚠️ OBSOLETO EM PARTE (2026-06-22). NÃO rodar o smoke de closure como está: ele manda validar 'Dizer Raro → REC inicia' (wake-word de palavra única, que NÃO é o estado real — hoje são 2 comandos foreground 'raro gravar'/'raro parar') e 'Subscribe sandbox → trial 30d' (RevenueCat = mock, nunca integrado). Wake-word background = standby Sensory (ONNX reprovado, sessão 0029).

> **Uso**: este arquivo contém TODOS os prompts copy-paste para sessões da Sprint 2. Abra → encontre o prompt → copie → cole em chat novo Claude Code. Self-contained: não precisa abrir outros arquivos.

**Entrega Sprint 2**: substituir implementações mock dos Riverpod providers de Sprint 1 por implementações REAIS, mantendo UI intacta. Recording real (MP4 H.264/H.265 → vault), replay buffer 15s/30s native (AVAssetWriter), wake word "Raro" (SFSpeechRecognizer + restart loop), volume button (KVO AVAudioSession), paywall RevenueCat sandbox, vault + share. Ainda iOS-only. Free Apple ID. NÃO paga $99. NÃO toca Android.

**Tasks Sprint 2**: A (recording + vault) → B (replay buffer) → C (wake word "Raro") → D (volume button) → E (RevenueCat sandbox) → F (share + polish + closure).

---

## Como usar este arquivo

1. **Primeira sessão Sprint 2** → cole **"2.0 — Kickoff"** (audit completo 30-50min, gate, execução Task A).
2. **Sessões seguintes** → cole **"2 — Sessão de execução"** substituindo `[TASK]` pela letra (B/C/D/E/F).
3. **Última sessão** → cole **"2 — Sessão de closure"** (smoke test fim-a-fim + Blueprint mark).
4. **Quebrou algo** → cole **"Recovery"**.
5. **Sessão anterior pausou mid-Task** → cole **"Continuação"**.
6. **Só validar MD sem executar** → cole **"Audit-only"**.

---

## 2.0 — Kickoff (primeira sessão Sprint 2)

Cole este prompt EXATO, sem modificar:

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

---

## 2 — Sessão de execução (Task subsequente)

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

**Letras válidas Sprint 2**: A (recording + vault), B (replay buffer), C (wake word "Raro"), D (volume button), E (RevenueCat sandbox — exige Apple Sandbox Tester), F (share + polish).

---

## 2 — Sessão de closure (Task F final + smoke fim-a-fim)

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

Próxima sessão: Sprint 3 Kickoff — abrir SPRINT-3-PROMPTS.md (apenas com confirmação de pagar Apple Dev $99 + Google Play $25).
```

---

## Audit-only (validar Sprint 2 MD sem executar)

```
Audit-only Sprint 2 MD docs/superpowers/plans/sprint-2-backend-logic-ios.md.

NÃO execute Tasks. Apenas:
1. /prime
2. Leia o MD inteiro + sprint-1 + sprint-3 (cross-MD check)
3. Despache 2 agentes Explore em paralelo:
   - Agente 1: rode o mesmo prompt FASE 2 do Kickoff 2.0 (audit mecânico)
   - Agente 2: rode o mesmo prompt FASE 3 do Kickoff 2.0 (audit best-practices 2026 via WebSearch + Context7)
4. Consolide em BLOQUEANTES / WARNINGS / INFORMATIVE.
5. AGUARDE minha decisão.

NÃO commita nada, NÃO altera código de produção.
```

---

## Recovery (algo quebrou)

```
Recovery session.

Sintoma: [descreva em 1-2 frases]

1. /prime
2. git status + git log --oneline -10
3. Identifique último commit estável (lefthook GREEN, analyze 0 issues, test PASS)
4. Reporte hipóteses + opções de recovery (revert vs fix forward)
5. NÃO faça reset destrutivo sem confirmação.

Sintomas comuns Sprint 2:
- "Pigeon não regenerou após edit": rode `bun --filter @raro/mobile run pigeon` + verifique `.g.dart` + `.g.swift` outputs
- "XCTest falha em RunnerTests sem mudança aparente": memória raro-pattern-flutter-ios-regen-xcconfig-spm-recovery (quit Xcode → pub:get → DerivedData clean → reabrir)
- "RevenueCat sandbox retorna empty offerings": confirmar Sandbox Tester signed in no iPhone Settings → App Store, e RevenueCat dashboard tem products configurados
- "Wake word não detecta 'Raro'": confirmar mic permission + SFSpeechRecognizer authorization, e que pt-BR locale está ativo
- "Volume button não dispara callback": memória raro-pattern-ios-volume-button-kvo-app-store-review (AVAudioSession.ambient + KVO obs install em start)
```

---

## Continuação (sessão pausada mid-Task)

```
Continuação Sprint 2 Task [TASK].

Sessão anterior pausou mid-Task. Último estado:
[descreva]

1. /prime
2. git status + git log --oneline -5
3. Releia sprint-2-backend-logic-ios.md seção "Task [TASK]" identificando próximo step não-concluído
4. Reporte: qual step faltava? Tem trabalho parcial não-commitado (XCTest WIP, Pigeon regenerated mas não wired, native Swift incomplete)?
5. AGUARDE meu OK antes de prosseguir.
```

---

## Lembretes universais (vale pra TODA sessão Sprint 2)

- **`/prime` SEMPRE** no início — re-injeta Blueprint + INDEX + invariants.
- **Kickoff 2.0 SEMPRE faz audit completo FASE 1-4 ANTES de executar Task A**. Sessões subsequentes herdam o audit.
- **"FORA DE ESCOPO"** pra qualquer drift mid-task. Backlog vira nova sessão.
- **Sem `--no-verify`** em nenhum commit. Lefthook falhar = diagnose causa-raiz.
- **Confirme destrutivos**: `rm`, `git reset --hard`, `git push --force`, `git branch -d`, `git checkout .`. Pergunte antes.
- **Não toque code Sprint 1 UI** a menos que swap exija. Sprint 2 só substitui implementação interna do provider, signature pública intacta.
- **`/session-end`** ao final.
- **Workflows multi-agent** só FASE 2 + FASE 3 do Kickoff.
- **Pigeon contracts platform-agnostic** — Sprint 3 vai implementar mesma API surface em Android, types iOS-only quebram cross-platform.
- **Locked invariants** (NÃO mudar): wake word = "Raro", free trial = 30 dias, planos = R$ 9,90 mensal / R$ 89,90 anual, Bundle ID = `com.rarocamera`.

---

## Em palavras simples

Esse arquivo é tua receita pra Sprint 2. Quando abrir uma sessão pra trabalhar nessa Sprint:

**Primeira vez** (Kickoff): cola o prompt "2.0 — Kickoff". O agente vai gastar 30-50min auditando 26 libs/APIs nativas iOS/serviços (incluindo RevenueCat workaround sem $99, SFSpeechRecognizer quota, AVAssetWriter circular buffer, AVAudioSession KVO) via WebSearch+Context7 ANTES de tocar em código. Você decide "executar" ou "corrigir o MD primeiro". Só depois roda Task A (recording real).

**Sessões seguintes**: cola "2 — Sessão de execução" trocando `[TASK]` pela letra da próxima (B, C, D, E, F). Audit muito mais leve. Roda Task, commita, fecha.

**Última sessão** (Closure): cola "2 — Sessão de closure". Smoke test fim-a-fim no iPhone 12 (gravação real, replay buffer, wake word, volume, paywall sandbox, share), marca Blueprint, fecha Sprint 2. Próximo passo: abrir SPRINT-3-PROMPTS.md (aí sim paga $99 Apple Dev + $25 Google Play).

Não precisa entender o conteúdo técnico do audit — você acompanha pelo terminal + pelo report final que o agente te entrega antes de executar.

