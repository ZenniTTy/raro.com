# Sprint 3 — Prompts (Android Parity + TestFlight + Cliente)

> ⚠️ ESTADO REAL 2026-06-22. Pre-flight incompleto: adicionar 'build Android compila (flutter build appbundle) — se falhar, executar PLANO-MESTRE Bloco 0.1 antes'. Wake-word Android = 2 comandos foreground (não palavra única); background standby Sensory. Comandos bun: 'bun run --filter X <script>'.

> **Uso**: este arquivo contém TODOS os prompts copy-paste para sessões da Sprint 3. Abra → encontre o prompt → copie → cole em chat novo Claude Code. Self-contained: não precisa abrir outros arquivos.

**Entrega Sprint 3**: paridade Android com iOS (Sprint 2) + pagamento Apple Developer Program ($99/ano) + Google Play Console ($25 taxa única) + TestFlight build + Google Play Internal Testing + cliente convidado em AMBAS plataformas. Entrega final do plano 3-Sprint.

**Tasks Sprint 3**: A (Apple Dev signup + bundle config) → B (Android camera CameraX) → C (Android recording + vault) → D (Android replay buffer MediaCodec) → E (Android wake word + volume) → F (Android paywall + Google Play setup) → G (i18n PT/ES/EN) → H (modais P12/P13/P14 + Crashlytics + Analytics) → I (golden tests + integration_test E2E) → J (TestFlight build + cliente convidado) → K (Google Play Internal Testing + cliente convidado) → L (smoke test cliente + closure).

---

## Como usar este arquivo

1. **Primeira sessão Sprint 3** → cole **"3.0 — Kickoff"** (audit completo 30-50min, gate, execução Task A).
2. **Sessões seguintes** → cole **"3 — Sessão de execução"** substituindo `[TASK]` pela letra (B/C/D/E/F/G/H/I/J/K).
3. **Última sessão** → cole **"3 — Sessão de closure (Task L — ENTREGA CLIENTE)"**.
4. **Quebrou algo** → cole **"Recovery"**.
5. **Sessão anterior pausou mid-Task** → cole **"Continuação"**.
6. **Só validar MD sem executar** → cole **"Audit-only"**.

---

## 3.0 — Kickoff (primeira sessão Sprint 3)

Cole este prompt EXATO, sem modificar:

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

---

## 3 — Sessão de execução (Task subsequente)

Cole substituindo `[TASK]` (B, C, D, E, F, G, H, I, J, K):

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
5. Mini-audit (sem WebSearch — herda Kickoff): file paths Task [TASK] existem? APIs nativas Android/iOS coerentes? Cite holes ≤100 palavras ou "clean".

Execução:
6. Execute step-by-step. Confirme destrutivos (incluindo TestFlight upload e Play Store upload). Para upload: validar versão incrementada em pubspec.yaml.
7. Lefthook GREEN. androidTest GREEN se B-E. XCTest GREEN se J. Smoke test device Android (B-E + G-K) ou iPhone (J).

Closure:
8. /session-end → próximo "Sprint 3 Task [PRÓXIMA]".
9. Reporte tasks done, commits, smoke iOS + Android.

Guardrails idem Kickoff.
```

**Letras válidas Sprint 3**: A (Apple Dev signup), B (Android camera CameraX), C (Android recording + vault), D (Android replay buffer MediaCodec), E (Android wake word + volume), F (Android paywall + Google Play setup), G (i18n PT/ES/EN), H (modais P12/P13/P14 + Crashlytics + Analytics), I (golden tests + integration_test E2E), J (TestFlight build + cliente convidado), K (Google Play Internal Testing + cliente convidado), L (smoke cliente + closure).

---

## 3 — Sessão de closure (Task L — ENTREGA CLIENTE)

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

Próxima fase (FORA deste plano 3-sprint): polish + screenshots oficiais + privacy policy final + categoria + marketing → production submission.
```

---

## Audit-only (validar Sprint 3 MD sem executar)

```
Audit-only Sprint 3 MD docs/superpowers/plans/sprint-3-android-parity-testflight-client.md.

NÃO execute Tasks. Apenas:
1. /prime
2. Leia o MD inteiro + sprint-1 + sprint-2 (cross-MD check)
3. Despache 2 agentes Explore em paralelo:
   - Agente 1: rode o mesmo prompt FASE 2 do Kickoff 3.0 (audit mecânico)
   - Agente 2: rode o mesmo prompt FASE 3 do Kickoff 3.0 (audit best-practices 2026 via WebSearch + Context7, 39 items)
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

Sintomas comuns Sprint 3:
- "Android build falha Gradle sync": confirmar Gradle Kotlin DSL versão + CameraX 1.6.1 deps + AndroidManifest permissions Android 13+
- "Xiaomi MIUI/HyperOS device não aparece no adb devices": ativar USB debugging em Developer Options + install apps via USB
- "TestFlight upload rejeitado": verificar privacy policy URL pronta, screenshots iOS, app icon 1024x1024, beta app review notes
- "Google Play AAB rejeitado": verificar Data Safety form preenchido, signing config keystore correto em key.properties
- "Wake word Android não detecta 'Raro'": confirmar mic permission Android + SpeechRecognizer.isRecognitionAvailable retorna true + pt-BR locale
- "Volume button Android não dispara callback": memória raro-pattern... confirmar ContentObserver registrado em Settings.System.CONTENT_URI
- "Firebase Crashlytics events não aparecem em Console": memória raro-pattern-crashlytics-3-handlers (FlutterError + PlatformDispatcher + Isolate listener obrigatórios)
- "i18n não troca locale": confirmar synthetic-package: false em l10n.yaml + flutter gen-l10n rodado + locale provider wired
```

---

## Continuação (sessão pausada mid-Task)

```
Continuação Sprint 3 Task [TASK].

Sessão anterior pausou mid-Task. Último estado:
[descreva]

1. /prime
2. git status + git log --oneline -5
3. Releia sprint-3-android-parity-testflight-client.md seção "Task [TASK]" identificando próximo step não-concluído
4. Reporte: qual step faltava? Tem trabalho parcial não-commitado (Kotlin WIP, Pigeon contract editado mas não regenerado, AAB build incomplete)?
5. AGUARDE meu OK antes de prosseguir.
```

---

## Lembretes universais (vale pra TODA sessão Sprint 3)

- **`/prime` SEMPRE** no início — re-injeta Blueprint + INDEX + invariants.
- **Kickoff 3.0 SEMPRE faz audit completo FASE 1-4 ANTES de executar Task A**. Sessões subsequentes herdam o audit.
- **"FORA DE ESCOPO"** pra qualquer drift mid-task. Backlog vira nova sessão.
- **Sem `--no-verify`** em nenhum commit. Lefthook falhar = diagnose causa-raiz.
- **Confirme destrutivos**: `rm`, `git reset --hard`, `git push --force`, `git branch -d`, uploads TestFlight, uploads Play Store. Pergunte antes.
- **`/session-end`** ao final.
- **Workflows multi-agent** só FASE 2 + FASE 3 do Kickoff.
- **Sem auto-rewrite de project.pbxproj** (§13 terminal-first). Se Xcode UI precisar pra signing, commit antes/depois validando diff.
- **Pigeon contracts mantêm signature** definida em Sprint 2 — Android implementa MESMA surface, types iOS-only NÃO entram.
- **Versão pubspec.yaml incrementada** antes de cada upload TestFlight ou Play Store.
- **Locked invariants** (NÃO mudar): wake word = "Raro", free trial = 30 dias, planos = R$ 9,90 mensal / R$ 89,90 anual, Bundle ID = `com.rarocamera`.

---

## Em palavras simples

Esse arquivo é tua receita pra Sprint 3 — a última do plano original. Quando abrir uma sessão pra trabalhar nessa Sprint:

**Primeira vez** (Kickoff): cola o prompt "3.0 — Kickoff". Antes de qualquer coisa, eu vou perguntar se já pagou o $99 da Apple e o $25 do Google, se tem device Android, privacy policy pronta, email do cliente. Se faltar, paro. Se OK, o agente vai gastar 30-50min auditando 39 items externos via WebSearch+Context7 (CameraX Android, MediaCodec, BillingClient, TestFlight requirements 2026, Apple Dev preço atual, Google Play taxa, Firebase Crashlytics handlers, i18n, ATT, GDPR) ANTES de tocar em código. Você decide "executar" ou "corrigir o MD primeiro". Só depois roda Task A (Apple Dev signup).

**Sessões seguintes**: cola "3 — Sessão de execução" trocando `[TASK]` pela letra da próxima (B, C, D, E, F, G, H, I, J, K). Audit muito mais leve. Roda Task, commita, fecha.

**Última sessão** (Closure Task L): cola "3 — Sessão de closure". Cliente já instalou o app em iPhone via TestFlight E em Android via Internal Testing. Smoke test cliente passou em ambas. Lista de bugs cliente registrada. Marca Blueprint §11 Sprint 3 tudo ✅. **Plano 3-sprint entregue.** Próxima fase (fora deste plano): polish + screenshots oficiais + production submission.

Não precisa entender o conteúdo técnico do audit — você acompanha pelo terminal + pelo report final que o agente te entrega antes de executar.

