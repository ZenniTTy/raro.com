# 0034 — Bloco 1: Firebase init + Crashlytics 3 handlers + analytics ligado (código + build provados; device pendente)

- **Data:** 2026-07-13
- **Duração:** ~2h30 (código rápido; a maior parte foi build iOS + diagnóstico de um beco de verificação)
- **Participantes:** Eduardo Rodrigues + Claude Code (Opus 4.8)
- **Branch:** `feat/camera-native-bridge`
- **Commits:** `2085811` (`feat(analytics)`) — 1 commit de código, 0 `--no-verify`

## Objetivo

Bloco 1 do PLANO-MESTRE (o próximo trabalho de CÓDIGO, independente da Sensory): fazer o app **não crashar em release** por falta de Firebase + **ligar a telemetria**. Escopo declarado upfront: `flutterfire configure` + `Firebase.initializeApp` + plugins gradle + os 3 handlers Crashlytics + confirmar analytics disparando. Device gate (crash real no painel) deixado explicitamente para uma sessão com o iPhone conectado (decisão do dono nesta sessão: "código + build agora, device depois").

## Contexto inicial

Pré-reqs prontos na 0032: projeto Firebase `raro-camera`, apps iOS+Android registrados (`com.rarocamera`), `GoogleService-Info.plist` + `google-services.json` posicionados e **gitignored** (chaves reais), flutterfire CLI 1.4.0 em `~/.pub-cache/bin`. `main.dart` só tinha `ensureInitialized()` + `runApp` — sem Firebase = crash em release. Havia um `camera_analytics_listener` **definido mas nunca observado** (logo, morto — os eventos nunca disparavam).

## O que foi feito

**Versões verificadas em fonte primária (§4 MCP precedence — Context7 estava STALE):**
- `com.google.gms.google-services`: Context7 mostrava `4.3.5`; Google Maven diz `4.5.0` latest. A CLI flutterfire fixou `4.4.4` — **mantido** (Surgical Changes; 4.4.4 é atual e tool-validado, bump a 4.5.0 seria especulativo).
- `com.google.firebase.crashlytics` (gradle): Context7 `2.7.1` stale; Google Maven `3.0.7` latest → CLI usou `3.0.7`. OK.
- firebase_core 4.x exige Android minSdk **23**; `flutter.minSdkVersion` (Flutter 3.44, `FlutterExtension.kt:26`) = **24** → 24 ≥ 23, sem mudança. iOS deployment target já é 15 (Podfile).

**1.1 — Firebase configure + init:**
- Resolvido um bloqueio: `flutterfire configure` falhava no passo iOS com `cannot load such file -- xcodeproj` (system Ruby 2.6 sem o gem). Fix: `gem install xcodeproj` na Homebrew Ruby (4.0.5, sem sudo) + rodar a CLI com essa Ruby no PATH. Aí gerou `lib/firebase_options.dart` (android+ios) e patchou o `project.pbxproj` (plist no Copy Bundle Resources + build phase de upload de dSYM do Crashlytics). Memória `raro-pattern-flutterfire-configure-needs-ruby-xcodeproj`.
- `main.dart`: `Future<void> main() async` → `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` antes do `runApp`.
- Gradle DSL moderno (a CLI escreveu): `id("com.google.gms.google-services") version("4.4.4") apply false` + crashlytics em `settings.gradle.kts`; ambos aplicados em `app/build.gradle.kts`.

**1.2 — Crashlytics 3 handlers** (memória `raro-pattern-crashlytics-3-handlers`, confirmado via Context7): `FlutterError.onError = recordFlutterFatalError` + `PlatformDispatcher.instance.onError` (fatal:true) + `Isolate.current.addErrorListener`. Exatamente 3, sem `runZonedGuarded` especulativo.

**1.3 — Analytics wiring (era o furo real):** `cameraAnalyticsListenerProvider` estava definido mas **nunca observado** → nunca ativava. `RaroApp` virou `ConsumerWidget` e faz `ref.watch(cameraAnalyticsListenerProvider)` (keepAlive). Agora abrir a câmera (P05) dispara `camera_started` (params lens/resolution/fps).

**Test fix (systematic-debugging):** o wiring quebrou `smoke_test.dart` (`RaroApp` passou a tocar `FirebaseAnalytics.instance` no boot → `[core/no-app]` sem `initializeApp`, que o teste não chama). Root cause confirmado na stack. Fix seguindo o padrão já existente em `camera_analytics_listener_test.dart`: prover `_MockAnalytics` via `firebaseAnalyticsProvider.overrideWithValue`. 323 testes verdes.

**Builds provados (código + build agora):**
- **Android:** `flutter build appbundle --debug` → `✓ app-debug.aab` (86.8 MB, +28 MB vs release antigo = SDK Firebase nativo). Prova que os plugins gradle google-services + crashlytics resolvem e aplicam.
- **iOS:** `flutter build ios --debug --no-codesign` → `✓ Runner.app` (197 MB), `GoogleService-Info.plist` bundlado, Xcode compilou a firebase-ios-sdk (SPM, 16 pins) por **545s** sem erro. Firebase iOS resolve via **SPM, não CocoaPods** (por isso Podfile.lock não lista pods Firebase). Pré-req: fix-spm-ios-target.sh patchou Package.swift 13→15.

## O que NÃO foi feito (e por quê)

- **Prova de crash no device (o gate §10)** — decisão do dono: código+build agora, device depois. `main.dart`/init foi tocado, então "provado" exige runtime: forçar crash e ver no painel Crashlytics + `camera_started` no DebugView do Analytics. **Bloco 1 fica "código pronto e compila", NÃO "provado no device".** Runbook em `docs/superpowers/notes/` (a criar) — sequência: build profile + `xcrun devicectl install` (confirmar "App installed") → abrir câmera (DebugView) → trigger temporário `FirebaseCrashlytics.instance.crash()` (NÃO commitar) → reabrir → ver no painel.
- **UI de crash-test permanente** — decisão consciente (Simplicity First): não existe crash button no app; o trigger da prova é temporário, só na sessão de device. Nada especulativo commitado.
- **Bump google-services 4.4.4→4.5.0** — deixado de propósito (Surgical Changes; 4.4.4 é a versão que a CLI valida). 4.5.0 registrado aqui como informação, não ação.
- **Habilitar Crashlytics no console** (se necessário) — ação do dono; a conta Firebase é dele.

## Aprendizados / surpresas

- **`flutter build ios --simulator` NÃO funciona neste projeto** e me custou ~15min perseguindo um "problema de Firebase" que não existia. Causa: `SUPPORTED_PLATFORMS = iphoneos` no pbxproj (pré-existente, CLAUDE.md §13 já documenta) → o scheme só oferece destinos iphoneos; `--simulator` falha em destination-matching com **exit 0 enganoso**, mesmo com `--device-id <sim>` e o sim booted. Verificação correta = `flutter build ios --debug --no-codesign` (iphoneos) + conferir o **artefato** (`Runner.app` + timestamp), nunca o exit code. Memória `raro-pattern-ios-build-verify-iphoneos-not-simulator`.
- **Exit 0 mente 2× aqui:** (a) `| tail` engole o PIPESTATUS; (b) o `flutter build --simulator` retorna sucesso do wrapper mesmo com "Failed to build iOS app" no corpo. A memória `feedback_verify_device_install_before_test` (artefato > exit code) se aplica a build também.
- **Context7 estava desatualizado nas 2 versões gradle** (4.3.5 e 2.7.1) — Google Maven `maven-metadata.xml` foi o fallback correto (§4 item 2). Confirmar versão sempre, não confiar no 1º hit.
- **O "só confirmar analytics" (1.3) era na verdade um bug:** o listener estava morto (nunca observado). Ler o código antes de aceitar o enunciado do prompt pegou isso.
- **flutterfire precisa de Ruby com xcodeproj** — a system Ruby 2.6 não tem; a 1ª rodada escreve o gradle mas silenciosamente não gera o `firebase_options.dart` nem toca o iOS (parcial enganoso).

## Próximos passos

- **[SESSÃO DE DEVICE — com o dono] Provar Firebase no iPhone 12:** build profile + install (confirmar "App installed"), `camera_started` no DebugView, crash de teste (trigger temporário) → aparece no painel Crashlytics. Só então marcar 1.2/1.3 como provados. Se Crashlytics não estiver habilitado no console `raro-camera`, avisar o dono.
- **[BLOCO 2 — próximo código] Monetização RevenueCat** (depende conta RevenueCat + produtos + IAP Key do dono). Hoje `subscribe()` é mock (bool local).
- **[Sensory — bloqueado por emails, ação do dono]** wake-word background segue em validação ativa (0033) — fora do escopo de código.

## Referências

- Commit: `2085811`
- Arquivos: `apps/mobile/lib/main.dart`, `apps/mobile/lib/app.dart`, `apps/mobile/test/smoke_test.dart`, `apps/mobile/android/settings.gradle.kts`, `apps/mobile/android/app/build.gradle.kts`, `apps/mobile/ios/Runner.xcodeproj/project.pbxproj`, `apps/mobile/firebase.json` (novo, sem secrets); `firebase_options.dart`/plist/json permanecem gitignored
- Memórias novas: `raro-pattern-ios-build-verify-iphoneos-not-simulator`, `raro-pattern-flutterfire-configure-needs-ruby-xcodeproj`
- Memórias aplicadas: `raro-pattern-crashlytics-3-handlers`, `raro-pattern-flutter-spm-ios-13-hardcoded`, `raro-pattern-spm-safe-bare-repository-sandbox`, `feedback_verify_device_install_before_test`, `feedback_per_task_harness_validation`, `raro-pattern-bun-filter-arg-order`, `feedback_synthetic_eval_is_not_the_gate_device_is`
- Plano: `docs/superpowers/plans/PLANO-MESTRE-finalizacao-entrega-cliente.md` (Bloco 1, checkboxes 1.1-1.3 — código feito, device pendente)
- Sessão anterior: [0033](0033-sensory-voicehub-pro-nda-modelo-raro-ptbr-em-validacao.md)
