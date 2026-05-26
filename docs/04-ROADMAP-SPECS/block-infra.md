# Bloco Infra — specs 002 a 005

> 4 specs de infraestrutura paralelizáveis (todas dependem só da spec-001 API contract). Sem essas, features de produto não conseguem rodar. Cada spec abaixo é independente — podem ser implementadas em qualquer ordem após 001.

## spec-002 — firebase-init

| Campo | Valor |
|---|---|
| **Sizing** | Medium |
| **Dependências** | spec-001 (api contract) |
| **Bloqueia** | spec-007 (camera-native-bridge), spec-013 (paywall) — porque analytics events precisam disparar do dia 1 |
| **Branch sugerido** | `chore/firebase-init` |
| **Telas afetadas** | Nenhuma (config nativa) |

### Problem

Bootstrap declarou `firebase_core ^4.9.0`, `firebase_analytics ^12.4.1`, `firebase_crashlytics ^5.2.2` em `pubspec.yaml` mas:
- `google-services.json` (Android) e `GoogleService-Info.plist` (iOS) não estão no repo (corretamente — vêm da conta Firebase do cliente)
- Não há `Firebase.initializeApp()` no boot
- `AnalyticsEvents` consts existem em shared mas não há `FirebaseAnalytics` wrapper que as consuma

### Atomic micro-sprints

#### 2.1 — Onboarding Firebase do cliente (não é código)

**Entregar:**
- Documento `docs/setup/firebase-onboarding.md` instruindo o cliente passo-a-passo a criar projeto Firebase com bundle ID `com.rarocamera`, adicionar apps iOS + Android, baixar configs
- Adicionar `google-services.json` e `GoogleService-Info.plist` ao `.gitignore` (verificar — já está coberto pelo bloqueio do hook `block-env`, mas confirmar no .gitignore explícito)

**Verification:**
- Documento existe e é navegável
- `git check-ignore google-services.json GoogleService-Info.plist` retorna sucesso

**Commit:** `docs(deps): firebase onboarding guide para cliente — spec-002 µ-sprint 2.1`

#### 2.2 — `FirebaseBootstrapService` em shared (interface)

**Files:**
- `packages/shared/lib/src/services/firebase_bootstrap_contract.dart` — abstract interface
- `packages/shared/test/services/firebase_bootstrap_contract_test.dart`

**Verification:**
- `dart test packages/shared` verde
- Interface não importa Flutter (Dart puro)

**Commit:** `feat(shared): firebase bootstrap contract — spec-002 µ-sprint 2.2`

#### 2.3 — Implementação Flutter do bootstrap

**Files:**
- `apps/mobile/lib/core/firebase/firebase_bootstrap.dart` — usa `firebase_core`
- `apps/mobile/lib/core/firebase/firebase_analytics_service.dart` — consome `AnalyticsEvents`
- `apps/mobile/lib/core/firebase/firebase_crashlytics_service.dart`
- `apps/mobile/lib/main.dart` — chama `Firebase.initializeApp()` antes do `runApp` + **3 handlers obrigatórios** (não 1):
  - `FlutterError.onError` → erros síncronos do framework
  - `PlatformDispatcher.instance.onError` → erros assíncronos não tratados
  - `Isolate.current.addErrorListener(...)` → erros em isolates (replay buffer pode usar)
- `apps/mobile/test/core/firebase/firebase_services_test.dart` — usa mocktail

**Verification:**
- `flutter analyze apps/mobile` zero
- `flutter test apps/mobile` verde (mocks de Firebase)
- App roda no simulator sem crash mesmo sem configs reais (graceful no-op em dev)
- Teste manual: throw uncaught exception em Future → aparece no Crashlytics console
- Teste manual: throw em isolate → aparece também (sem isolate listener, some)

**Commit:** `feat(analytics): firebase init + analytics + crashlytics com 3 error handlers — spec-002 µ-sprint 2.3`

> **Aprendizado validado via Context7 docs/firebase/flutterfire (2026-05-25):** sem os 3 handlers (especialmente `PlatformDispatcher.instance.onError` e `Isolate.current.addErrorListener`), erros async e em isolates somem. **Não usar `runZonedGuarded`** — abordagem legada substituída por `PlatformDispatcher.instance.onError` desde Flutter 3.3+.

#### 2.4 — ADR + CHANGELOG

**Files:**
- `docs/decisions/0014-firebase-bootstrap-strategy.md` — decisão de quando init (eager vs lazy), tratamento de configs ausentes em dev
- `docs/10-CHANGELOG.md` (entry)

**Verification:**
- `adr-guardian` confirma ADR cobre mudança
- `docs-lint` zero issues

**Commit:** `docs(blueprint): adr 0014 firebase bootstrap strategy — spec-002 µ-sprint 2.4`

### Gates

- `warn-adr-drift` dispara em `pubspec.yaml` (mas não vai mudar — só usa o que já está)
- `block-env` protege `google-services.json` e `GoogleService-Info.plist`
- `flutter-test-author` invocado para mocks de Firebase
- `researcher` confirma SDK 4.9.0 ainda current via Context7 antes de implementar

---

## spec-003 — revenuecat-init

| Campo | Valor |
|---|---|
| **Sizing** | Medium |
| **Dependências** | spec-001 (Plan, Entitlement, SubscriptionStatus types) |
| **Bloqueia** | spec-013 (paywall), spec-014 (checkout) |
| **Branch sugerido** | `chore/revenuecat-init` |
| **Telas afetadas** | Nenhuma (config nativa + SDK init) |

### Problem

`purchases_flutter ^10.1.1` declarado em `pubspec.yaml`, SKUs definidos em `shared/SubscriptionSkus`, mas:
- `Purchases.configure()` não é chamado
- API key do RevenueCat ausente (esperado — vem do cliente)
- Sem listener para `CustomerInfo` updates
- Sem mapeamento `purchases_flutter` types → `shared/Plan`/`Entitlement`

### Atomic micro-sprints

#### 3.1 — Onboarding RevenueCat do cliente

**Entregar:**
- `docs/setup/revenuecat-onboarding.md` instruindo o cliente a criar projeto, configurar offerings `monthly` + `yearly`, conectar Apple/Google billing, gerar API keys
- `.env.example` com placeholders `REVENUECAT_API_KEY_IOS=` e `REVENUECAT_API_KEY_ANDROID=`

**Verification:**
- Doc existe
- `.env.example` no repo, `.env` bloqueado por `block-env`

**Commit:** `docs(deps): revenuecat onboarding guide + .env.example — spec-003 µ-sprint 3.1`

#### 3.2 — `SubscriptionService` contract em shared

**Files:**
- `packages/shared/lib/src/services/subscription_service_contract.dart` — interface com `init()`, `purchase(Plan)`, `restore()`, `currentEntitlement()`, `subscriptionStatusStream()`
- `packages/shared/test/services/subscription_contract_test.dart`

**Verification:**
- Contract consome `Plan`, `Entitlement`, `SubscriptionStatus`, `SubscriptionSku` (todos de shared, sem duplicação)
- `dart test` verde

**Commit:** `feat(shared): subscription service contract — spec-003 µ-sprint 3.2`

#### 3.3 — Implementação RevenueCat

**Files:**
- `apps/mobile/lib/core/subscription/revenuecat_subscription_service.dart`
- `apps/mobile/lib/core/subscription/subscription_provider.dart` — Riverpod `@riverpod` provider
- `apps/mobile/lib/core/subscription/purchases_error_mapper.dart` — converte `PlatformException` → `SubscriptionError` sealed (de `packages/shared`) usando `PurchasesErrorHelper.getErrorCode`
- `apps/mobile/test/core/subscription/revenuecat_service_test.dart` com mocktail
- `apps/mobile/test/core/subscription/purchases_error_mapper_test.dart` — cobre 8+ casos de `PurchasesErrorCode`

**Padrão de erro obrigatório (validado via Context7 pub.dev purchases_flutter 2026-05-25):**

```dart
try {
  await Purchases.purchasePackage(package);
} on PlatformException catch (e) {
  final code = PurchasesErrorHelper.getErrorCode(e);
  switch (code) {
    case PurchasesErrorCode.purchaseCancelledError: // user cancelou — UI silenciosa
    case PurchasesErrorCode.networkError:           // retry com backoff
    case PurchasesErrorCode.paymentPendingError:    // family sharing aguarda aprovação
    case PurchasesErrorCode.purchaseNotAllowedError:// parental controls bloqueou
    // ... mapeia para SubscriptionError sealed de shared
  }
}
```

**Verification:**
- `flutter analyze` zero
- `flutter test` verde
- `flutter pub get` resolve `purchases_flutter` corretamente
- Codegen via `bun --filter @raro/mobile run codegen` gera `.g.dart`
- `run-riverpod-codegen` hook sinaliza após `@riverpod` editado
- Mapper cobre ≥8 `PurchasesErrorCode` (cancelled, network, paymentPending, notAllowed, productAlreadyPurchased, storeProblem, configuration, unknown)

**Commit:** `feat(subscription): revenuecat service + riverpod provider + purchases error mapper — spec-003 µ-sprint 3.3`

#### 3.4 — ADR + CHANGELOG

**Files:**
- `docs/decisions/0015-revenuecat-bootstrap-strategy.md`
- `docs/10-CHANGELOG.md`

**Verification:**
- ADR cobre decisão de quando configure() (no boot vs lazy), tratamento sem API key (modo dev)
- `docs-lint` zero

**Commit:** `docs(blueprint): adr 0015 revenuecat strategy — spec-003 µ-sprint 3.4`

### Gates

- `warn-adr-drift` em `pubspec.yaml`/`.env.example`
- `block-secrets` protege API keys reais
- `run-riverpod-codegen` em `subscription_provider.dart`
- `researcher` confirma `purchases_flutter 10.1.1` ainda current

---

## spec-004 — theme-design-tokens

| Campo | Valor |
|---|---|
| **Sizing** | Quick |
| **Dependências** | spec-001 (RaroColor, RaroGradient, RaroFontFamily enums) |
| **Bloqueia** | spec-006 (splash), e indiretamente toda spec com UI |
| **Branch sugerido** | `chore/theme-design-tokens` |
| **Telas afetadas** | Nenhuma direto, mas habilita todas |

### Problem

`RaroColor`, `RaroGradient`, `RaroFontFamily` são enums em shared mas sem valores Flutter. Cada feature que renderiza UI precisaria importar `dart:ui` Color() inline. Precisa de uma camada Flutter que mapeie cada token enum para seu valor real, extraído do `:root` do protótipo.

### Atomic micro-sprints

#### 4.1 — Mapeamento de tokens

**Files:**
- `apps/mobile/lib/core/theme/raro_tokens.dart` — Map `<RaroColor, Color>`, `<RaroGradient, Gradient>`, `<RaroFontFamily, String>`
- `apps/mobile/test/core/theme/tokens_test.dart`

**Tipos:**

```dart
const Map<RaroColor, Color> raroColors = {
  RaroColor.bgDeep: Color(0xFF000000),
  RaroColor.bgElev: Color(0xFF0a0a0a),
  // ... (do Blueprint Seção 4.1)
};

final Map<RaroGradient, Gradient> raroGradients = {
  RaroGradient.linear7Colors: LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFff2d55), Color(0xFFff6b35), Color(0xFFffcc00), Color(0xFF34c759), Color(0xFF00c7be), Color(0xFF007aff), Color(0xFFaf52de)],
    stops: [0.0, 0.16, 0.33, 0.5, 0.66, 0.83, 1.0],
  ),
  // ... (do Blueprint Seção 4.2)
};
```

**Verification:**
- Cobertura completa: para cada enum value em shared, há mapping em mobile (teste de exhaustive)
- Valores hex batem exatamente com `:root` do protótipo
- `design-fidelity-checker` invocado para validar contra `Prototipo-RARO.html`

**Commit:** `feat(theme): raro_tokens com cores/gradients/fontes do protótipo — spec-004 µ-sprint 4.1`

#### 4.2 — `RaroTheme` Flutter `ThemeData`

**Files:**
- `apps/mobile/lib/core/theme/raro_theme.dart` — `ThemeData` configurado com tokens
- `apps/mobile/lib/app.dart` — usar `RaroTheme.dark()` em vez de `ThemeData(brightness: dark)` inline
- `apps/mobile/test/core/theme/theme_test.dart`

**Hard rule — NÃO usar `ColorScheme.fromSeed` neste tema.**

Validado via Context7 docs Flutter (2026-05-25): `material_color_utilities` muda algoritmos entre versões do Flutter (`v0.11.1` → `v0.13.0` mudou `onPrimaryContainer`, `onSecondaryContainer`, etc.). Como o protótipo Claude Design dita cores literais (Blueprint Seção 4.1 — 9 cores hex específicas + 3 gradientes), derivar via seed é fonte garantida de drift visual a cada bump do Flutter.

Definir `ColorScheme` manual com cores literais do protótipo:

```dart
const _darkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFff2d55),       // raroRed
  onPrimary: Color(0xFFFFFFFF),
  secondary: Color(0xFFff6b35),     // raroOrange (gradient stop)
  onSecondary: Color(0xFF000000),
  surface: Color(0xFF0a0a0a),       // bg-elev
  onSurface: Color(0xFFFFFFFF),     // ink
  error: Color(0xFFff2d55),
  onError: Color(0xFFFFFFFF),
);
```

**Verification:**
- `flutter analyze` zero
- `flutter test` verde (existing smoke test continua passando)
- App renderiza com bg preto + texto branco como antes
- Grep no diff confirma zero ocorrências de `ColorScheme.fromSeed`
- `design-fidelity-checker` valida que cores literais batem com `:root` do protótipo

**Commit:** `refactor(theme): RaroTheme com colorscheme literal sem fromseed — spec-004 µ-sprint 4.2`

### Gates

- `design-fidelity-checker` valida tokens contra `Prototipo-RARO.html`
- `format-dart` em todos arquivos novos
- Existing smoke test não pode quebrar

---

## spec-005 — native-fonts

| Campo | Valor |
|---|---|
| **Sizing** | Quick |
| **Dependências** | spec-004 (RaroFontFamily enum mapeado) |
| **Bloqueia** | spec-006 (splash usa Space Grotesk bold), e qualquer tela com tipografia |
| **Branch sugerido** | `chore/native-fonts` |
| **Telas afetadas** | Nenhuma direto, mas habilita display tipográfico do protótipo |

### Problem

Pubspec declara `assets/fonts/.gitkeep` mas TTFs reais (Space Grotesk, Inter, JetBrains Mono) não existem. No µ-sprint 2.2 do bootstrap, fontes foram removidas do pubspec porque arquivos não existiam — foi adiado para esta spec.

### Atomic micro-sprints

> **Decisão técnica registrada (Context7 2026-05-25):** NÃO usar package `google_fonts ^8.1.0` — esse package faz HTTP fetch runtime no primeiro uso (cache local depois). Para app de captura em campo (offline-first), bundlar TTFs locais é correto: latência zero, sem dependência de internet, sem privacy concern (Google CDN tracking). Tamanho marginal (~500KB total para 11 TTFs).

#### 5.1 — Download e licenças

**Entregar:**
- `apps/mobile/assets/fonts/SpaceGrotesk-{Regular,Medium,SemiBold,Bold}.ttf` (SIL Open Font Licence 1.1)
- `apps/mobile/assets/fonts/Inter-{Regular,Medium,SemiBold,Bold}.ttf` (SIL Open Font Licence 1.1)
- `apps/mobile/assets/fonts/JetBrainsMono-{Regular,Medium,Bold}.ttf` (Apache License 2.0)
- `docs/setup/font-licenses.md` — atribuição completa com texto da licença + URL do repositório oficial
- **Source:** baixar dos repositórios oficiais (Space Grotesk: `floriankarsten/space-grotesk`, Inter: `rsms/inter`, JetBrains Mono: `JetBrains/JetBrainsMono`) ou Google Fonts download — NÃO usar package `google_fonts`

**Verification:**
- 11 arquivos `.ttf` no diretório
- Cada um abre em font viewer (não corrompido)
- Doc de licença existe e atribui corretamente com URLs
- `pubspec.yaml` NÃO tem `google_fonts` como dependência

**Commit:** `chore(theme): adiciona fontes space grotesk + inter + jetbrains mono bundled + licenças — spec-005 µ-sprint 5.1`

#### 5.2 — Reativa declaração em pubspec

**Files:**
- `apps/mobile/pubspec.yaml` — restaura bloco `fonts:` removido no bootstrap µ-sprint 2.2
- `apps/mobile/test/core/theme/fonts_loaded_test.dart` — widget test que confirma fontes carregam

**Verification:**
- `flutter pub get` resolve sem erro de "asset not found" (que foi o motivo da remoção)
- `flutter test` verde (incluindo novo test de fontes)
- `flutter analyze` zero

**Commit:** `feat(theme): reativa declaração de fontes em pubspec — spec-005 µ-sprint 5.2`

### Gates

- `warn-adr-drift` em `pubspec.yaml` — mas é restauração de algo declarado no Blueprint Seção 4.3, não precisa ADR novo
- `flutter-test-author` para teste de font loading
- ADR existente (Blueprint Seção 4.3) cobre a decisão

---

## Validação cruzada do bloco infra

Após 002 + 003 + 004 + 005 mergeados:

- [ ] `bun run lint && typecheck && test` zero issues
- [ ] Firebase services importáveis de `apps/mobile/lib/core/firebase/`
- [ ] Subscription service importável de `apps/mobile/lib/core/subscription/`
- [ ] `RaroTheme.dark()` aplicado em `app.dart`, todas cores via `RaroColor` enum
- [ ] 11 TTFs em `assets/fonts/`, fontes declaradas em pubspec, render no simulator confere com protótipo
- [ ] ADRs 0014 e 0015 mergeados, ADR existente do Blueprint Seção 4 referenciado
- [ ] CHANGELOG tem 4 entries (uma por spec do bloco)
- [ ] Smoke test inicial do mobile continua verde
- [ ] Session log do bloco em `docs/sessions/`
