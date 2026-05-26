# 2026-05-25 — api-contract-shared

> Spec-001 (rm-2) — **bloqueante**. Estabelece o contrato anti-drift do projeto RARO. Todas as specs subsequentes (bridges, telas, paywall, settings, gallery) referenciam este contrato e **não redefinem nomes**. Brainstorming concluído em 2026-05-26.

## Status

`Approved` — 2026-05-26.

## Owner / Implementer

- **Spec owner:** Eduardo Rodrigues
- **Implementer agent:** `implementer`
- **Validator agent:** `validator`
- **Co-agents acionados nesta spec:** `adr-guardian` (ADR-013), `researcher` (validação Context7/WebSearch de Pigeon + Theme Tailor)

## Reading order (pre-flight obrigatório)

1. `docs/briefing/original-briefing.md` — Seções 3.2 (protótipo como fonte), 5 (escopo), 6 (decisões técnicas)
2. `docs/Blueprint.md` — Seções 1 (divergências), 2 (stack), 4 (design system), 5 (mapa de telas), 9 (ADRs previstos)
3. `docs/briefing/prototype/Prototipo-RARO.html` — bloco CSS `:root` (linhas iniciais) + screen registry no JS
4. `CLAUDE.md` — Seções 1 (Karpathy), 5 (convenções), 11 (anti-patterns)
5. ADRs relacionados: **0001** (stack inicial), **0009** (wake word), **0010** (planos dual)
6. ADR novo desta spec: **0013 — Pigeon + Theme Tailor + gates anti-drift** (será criado junto)

## Problem

O projeto RARO tem hoje **≥ 12 famílias de identificadores duplicáveis** que, sem fonte única, vão divergir entre `apps/mobile`, `packages/shared`, código nativo iOS/Android, `.arb`, `Info.plist`, `AndroidManifest.xml` e documentação. Drift já é detectável no estado atual do repo:

- `apps/mobile/ios/Runner/Info.plist:10` declara `CFBundleDisplayName = "Raro Mobile"`.
- `packages/shared/lib/src/constants/app_identity.dart:4` declara `AppIdentity.displayName = 'Raro Camera'`.

Esses dois valores deveriam ser **o mesmo símbolo**, em um único arquivo, consumido por referência. Esta spec resolve isso para as 12 famílias simultaneamente:

1. **Identidade** — bundle ID, application ID, display name, versão
2. **Invariantes inegociáveis** — wake word `"Raro"`, free trial 30 dias, SKUs, entitlement, planos
3. **Bridge channels** — namespaces `com.rarocamera/{camera,replay_buffer,voice,volume}`
4. **Bridge métodos e eventos** — assinaturas Dart↔Swift↔Kotlin
5. **Enums de domínio** — Lens, Fps, Resolution, BufferDuration, ControlMode, AppLanguage
6. **Analytics event names** — 27 eventos atuais + futuros
7. **Analytics event params** — payload tipado por evento
8. **Screen / Modal IDs** — P01..P12, P05a, M01..M03
9. **Storage keys** — chaves de `shared_preferences`
10. **Permissions / Info.plist / Manifest** — keys + mensagens de uso
11. **Design tokens** — cores, gradientes, tipografia, radii, spacings, durações
12. **Copy literal** — strings de UI canônicas + termos proibidos

Sem este contrato, qualquer agente Claude/Codex pode introduzir drift por alucinação ao criar a próxima feature. **Com** este contrato, drift fica impossível por construção (codegen) ou detectado em CI antes do merge (gates).

## Sizing

- [x] **Large** — toca múltiplas features, exige ADR novo, adiciona Pigeon + Theme Tailor + custom hooks ao stack, materializa estrutura de `packages/shared`, e cria gates em hooks + CI.

## Q-table (todas respondidas — sem ambiguidade residual)

| # | Question | Answer |
|---|---|---|
| Q1 | Onde mora o schema Pigeon dos 4 bridges? | `apps/mobile/pigeons/{camera,replay_buffer,voice,volume}_api.dart`. Saídas Dart em `apps/mobile/lib/core/native_bridges/generated/`, Swift em `apps/mobile/ios/Runner/Native/Generated/`, Kotlin em `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/generated/`. |
| Q2 | Schemas Pigeon nascem vazios ou com métodos? | **Vazios** — só `@ConfigurePigeon`, namespace e classes `@HostApi()`/`@FlutterApi()` declaradas. Métodos entram nas specs de bridge específicas. |
| Q3 | Onde mora a fonte dos design tokens? | `apps/mobile/lib/core/theme/raro_theme.dart` com `@TailorMixin` → gera `raro_theme.tailor.dart`. Tokens: `RaroColors`, `RaroGradients`, `RaroTypography`, `RaroRadii`, `RaroSpacing`, `RaroDurations`. |
| Q4 | Onde moram as constantes de identidade/invariante/SKU/wake-word/storage/events? | `packages/shared/lib/src/<family>/*.dart`, todos exportados via barrel `packages/shared/lib/raro_shared.dart`. |
| Q5 | `AppScreen` enum vira fonte única de rotas + analytics screen names? | **Sim.** `enum AppScreen { p01Splash('/splash', 'splash'), p05Camera('/camera', 'camera'), ... }` com getters `path` e `analyticsName`. go_router consome `AppScreen.<id>.path`. |
| Q6 | Analytics payloads tipados — quão estritos? | Para cada evento com parâmetros, classe imutável em `AnalyticsPayloads` com `toMap()` retornando `Map<String, Object?>`. `FirebaseAnalytics.logEvent(name: AnalyticsEvents.recordingStarted, parameters: payload.toMap())`. **Nunca** map literal em widget. |
| Q7 | Gate de copy literal — quão estrito? | Detecta `'…'` ou `"…"` em arquivos `.dart` (excluindo `*.g.dart`, `*.tailor.dart`, `*.freezed.dart`, `_test.dart`) que: contém ≥ 1 espaço E ≥ 3 chars E não está em arquivo dentro de `core/theme/` ou `packages/shared/`. Exceções declaradas explicitamente em lista. |
| Q8 | Permissions/Info.plist/AndroidManifest — gerar ou só validar? | **Validar.** `permissions/permissions_contract.dart` lista keys + mensagens canônicas pt/en/es. Testes `info_plist_parity_test.dart` e `android_manifest_parity_test.dart` parseiam os arquivos nativos e comparam. |
| Q9 | `custom_lint` package ou só `dart test` estático? | **`dart test` estático** em `apps/mobile/test/contract/`. Decisão: evita overhead de codegen extra. Pode escalar para `custom_lint` em spec futura se um gate virar muito ruidoso. |
| Q10 | Correção do drift `"Raro Mobile"` entra aqui ou em spec separada? | **Aqui.** Esta spec só vale se o estado inicial é coerente. Step 12 do plano de execução. |
| Q11 | Onde fica a lista de termos proibidos e quem aplica? | Lista em `packages/shared/lib/src/contract/forbidden_terms.dart`. Triple gate: (a) `.claude/hooks/block-forbidden-terms.sh` PreToolUse, (b) teste estático `forbidden_literals_test.dart`, (c) `lefthook` pre-push. |
| Q12 | Versionamento do contrato? | Semver no `packages/shared/pubspec.yaml` + entrada em `docs/10-CHANGELOG.md` sob `## packages/shared`. Quebra (rename/remove) = bump major; adição compatível = minor. Documentado na seção "Como evoluir o contrato" abaixo. |

---

## Arquitetura — overview das 12 famílias

```
┌────────────────────────────────────────────────────────────────┐
│  packages/shared (Dart puro, sem Flutter)                      │
│  Barrel: lib/raro_shared.dart                                  │
│  ─────────────────────────────────────────────────────────     │
│  identity/         subscription/      voice/                    │
│  enums/            screens/           analytics/                │
│  storage/          bridges/           permissions/              │
│  contract/                                                      │
└────────────────────────────────────────────────────────────────┘
             ↑                              ↑
             │ import 'package:raro_shared/raro_shared.dart'
             │                              │
┌──────────────────────────────┐  ┌──────────────────────────────┐
│  apps/mobile/lib/core/theme  │  │  apps/mobile/pigeons/        │
│  raro_theme.dart             │  │  camera_api.dart             │
│  raro_theme.tailor.dart      │  │  replay_buffer_api.dart      │
│  raro_theme_data.dart        │  │  voice_api.dart              │
│  (Theme Tailor codegen)      │  │  volume_api.dart             │
└──────────────────────────────┘  └──────────────────────────────┘
                                              ↓ pigeon codegen
                                  ┌──────────────────────────────┐
                                  │  Dart  : lib/.../generated/  │
                                  │  Swift : ios/.../Generated/  │
                                  │  Kotlin: android/.../generated│
                                  └──────────────────────────────┘
```

Princípio fundamental: **se um identificador pode ser digitado em dois lugares diferentes, ou ele é gerado por codegen, ou está atrás de uma constante tipada em `raro_shared`, ou tem teste de paridade.**

---

## Famílias — materialização detalhada

### Família 1 — Identidade

**Arquivo canônico:** `packages/shared/lib/src/identity/app_identity.dart`

```dart
abstract final class AppIdentity {
  static const String displayName = 'Raro Camera';
  static const String bundleId = 'com.rarocamera';
  static const String applicationId = 'com.rarocamera';
  static const String version = '1.0.0';
  static const int build = 1;
}
```

**Espelhos validados:**
- `ios/Runner/Info.plist`: `CFBundleDisplayName`, `CFBundleIdentifier`, `CFBundleShortVersionString`, `CFBundleVersion`
- `android/app/build.gradle`: `applicationId`, `versionName`, `versionCode`
- `pubspec.yaml` (`apps/mobile`): `version`

**Gate:** `info_plist_parity_test.dart` + `android_manifest_parity_test.dart` (Família 10).

### Família 2 — Invariantes inegociáveis

**Arquivos canônicos:**
- `packages/shared/lib/src/voice/voice_config.dart` — `VoiceConfig.wakeWord = 'Raro'`
- `packages/shared/lib/src/subscription/subscription.dart` — `SubscriptionSkus.monthly/yearly`, `SubscriptionConfig.entitlement`, `SubscriptionConfig.freeTrialDays = 30`
- `packages/shared/lib/src/contract/forbidden_terms.dart` — lista de termos proibidos: `['OkCamera', 'Ok Camera', 'hey OkCamera', 'okCamera', 'ok_camera']`

**Teste obrigatório (já existe em `packages/shared/test/smoke_test.dart`, estender):**
```dart
test('wake word is "Raro" (never "OkCamera")', () => expect(VoiceConfig.wakeWord, 'Raro'));
test('free trial is 30 days', () => expect(SubscriptionConfig.freeTrialDays, 30));
test('SKUs match Blueprint Section 2.4', () {
  expect(SubscriptionSkus.monthly, 'raro_premium_monthly_BRL_9_90');
  expect(SubscriptionSkus.yearly, 'raro_premium_yearly_BRL_89_90');
});
```

**Gate:** termos proibidos validados em triple gate (hook + test estático + lefthook).

### Família 3 — Bridge channels (namespaces)

**Arquivo canônico:** `packages/shared/lib/src/bridges/bridge_channels.dart`

```dart
abstract final class BridgeChannels {
  static const String camera = 'com.rarocamera/camera';
  static const String replayBuffer = 'com.rarocamera/replay_buffer';
  static const String voice = 'com.rarocamera/voice';
  static const String volume = 'com.rarocamera/volume';
}
```

**Espelhos:** os 4 schemas Pigeon em `apps/mobile/pigeons/*.dart` declaram namespace cuja string deve casar com `BridgeChannels.<id>`.

**Gate:** `bridge_channels_parity_test.dart` faz regex parse dos `.dart` em `pigeons/` e compara com as constantes.

### Família 4 — Bridge métodos e eventos (Pigeon-driven)

**Estado nesta spec:** schemas **vazios** em `apps/mobile/pigeons/{camera,replay_buffer,voice,volume}_api.dart`. Estrutura mínima:

```dart
// apps/mobile/pigeons/camera_api.dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/core/native_bridges/generated/camera_api.g.dart',
  dartOptions: DartOptions(),
  swiftOut: 'ios/Runner/Native/Generated/CameraApi.g.swift',
  swiftOptions: SwiftOptions(),
  kotlinOut: 'android/app/src/main/kotlin/com/rarocamera/raro_mobile/generated/CameraApi.g.kt',
  kotlinOptions: KotlinOptions(package: 'com.rarocamera.raro_mobile.generated'),
  dartPackageName: 'raro_mobile',
))
@HostApi()
abstract class CameraHostApi {
  // Métodos serão adicionados pela spec feat/camera-native-bridge.
}

@FlutterApi()
abstract class CameraFlutterApi {
  // Callbacks de evento serão adicionados pela spec feat/camera-native-bridge.
}
```

**Idem** para `replay_buffer_api.dart`, `voice_api.dart`, `volume_api.dart` (com `dartOut`/`swiftOut`/`kotlinOut` ajustados).

**Saídas geradas** (commitadas para review):
- `apps/mobile/lib/core/native_bridges/generated/{camera,replay_buffer,voice,volume}_api.g.dart`
- `apps/mobile/ios/Runner/Native/Generated/{Camera,ReplayBuffer,Voice,Volume}Api.g.swift`
- `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/generated/{Camera,ReplayBuffer,Voice,Volume}Api.g.kt`

**Comando codegen** (registrado em `apps/mobile/package.json` script `pigeon`):
```bash
dart run pigeon --input pigeons/camera_api.dart
dart run pigeon --input pigeons/replay_buffer_api.dart
dart run pigeon --input pigeons/voice_api.dart
dart run pigeon --input pigeons/volume_api.dart
```

### Família 5 — Enums de domínio

**Arquivos canônicos** (já existentes em `packages/shared/lib/src/enums/`):
- `lens.dart` — `Lens.ultraWide('0.5x')`, `Lens.wide('1x')`
- `fps.dart` — `Fps.fps30(30)`, `Fps.fps60(60)`
- `resolution.dart` — `Resolution.hd720`, `fullHd1080`, `uhd4k`, `uhd4k60`
- `buffer_duration.dart` — `BufferDuration.seconds15(15)`, `seconds30(30)`
- `control_mode.dart` — `ControlMode.voice`, `volume`
- `app_language.dart` — `AppLanguage.ptBr`, `en`, `es`

**Política:** qualquer feature que precise representar lente, FPS, resolução, duração de buffer, modo de controle ou idioma **deve** importar do shared. Criar tipo local equivalente é violação.

**Gate:** `forbidden_literals_test.dart` detecta strings `'0.5x'`, `'1x'`, `'30fps'`, `'pt-BR'`, etc., fora de shared (com exceções para os próprios arquivos do enum e `.arb`).

### Família 6 — Analytics event names

**Arquivo canônico:** `packages/shared/lib/src/analytics/analytics_events.dart`

```dart
abstract final class AnalyticsEvents {
  static const String appOpen = 'app_open';
  static const String onboardingStarted = 'onboarding_started';
  // ... (27 eventos atuais + extensíveis)
}
```

**Gate:** `analytics_events_used_test.dart` varre `apps/mobile/lib/**/*.dart` por chamadas que casam regex `FirebaseAnalytics(\.[a-zA-Z]+)*\.logEvent\(`. Para cada match, exige que o argumento `name:` seja **identificador qualificado** começando com `AnalyticsEvents.`, nunca literal string.

### Família 7 — Analytics event params (payloads tipados)

**Arquivo canônico:** `packages/shared/lib/src/analytics/analytics_payloads.dart`

```dart
class RecordingStartedPayload {
  const RecordingStartedPayload({
    required this.lens,
    required this.resolution,
    required this.fps,
    required this.trigger,
    required this.bufferDuration,
  });

  final Lens lens;
  final Resolution resolution;
  final Fps fps;
  final ControlMode trigger;
  final BufferDuration bufferDuration;

  Map<String, Object?> toMap() => {
    'lens': lens.label,
    'resolution': resolution.label,
    'fps': fps.value,
    'trigger': trigger.name,
    'buffer_duration': bufferDuration.value,
  };
}

class PlanSelectedPayload {
  const PlanSelectedPayload({required this.sku});
  final String sku; // sempre vem de SubscriptionSkus.*
  Map<String, Object?> toMap() => {'sku': sku};
}

// ... uma classe por evento que carrega params.
```

**Política:** widget que dispara analytics **constrói o payload tipado** e chama `analytics.logEvent(name: AnalyticsEvents.x, parameters: payload.toMap())`. Sem map literal em widget.

### Família 8 — Screen / Modal IDs

**Arquivo canônico:** `packages/shared/lib/src/screens/app_screen.dart`

```dart
enum AppScreen {
  p01Splash('/splash', 'splash'),
  p02Onboarding1('/onboarding/1', 'onboarding_1'),
  p03Onboarding2('/onboarding/2', 'onboarding_2'),
  p04Permissions('/permissions', 'permissions'),
  p05Camera('/camera', 'camera'),
  p05aLockMode('/camera/lock', 'lock_mode'),
  p06Settings('/settings', 'settings'),
  p07Gallery('/gallery', 'gallery'),
  p08Preview('/preview', 'preview'),
  p09Paywall('/paywall', 'paywall'),
  p10Checkout('/checkout', 'checkout'),
  p11Terms('/terms', 'terms'),
  p12Privacy('/privacy', 'privacy');

  const AppScreen(this.path, this.analyticsName);
  final String path;
  final String analyticsName;
}

enum AppModal {
  m01SubscriptionPopup('subscription_popup'),
  m02XiaomiGuide('xiaomi_guide'),
  m03BluetoothControlDetected('bluetooth_control_detected');

  const AppModal(this.analyticsName);
  final String analyticsName;
}
```

**Consumo:**
- go_router em `apps/mobile/lib/core/routing/router.dart` itera `AppScreen.values` para registrar rotas.
- `FirebaseAnalytics.setCurrentScreen(screenName: AppScreen.p05Camera.analyticsName)`.

**Gate:** `screen_paths_unique_test.dart` garante que `AppScreen.values.map((s) => s.path)` é distinct, idem para `analyticsName`, idem para `AppModal.values.map((m) => m.analyticsName)`.

### Família 9 — Storage keys

**Arquivo canônico:** `packages/shared/lib/src/storage/storage_keys.dart`

```dart
abstract final class StorageKeys {
  static const String onboardingCompleted = 'raro.onboarding.completed';
  static const String selectedLanguage = 'raro.language.selected';
  static const String preferredResolution = 'raro.camera.resolution';
  static const String preferredFps = 'raro.camera.fps';
  static const String preferredBufferDuration = 'raro.replay.buffer_duration';
  static const String preferredControlMode = 'raro.control.mode';
  static const String xiaomiGuideShown = 'raro.xiaomi.guide_shown';
  static const String firstLaunchAt = 'raro.first_launch_at';
  static const String lastLanguageDetected = 'raro.language.detected';
}
```

**Política:** namespace `raro.<domain>.<key>` para evitar colisão futura. **Nenhuma** chamada `prefs.setX('literal')` em código de feature; sempre `prefs.setX(StorageKeys.x, ...)`.

**Gate:** `forbidden_literals_test.dart` detecta literais que parecem keys (regex `[a-z]+\.[a-z_]+\.[a-z_]+`) em chamadas `SharedPreferences` fora deste arquivo.

### Família 10 — Permissions / Info.plist / Manifest

**Arquivo canônico:** `packages/shared/lib/src/permissions/permissions_contract.dart`

```dart
abstract final class PermissionsContract {
  static const Map<String, PermissionMessage> ios = {
    'NSCameraUsageDescription': PermissionMessage(
      ptBr: 'A Raro Camera precisa da câmera para gravar vídeos.',
      en: 'Raro Camera needs the camera to record videos.',
      es: 'Raro Camera necesita la cámara para grabar videos.',
    ),
    'NSMicrophoneUsageDescription': PermissionMessage(
      ptBr: 'A Raro Camera precisa do microfone para capturar áudio.',
      en: 'Raro Camera needs the microphone to capture audio.',
      es: 'Raro Camera necesita el micrófono para capturar audio.',
    ),
    'NSSpeechRecognitionUsageDescription': PermissionMessage(
      ptBr: 'A Raro Camera usa reconhecimento de voz no dispositivo para detectar "Raro".',
      en: 'Raro Camera uses on-device speech recognition to detect "Raro".',
      es: 'Raro Camera usa reconocimiento de voz en el dispositivo para detectar "Raro".',
    ),
  };

  static const List<String> android = [
    'android.permission.CAMERA',
    'android.permission.RECORD_AUDIO',
  ];
}

class PermissionMessage {
  const PermissionMessage({required this.ptBr, required this.en, required this.es});
  final String ptBr;
  final String en;
  final String es;
}
```

**Gates:**
- `info_plist_parity_test.dart`: parseia `apps/mobile/ios/Runner/Info.plist`, exige que cada key em `PermissionsContract.ios` exista e que `CFBundleDisplayName == AppIdentity.displayName`, `CFBundleIdentifier == AppIdentity.bundleId`. (Mensagens em pt/en/es vivem em `InfoPlist.strings` per-locale — o teste só valida a key pt-BR default.)
- `android_manifest_parity_test.dart`: parseia `apps/mobile/android/app/src/main/AndroidManifest.xml`, exige que cada permission em `PermissionsContract.android` esteja declarada.

### Família 11 — Design tokens (Theme Tailor codegen)

**Arquivo canônico:** `apps/mobile/lib/core/theme/raro_theme.dart`

```dart
import 'package:flutter/material.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

part 'raro_theme.tailor.dart';

@TailorMixin()
class RaroColors extends ThemeExtension<RaroColors> with _$RaroColorsTailorMixin {
  const RaroColors({
    required this.bgDeep,
    required this.bgElev,
    required this.bgCard,
    required this.ink,
    required this.inkDim,
    required this.inkFaint,
    required this.border,
    required this.borderBright,
    required this.raroRed,
  });

  @override final Color bgDeep;
  @override final Color bgElev;
  @override final Color bgCard;
  @override final Color ink;
  @override final Color inkDim;
  @override final Color inkFaint;
  @override final Color border;
  @override final Color borderBright;
  @override final Color raroRed;

  static const RaroColors dark = RaroColors(
    bgDeep: Color(0xFF000000),
    bgElev: Color(0xFF0A0A0A),
    bgCard: Color(0xFF141414),
    ink: Color(0xFFFFFFFF),
    inkDim: Color(0xFFA3A3A3),
    inkFaint: Color(0xFF525252),
    border: Color(0xFF1F1F1F),
    borderBright: Color(0xFF2E2E2E),
    raroRed: Color(0xFFFF2D55),
  );
}

@TailorMixin()
class RaroGradients extends ThemeExtension<RaroGradients> with _$RaroGradientsTailorMixin {
  // raro (linear arco-íris CTAs), raroRadial (halos), raroRedRadial (toggle ON, slider thumb)
}

@TailorMixin()
class RaroTypography extends ThemeExtension<RaroTypography> with _$RaroTypographyTailorMixin {
  // Space Grotesk, Inter, JetBrains Mono — TextStyle por hierarquia (Blueprint 4.3)
}

@TailorMixin()
class RaroRadii extends ThemeExtension<RaroRadii> with _$RaroRadiiTailorMixin {
  // card 16, button 16, pill 999, chip 10, sheet 24, phone 50
}

@TailorMixin()
class RaroSpacing extends ThemeExtension<RaroSpacing> with _$RaroSpacingTailorMixin {
  // base 4, escala 2/4/8/12/16/20/24/28/40/48
}

@TailorMixin()
class RaroDurations extends ThemeExtension<RaroDurations> with _$RaroDurationsTailorMixin {
  // logoBreathe 3400ms, recPulse 1200ms, lensSwitchBlur 220ms, focusRing 1200ms, gradShift 5000ms, planHueSpin 6000ms
}
```

**ThemeData instalação:** `apps/mobile/lib/core/theme/raro_theme_data.dart` instala as 6 extensions em `ThemeData(extensions: [RaroColors.dark, RaroGradients.dark, ...])`.

**Consumo em widget:** `final colors = Theme.of(context).extension<RaroColors>()!;` → `Container(color: colors.raroRed)`.

**Gate:** `forbidden_literals_test.dart` detecta `Color(0xFF...)` fora de `apps/mobile/lib/core/theme/`.

### Família 12 — Copy literal canônica (`.arb`)

**Arquivos canônicos** (criação adiada para spec de i18n — esta spec só define **convenção de naming**):

`apps/mobile/lib/l10n/app_pt.arb` (estrutura alvo):

```json
{
  "@@locale": "pt",
  "p02_onboarding_title": "Grave sem tocar",
  "p02_onboarding_body": "Diga \"Raro\" para iniciar a gravação.",
  "p02_onboarding_cta_next": "Avançar",
  "p02_onboarding_cta_skip": "Pular",
  "p05_camera_hint_say_raro": "DIGA \"RARO\" PARA GRAVAR",
  "p09_paywall_title": "Escolha seu plano",
  "p09_paywall_subtitle_30days": "30 dias grátis",
  "p09_paywall_badge_best_offer": "MELHOR OFERTA",
  "p09_paywall_cta_subscribe": "Assinar agora",
  "p10_checkout_title": "Finalizar assinatura",
  "p10_checkout_cta_confirm": "Confirmar assinatura",
  "m01_subscription_popup_title": "Assinatura necessária",
  "m02_xiaomi_guide_title": "Otimização de bateria"
}
```

**Convenção:** `<screenOrModalId>_<section>_<role>`. Exemplos: `p05_camera_hint_say_raro`, `m02_xiaomi_guide_step_3_title`.

**Gate:** `forbidden_literals_test.dart` detecta `Text('<pt-BR>')` fora de `.arb`, com exceções declaradas (strings técnicas como `':'`, `'×'`, `'•'`, debug labels, asset paths).

---

## Enforcement (gates anti-drift)

### G1 — Hook PreToolUse `block-forbidden-terms.sh`

`.claude/hooks/block-forbidden-terms.sh` (modelo: copiar estrutura de `.claude/hooks/block-secrets.sh`):

- Trigger: PreToolUse Write/Edit/MultiEdit.
- Lê tool input via JSON em stdin.
- Bloqueia (exit code != 0 + mensagem) se `content` ou `new_string` contém qualquer termo de `ForbiddenTerms.all`.
- Registrado em `.claude/settings.json` no array `PreToolUse`.

### G2 — Test suite `apps/mobile/test/contract/`

Mínimo 6 testes verdes:

1. `forbidden_literals_test.dart` — termos proibidos, hex colors fora do tema, channel literals fora de bridges, SKU literals fora de subscription, storage key patterns fora de storage, copy literals em pt-BR fora de `.arb`.
2. `info_plist_parity_test.dart` — `CFBundleDisplayName`, `CFBundleIdentifier`, `CFBundleShortVersionString`, presença de `NSCameraUsageDescription`/`NSMicrophoneUsageDescription`/`NSSpeechRecognitionUsageDescription`.
3. `android_manifest_parity_test.dart` — permissions `CAMERA`/`RECORD_AUDIO`.
4. `analytics_events_used_test.dart` — todas chamadas `*.logEvent(name: ...)` usam `AnalyticsEvents.<const>`.
5. `screen_paths_unique_test.dart` — `AppScreen.values` e `AppModal.values` sem duplicação de `path`/`analyticsName`.
6. `bridge_channels_parity_test.dart` — regex parse dos 4 `pigeons/*.dart` extrai namespace e compara com `BridgeChannels.*`.

### G3 — lefthook pre-push

Em `lefthook.yml`, adicionar à seção `pre-push`:

```yaml
contract-tests:
  run: bun --filter @raro/mobile run test:contract
  glob: "{apps,packages,.claude,docs}/**/*"
```

E em `apps/mobile/package.json` adicionar script:
```json
"test:contract": "flutter test test/contract/"
```

### G4 — CI (futura)

Quando CI for ligado (spec posterior), pipeline rodará `bun run test` que cobre todos os contratos. Esta spec não cria GitHub Actions ainda — só prepara o terreno.

---

## Observable goals (critérios objetivos da Definition of Done)

- [ ] `bun --filter @raro/mobile run analyze` sem warnings.
- [ ] `bun --filter @raro/mobile run test` passa, incluindo suite `test/contract/` com **6+ testes verdes**.
- [ ] `bun --filter @raro/shared run test` passa com asserts de invariantes.
- [ ] `dart run pigeon --input pigeons/<each>.dart` executa sem erro para os 4 schemas.
- [ ] `bun --filter @raro/mobile run codegen` gera `raro_theme.tailor.dart` válido.
- [ ] `grep -r "Raro Mobile" apps/ packages/ docs/` retorna vazio.
- [ ] `grep -rE "OkCamera|Ok Camera|hey OkCamera|okCamera" apps/ packages/ docs/ .claude/` retorna vazio.
- [ ] Hook `block-forbidden-terms.sh` testado manualmente bloqueando inserção de `OkCamera`.
- [ ] ADR-013 mergeado em `docs/decisions/`.
- [ ] Blueprint atualizado nas Seções 2.2, 2.10, 9.
- [ ] `docs/10-CHANGELOG.md` atualizado.
- [ ] App buildando localmente em iOS Simulator e Android Emulator (`flutter build ios --no-codesign --debug` + `flutter build apk --debug`).

---

## UI / protótipo

Esta spec não introduz tela nova. Os tokens da Família 11 são extraídos do protótipo `docs/briefing/prototype/Prototipo-RARO.html` (bloco `:root`) e do Blueprint Seção 4. Validação visual entra nas specs de tela.

---

## Out of scope (explícito)

- Implementação dos métodos dos bridges (Camera/Replay/Voice/Volume). Esta spec só estabelece o **namespace** e **schema vazio**. Métodos vêm em `feat/camera-native-bridge`, `feat/replay-buffer-native-bridge`, etc.
- Conteúdo final dos `.arb` (pt/en/es). Esta spec define **convenção de naming de chaves** e o gate; tradução completa entra em `feat/i18n-arb-files`.
- Widgetbook / catálogo visual dos tokens. Overkill agora. Reabrir em spec futura se o time precisar.
- White-label / multi-tenant.
- `custom_lint` package separado. Pode ser introduzido em spec futura se algum gate `dart test` virar muito ruidoso.
- GitHub Actions CI completo. Esta spec deixa lefthook + scripts prontos; pipeline CI entra em `feat/ci-pipeline`.
- Geração automática a partir de Figma. Tokens nascem do protótipo HTML; migração manual de 1x.

---

## Risks & mitigations

| Risco | Mitigação |
|---|---|
| Pigeon codegen falha na configuração inicial (versão, paths, package name Kotlin) | ADR-013 fixa versões via Context7/pub.dev API no momento da implementação. Primeiro commit do schema vazio + saídas valida pipeline antes de qualquer método ser declarado. |
| Theme Tailor + `alchemist` goldens podem ter conflito em `lerp` | Manter `lerp` default gerado. Só customizar se golden test exigir. |
| Gate de copy literal (≥3 chars com espaço) gera falso positivo em strings técnicas | Lista de exceções explícita em `forbidden_literals_test.dart`, com comentário `// ALLOWED: motivo` no match. Documentada na spec. |
| Reorganização de `packages/shared` quebra imports em `apps/mobile` | Barrel `raro_shared.dart` re-exporta tudo. Mudança em cliente fica em **1 linha de import**. Smoke test pega regressão. |
| `Info.plist` drift correction quebra builds existentes (XCode cache) | Após correção, rodar `flutter clean && flutter build ios --no-codesign --debug` local. CHANGELOG explicita user-facing display name. |
| Versão de Pigeon ou Theme Tailor muda API entre `pub get` e merge | ADR-013 versiona explicitamente. Renovate/dependabot fora de escopo nesta spec. |
| Codegen output (`*.g.dart`, `*.tailor.dart`, `*.g.swift`, `*.g.kt`) gera muito noise em PR | Commitados intencionalmente para review humano. Spec futura pode optar por gitignore + CI gera. Por ora: visibilidade > ruído. |

---

## ADRs necessários

- [x] ADR existente: **0001** stack inicial — referenciado, sem mudança
- [x] ADR existente: **0009** wake word `"Raro"` — referenciado, sem mudança
- [x] ADR existente: **0010** modelo dual de assinatura — referenciado, sem mudança
- [ ] ADR novo: **0013** — Pigeon + Theme Tailor + gates anti-drift (criar junto desta spec, commit separado)

---

## Como evoluir o contrato (governança)

1. **Adição compatível** (novo evento analytics, nova storage key, novo screen): bump `minor` em `packages/shared/pubspec.yaml`, entrada em `docs/10-CHANGELOG.md` sob `## packages/shared`. PR normal.
2. **Quebra de contrato** (rename, remove, mudar tipo de campo): bump `major`. PR exige:
   - ADR explicando motivo
   - migration notes em `docs/10-CHANGELOG.md`
   - todos os consumers atualizados no mesmo PR (monorepo permite atomic change)
3. **Novo bridge** (e.g. `com.rarocamera/<novo>`): adicionar em `BridgeChannels`, criar `pigeons/<novo>_api.dart`, rodar codegen. Spec dedicada para os métodos.
4. **Termo proibido novo**: adicionar em `forbidden_terms.dart`. Triple gate detecta automaticamente.
5. **Token de design novo**: adicionar campo em `RaroColors`/`RaroGradients`/etc., rodar codegen Theme Tailor. Spec do design system pode validar com goldens.

Quem é guardião do contrato: **`adr-guardian` subagent** (Fase 4) avisa quando mudança toca pubspec/Blueprint/native_bridges sem ADR novo no branch.

---

## References

- Briefing: `docs/briefing/original-briefing.md` Seções 3.2, 5, 6
- Blueprint: `docs/Blueprint.md` Seções 1, 2, 4, 5, 9
- ADRs ativos: 0001, 0009, 0010
- ADR a criar nesta spec: 0013
- Protótipo: `docs/briefing/prototype/Prototipo-RARO.html` (`:root` + screen registry)
- Pigeon docs oficial: https://docs.flutter.dev/platform-integration/platform-channels
- Pigeon pub.dev: https://pub.dev/packages/pigeon
- Theme Tailor: https://pub.dev/packages/theme_tailor
- ThemeExtension API: https://api.flutter.dev/flutter/material/ThemeExtension-class.html
- Migrating to Pigeon (Invertase): https://invertase.io/blog/migrating-flutter-plugins-to-pigeon-lessons-learned
- Spec scaffold criado em: 2026-05-25 via `/new-spec api-contract-shared`
- Brainstorming concluído em: 2026-05-26 via `superpowers:brainstorming`
- Plan file: `~/.claude/plans/aprovo-siga-as-boas-declarative-swing.md`
