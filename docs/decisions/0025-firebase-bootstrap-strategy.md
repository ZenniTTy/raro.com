# 0025 — Estratégia de bootstrap do Firebase (init eager + Crashlytics 3 handlers + pin dos plugins gradle)

- **Data:** 2026-07-14
- **Status:** Accepted
- **Sessões:** 0034 (código + build), 0035 (prova no device iPhone 12)
- **Implementa:** `docs/04-ROADMAP-SPECS/block-infra.md` µ-sprint 2.4 (o ADR de bootstrap-strategy prometido lá; o número 0014 originalmente reservado foi consumido por `0014-flutter-3.44-spm-ios-15.md`, então este recebe o próximo número livre, 0025)
- **Relaciona:** ADR-0001 (pin das deps `firebase_core`/`analytics`/`crashlytics`), ADR-0004 (Firebase como pilar da arquitetura client-only), ADR-0014 (SPM iOS 15 — Firebase iOS resolve via SPM)

## Contexto

As deps Firebase (`firebase_core ^4.9.0`, `firebase_analytics ^12.4.1`, `firebase_crashlytics ^5.2.2`) já eram decisão de stack registrada (ADR-0001 + ADR-0004), mas nunca haviam sido ativadas: `main.dart` só chamava `WidgetsFlutterBinding.ensureInitialized()` + `runApp`, sem `Firebase.initializeApp` — o app **crashava em release**. A spec `block-infra.md` (µ-sprint 2.4) exigia um ADR de bootstrap-strategy que nunca foi criado, deixando as decisões de *como* o Firebase liga espalhadas em session logs (não-autoritativos). Este ADR consolida essas decisões.

## Decisão

1. **Init eager no boot.** `main()` vira `Future<void> main() async` e chama `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` **antes** do `runApp`. Sem tratamento de "config ausente em dev": os configs (`GoogleService-Info.plist`/`google-services.json`/`firebase_options.dart`) são pré-requisito de build e ficam gitignored no device do dono; um build sem eles falha explicitamente (preferível a um no-op silencioso que mascararia telemetria morta). O provider `firebaseAnalyticsProvider` (`FirebaseAnalytics.instance`) **lança se acessado antes do init** — por isso a ordem init→handlers→runApp é obrigatória.

2. **Crashlytics: exatamente 3 handlers**, sem `runZonedGuarded`.
   - `FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError` (erros síncronos do framework Flutter).
   - `PlatformDispatcher.instance.onError` → `recordError(..., fatal: true)` (erros assíncronos fora do framework).
   - `Isolate.current.addErrorListener` → `recordError(..., fatal: true)` (erros em isolates).
   - **`runZonedGuarded` NÃO é usado**: a orientação moderna do FlutterFire (validada via Context7, 2026-07-13) prefere `PlatformDispatcher.instance.onError`, que cobre o mesmo caminho sem o custo/aninhamento da zona. Adicionar `runZonedGuarded` seria redundante. Memória `raro-pattern-crashlytics-3-handlers`.

3. **Plugins gradle no DSL moderno, versões pinadas.** Em `apps/mobile/android/settings.gradle.kts` (`apply false`) + `apps/mobile/android/app/build.gradle.kts` (aplicados):
   - `com.google.gms.google-services` **4.4.4**
   - `com.google.firebase.crashlytics` **3.0.7**
   - Escritos pela CLI `flutterfire configure`. **Não bumpados para 4.5.0** (o latest à época) — Surgical Changes: 4.4.4 é a versão que a CLI valida contra seus templates; bump seria especulativo. Estes pins são **imutáveis sem novo ADR** (mesma regra das deps do pubspec — CLAUDE.md §3).

4. **iOS resolve Firebase via SPM, não CocoaPods** (consequência do ADR-0014). O `Podfile.lock` não lista pods Firebase; o `Package.resolved` do xcworkspace tem os 16 pins (`firebase-ios-sdk`, `googleappmeasurement`, etc.). A build phase de upload de dSYM que o `flutterfire configure` adicionou ao `project.pbxproj` já cobre o caso SPM (aponta para `firebase-ios-sdk/Crashlytics/run` quando não há `$PODS_ROOT/FirebaseCrashlytics`).

## Consequências

- **Positivas:** app não crasha em release; crashes e telemetria chegam ao Firebase (provado no iPhone 12, sessão 0035 — crash real recebido no painel + dSYM aceito, UUID batendo). Decisões de bootstrap agora têm fonte autoritativa (este ADR) em vez de só session logs.
- **Negativas / pendências:**
  - **Upload automático de dSYM em release/CI não garantido:** `flutter build` de linha de comando pode não disparar a build phase de upload; na sessão 0035 os dSYMs foram subidos manualmente via `upload-symbols`. Validar no pipeline de publicação (Bloco 5). Sem isso, stacks de crashes de produção vêm sem símbolos.
  - **Instrumentação de analytics incompleta:** só `camera_started`/`camera_error` estão wired; os outros 28 eventos de `analytics_events.dart` seguem sem emissor (cobertura, não drift de schema).
- **Gap de guarda registrado:** o hook `warn-adr-drift.sh` não vigia `android/**/*.gradle.kts`, então não teria avisado da mudança de plugins gradle. Melhoria de guarda anotada (não bloqueante).

## Alternativas consideradas

- **Init lazy / graceful no-op em dev:** rejeitado — mascararia telemetria morta e o crash-em-release que motivou o bloco; falha explícita é melhor sinal.
- **`runZonedGuarded` como 4º mecanismo:** rejeitado — redundante com `PlatformDispatcher.onError` na orientação atual do FlutterFire.
- **Bump google-services 4.4.4 → 4.5.0:** rejeitado nesta entrega — Surgical Changes; sem necessidade concreta.
