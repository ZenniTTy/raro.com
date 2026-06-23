# Prompt de abertura — Próxima sessão: BLOCO 1 (Firebase/Crashlytics)

> Cole o bloco abaixo (entre as linhas `---`) ao abrir a próxima sessão. Começa com `/prime`.

---

Contexto: as sessões 0031/0032/0033 fecharam (tudo commitado E pushado; HEAD `af35962` em
`origin/feat/camera-native-bridge`). Estado autoritativo:
  - Bloco 0 FECHADO (0031): Android compila (`flutter build appbundle` ✓), App ID alinhado
    `com.rarocamera` nas 2 plataformas, label "Raro Camera", ONNX órfão dormente.
  - Bloco 1 PRÉ-REQS PRONTOS (0032): conta Firebase `raro-camera` criada, apps iOS+Android
    registrados (bundle `com.rarocamera`), `GoogleService-Info.plist` em
    `apps/mobile/ios/Runner/` e `google-services.json` em `apps/mobile/android/app/` (ambos
    GITIGNORED — chaves REAIS, NÃO commitar; existem só no device do dono). `flutterfire_cli`
    1.4.0 instalado em `~/.pub-cache/bin` (NÃO está no PATH → prefixar comandos com
    `export PATH="$PATH:$HOME/.pub-cache/bin"` ou usar caminho absoluto).
  - Voz: FOREGROUND SFSpeech "raro gravar"/"raro parar" funciona (iPhone 12). BACKGROUND
    wake-word: Sensory EM VALIDAÇÃO ATIVA (0033) — pendente preço (email Jeff) + teste do
    modelo "Raro" no iPhone. NÃO mexer nessa frente nesta sessão (é outra fase, bloqueada
    esperando emails). NÃO reabrir treino ONNX próprio sem ADR.

Roadmap vigente: `docs/superpowers/plans/PLANO-MESTRE-finalizacao-entrega-cliente.md` (Bloco 1).

Entregável desta sessão (1 sessão = 1 entregável fechado): BLOCO 1 — Firebase não crasha em
release + telemetria liga. Em ordem:
  1.1  `flutterfire configure` (gera `firebase_options.dart`, que JÁ está gitignored) →
       `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` no
       `apps/mobile/lib/main.dart` (hoje só `WidgetsFlutterBinding.ensureInitialized()` +
       `runApp`; sem Firebase = crasha em release). Plugin gradle google-services no DSL
       MODERNO: `id("com.google.gms.google-services") version "<descobrir via Context7/pub.dev>"
       apply false` em `apps/mobile/android/settings.gradle.kts` + `id(...)` em
       `app/build.gradle.kts`. NÃO é classpath legado. Deps já no pubspec
       (firebase_core ^4.9.0, firebase_analytics ^12.4.1, firebase_crashlytics ^5.2.2).
  1.2  Crashlytics: os 3 handlers OBRIGATÓRIOS (FlutterError.onError + PlatformDispatcher
       .onError + Isolate listener) — só 1 ou 2 deixa erros escapando. Memória
       `raro-pattern-crashlytics-3-handlers`.
  1.3  Confirmar analytics events disparando (já há `camera_analytics_listener`).

Antes de tocar código: rode `/prime`, leia o Bloco 1 completo no PLANO-MESTRE, e confirme via
Context7/pub.dev a versão atual do plugin gradle `com.google.gms.google-services` e do
`com.google.firebase.firebase-crashlytics` (NÃO chutar — MCP precedence do CLAUDE.md §4).

Gates do harness (CLAUDE.md §10) que se aplicam aqui:
  - Tocou `main.dart`/inicialização → validar no DEVICE, não só compilar. Firebase só prova
    em runtime: forçar um crash de teste e ver chegar no painel Crashlytics; ver evento no
    DebugView do Analytics.
  - Build iOS terminal-first (CLAUDE.md §13): `bun run --filter '@raro/mobile' dev:ios`,
    2 git overrides SPM no sandbox, debug NÃO roda standalone no device (usar
    `flutter build ios --profile` + `xcrun devicectl`). Firebase iOS exige iOS 15+ (ADR-0014;
    o `firebase_core` 4.x já força isso) — pode reativar o loop SPM 13/15; memórias
    `raro-pattern-flutter-spm-ios-13-hardcoded`, `raro-pattern-flutter-ios-regen-xcconfig-spm-recovery`,
    `raro-pattern-spm-safe-bare-repository-sandbox`.
  - GATE PÓS-`flutterfire configure`: rodar `git status` e CONFIRMAR que os 3 arquivos Firebase
    (plist/json/`firebase_options.dart`) NÃO aparecem para commit (estão gitignored;
    `block-env.sh` também bloqueia os 3). Se algum aparecer, PARAR — é chave real.

Boas práticas que NÃO podem ser repetidas (memórias):
  - feedback_verify_device_install_before_test — confirmar "App installed" antes de pedir teste.
  - feedback_ios_workflow_terminal_first_no_xcode_build — build sempre via terminal/bun.
  - feedback_per_task_harness_validation — após CADA commit: analyze + test (não batched).
  - raro-pattern-bun-filter-arg-order — `bun run --filter '@raro/mobile' <script>`.
  - feedback_synthetic_eval_is_not_the_gate_device_is — só device decide (vale p/ Crashlytics:
    "configurei" ≠ "crash chegou no painel"; provar com o crash real).

Dependência externa: a conta Firebase é do DONO (projeto `raro-camera`). Se faltar permissão
ou config no console (ex: Crashlytics não habilitado no painel), avisar o dono — não inferir.

Fecho a sessão com `/session-end`.

---

## Por que este prompt (notas, não colar)

- **Bloco 1 é o próximo CÓDIGO**, independente da Sensory (que está em validação, bloqueada por emails).
- Pré-reqs já feitos na 0032 → a sessão é só código, não espera o cliente (exceto habilitar Crashlytics no painel, se preciso).
- Os gates de SPM iOS e device-validation são os maiores riscos técnicos — por isso citados explícitos.
- Substitui os prompts obsoletos `NEXT-SESSION-PROMPT-bloco-0-destravar.md` (Bloco 0 já fechado na 0031) e `NEXT-SESSION-PROMPT-voice-openwakeword.md` (beco ONNX, sessão 0029).
