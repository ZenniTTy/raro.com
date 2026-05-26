# api-contract-shared Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Estabelecer o contrato anti-drift do RARO materializando 12 famílias de identificadores em fontes únicas (Dart shared package, Pigeon schemas, Theme Tailor codegen) com 6 gates automáticos que falham CI ao primeiro drift.

**Architecture:** Single source of truth por família. `packages/shared` (Dart puro) abriga identidade, invariantes, enums, eventos analytics, payloads tipados, screen/modal IDs, storage keys, bridge channel namespaces, permissions, termos proibidos. `apps/mobile/pigeons/` abriga 4 schemas Pigeon vazios que geram código Dart+Swift+Kotlin sincronizado. `apps/mobile/lib/core/theme/` abriga 4 `ThemeExtension` gerados por Theme Tailor. Gates Dart estáticos em `apps/mobile/test/contract/` + hook PreToolUse + lefthook pre-push impedem drift.

**Tech Stack:** Flutter 3.41+, Dart 3.11+, `pigeon ^26.3.4`, `theme_tailor ^3.1.3`, `theme_tailor_annotation ^3.1.3`, `build_runner ^2.15.0`, `xml ^6.5.0` (parse Info.plist/AndroidManifest), `path ^1.9.0`, monorepo Bun + Turborepo, lefthook + commitlint.

**Reference:** spec `docs/superpowers/specs/2026-05-25-api-contract-shared-design.md` (Approved 2026-05-26).

---

## 7 execution rules (sempre aplicar)

1. **Surgical changes** — só toque no que a task pede. Sem refactor de passagem.
2. **Sem comentários** em código de produção. Nomes explicam WHAT.
3. **Imports absolutos** via `package:raro_mobile/...` ou `package:raro_shared/...`. Sem `../../../`.
4. **Riverpod 3 codegen** — `@riverpod` annotation quando aplicável. Não há provider nesta spec, mas a regra continua.
5. **Strict lints** — `flutter analyze` zero issues após cada arquivo modificado.
6. **Strings de UI em `.arb`** — sem inline. Esta spec não cria `.arb`, mas estabelece convenção.
7. **Conventional Commits** — scope do scope-enum em `commitlint.config.cjs`. Subject lowercase. Sem `--no-verify`.

## Phase 0 — pre-flight (bloqueante)

- [x] Spec lida integralmente, status `Approved`
- [x] Q-table preenchida (12 Q&A, sem `?`)
- [x] Sizing definido: **Large**
- [x] Plano aprovado em `~/.claude/plans/aprovo-siga-as-boas-declarative-swing.md`
- [x] Versões Pigeon/Theme Tailor verificadas via pub.dev API em 2026-05-26 (pigeon 26.3.4, theme_tailor 3.1.3)
- [ ] Branch `feat/api-contract-shared` criado a partir de `develop`
- [ ] Hooks lefthook + .claude/hooks/ instalados (`./setup.sh` já rodado no bootstrap)

---

## File Structure (decomposição)

**`packages/shared/lib/`** — Dart puro, sem Flutter:

```
raro_shared.dart                          # barrel export
src/
├── identity/app_identity.dart            # AppIdentity
├── voice/voice_config.dart               # VoiceConfig (mover de constants/)
├── subscription/subscription.dart        # SKUs + config (mover de constants/)
├── enums/
│   ├── lens.dart                         # já existe
│   ├── fps.dart                          # já existe
│   ├── resolution.dart                   # já existe
│   ├── buffer_duration.dart              # já existe
│   ├── control_mode.dart                 # já existe
│   └── app_language.dart                 # já existe
├── screens/app_screen.dart               # AppScreen + AppModal enums
├── analytics/
│   ├── analytics_events.dart             # mover de events/
│   └── analytics_payloads.dart           # payloads tipados
├── storage/storage_keys.dart             # StorageKeys
├── bridges/bridge_channels.dart          # BridgeChannels namespaces
├── permissions/permissions_contract.dart # PermissionsContract + PermissionMessage
└── contract/forbidden_terms.dart         # ForbiddenTerms.all
```

**`apps/mobile/pigeons/`** — Pigeon schemas vazios (com 1 método stub cada):

```
camera_api.dart
replay_buffer_api.dart
voice_api.dart
volume_api.dart
```

**`apps/mobile/lib/core/`** — código Flutter:

```
core/
├── theme/
│   ├── raro_theme.dart                   # @TailorMixin classes
│   ├── raro_theme.tailor.dart            # GENERATED (commitar)
│   └── raro_theme_data.dart              # ThemeData install
└── native_bridges/generated/             # GENERATED Pigeon Dart (commitar)
    ├── camera_api.g.dart
    ├── replay_buffer_api.g.dart
    ├── voice_api.g.dart
    └── volume_api.g.dart
```

**`apps/mobile/test/contract/`** — 6 testes de gate:

```
test/contract/
├── forbidden_literals_test.dart
├── info_plist_parity_test.dart
├── android_manifest_parity_test.dart
├── analytics_events_used_test.dart
├── screen_paths_unique_test.dart
└── bridge_channels_parity_test.dart
```

**Native generated (commitar):**
- `apps/mobile/ios/Runner/Native/Generated/{Camera,ReplayBuffer,Voice,Volume}Api.g.swift`
- `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/generated/{Camera,ReplayBuffer,Voice,Volume}Api.g.kt`

**Hooks:**
- `.claude/hooks/block-forbidden-terms.sh` (novo)
- `.claude/settings.json` (registrar hook)

**Docs:**
- `docs/decisions/0013-pigeon-theme-tailor-and-anti-drift-gates.md` (novo ADR)
- `docs/Blueprint.md` (atualizar Seções 2.2, 2.10, 9)
- `docs/10-CHANGELOG.md` (entrada datada)
- `docs/sessions/` (session log + INDEX update)

**Drift fix:**
- `apps/mobile/ios/Runner/Info.plist` — `Raro Mobile` → `Raro Camera`

---

## Atomic tasks

### Task 1: Criar branch + ADR-013

**Files:**
- Create: `docs/decisions/0013-pigeon-theme-tailor-and-anti-drift-gates.md`

- [ ] **Step 1: Criar branch**

```bash
git checkout develop
git pull --rebase
git checkout -b feat/api-contract-shared
```

Expected: `Switched to a new branch 'feat/api-contract-shared'`

- [ ] **Step 2: Escrever ADR-013**

Create `docs/decisions/0013-pigeon-theme-tailor-and-anti-drift-gates.md`:

```markdown
# ADR-0013 — Pigeon + Theme Tailor + gates anti-drift como contrato canônico

- **Status:** Accepted
- **Date:** 2026-05-26
- **Spec:** docs/superpowers/specs/2026-05-25-api-contract-shared-design.md
- **Supersedes:** parcialmente ADR-0002 (descrição original dos Method Channels como strings JSON manuais)

## Context

O Blueprint 2026-05-25 listou 4 Method Channels (`com.rarocamera/{camera,replay_buffer,voice,volume}`) descritos como contratos JSON-serializáveis manuais (Seção 2.2). Após brainstorming da spec `api-contract-shared` (2026-05-26), ficou evidente que:

1. Strings de namespace duplicadas em Dart + Swift + Kotlin são fonte garantida de drift por alucinação de agentes Claude/Codex.
2. Design tokens (cores, gradients, tipografia) declarados como constantes soltas permitem `Color(0xFFFF2D55)` literal em widget, fugindo da fonte canônica.
3. Identificadores de domínio (event names, screen IDs, storage keys, SKUs, wake word) precisam de gates automáticos que falhem o build na primeira divergência.

## Decision

Adotamos três mecanismos complementares:

1. **Pigeon ^26.3.4** para Method Channels — schemas Dart únicos em `apps/mobile/pigeons/*.dart` geram código tipado em Dart + Swift + Kotlin sincronizado. Elimina por construção o drift de namespace e assinaturas.
2. **Theme Tailor ^3.1.3** (+ `theme_tailor_annotation ^3.1.3`) para design tokens — classes `@TailorMixin` em `apps/mobile/lib/core/theme/raro_theme.dart` geram `ThemeExtension` tipadas. Consumo via `Theme.of(context).extension<RaroColors>()!`. `Color(0xFF...)` fora de `core/theme/` vira erro de teste.
3. **Triple-gate anti-drift** para invariantes de marca e identificadores:
   - (a) Hook PreToolUse `.claude/hooks/block-forbidden-terms.sh` bloqueia `OkCamera`, `Ok Camera`, `hey OkCamera` em qualquer Write/Edit/MultiEdit.
   - (b) Suite `apps/mobile/test/contract/` (6 testes mínimos) varre o repo com regex e falha em drift.
   - (c) `lefthook` pre-push roda `bun --filter @raro/mobile run test:contract`.

Versões fixadas via pub.dev API consulta em 2026-05-26.

## Consequences

**Positivo:**
- Drift de namespace de bridge fica impossível (codegen).
- Drift de cor/gradient fica impossível (ThemeExtension tipada).
- Drift de event name, screen ID, storage key, SKU detectado em CI antes do merge.
- Specs de bridges subsequentes (camera, replay, voice, volume) só editam schema Pigeon — nunca strings de channel.

**Negativo:**
- Adiciona Pigeon + Theme Tailor + build_runner ao stack (deps + tempo de codegen).
- Arquivos gerados commitados aumentam volume de PR (decisão consciente: visibilidade > ruído).
- Reorganização de `packages/shared` (constants/ → identity/voice/subscription/) exige atualizar imports.

**Neutro:**
- Renovate/dependabot fora de escopo desta ADR. Versões revisadas manualmente em specs futuras de upgrade.

## Alternatives considered

- **MethodChannel cru com strings** — rejeitado por ser exatamente o que esta ADR resolve.
- **`json_serializable` puro para payloads** — não cobre cross-platform; Pigeon faz ambos.
- **`custom_lint` package** — overhead de codegen extra; `dart test` estático cobre os mesmos casos com menor custo. Reabrir se algum gate virar ruidoso em IDE.
- **Geração de tokens via Figma Tokens** — overkill; protótipo HTML é a fonte e migra 1x.

## References

- spec: `docs/superpowers/specs/2026-05-25-api-contract-shared-design.md`
- plan: `docs/superpowers/plans/2026-05-26-api-contract-shared.md`
- https://docs.flutter.dev/platform-integration/platform-channels
- https://pub.dev/packages/pigeon
- https://pub.dev/packages/theme_tailor
- https://api.flutter.dev/flutter/material/ThemeExtension-class.html
```

- [ ] **Step 3: Commit**

```bash
git add docs/decisions/0013-pigeon-theme-tailor-and-anti-drift-gates.md
git commit -m "docs(decisions): adr-013 pigeon + theme tailor + anti-drift gates"
```

Expected: pre-commit limpo, commit-msg passa commitlint.

---

### Task 2: Atualizar Blueprint (Seções 2.2, 2.10, 9)

**Files:**
- Modify: `docs/Blueprint.md` — Seção 2.2 (parágrafo "Method Channels"), Seção 2.10 (tabela monorepo tooling), Seção 9 (tabela ADRs previstos)

- [ ] **Step 1: Adicionar nota Pigeon após tabela de Method Channels em Seção 2.2**

Em `docs/Blueprint.md`, localizar a tabela "Method Channels (Dart ↔ Swift/Kotlin)" e adicionar imediatamente após, antes da Seção 2.3:

```markdown
> **Atualização 2026-05-26 (ADR-0013):** Os 4 channels acima são gerados via **Pigeon ^26.3.4** a partir de schemas Dart únicos em `apps/mobile/pigeons/{camera,replay_buffer,voice,volume}_api.dart`. Strings de namespace nunca são digitadas em Swift ou Kotlin; codegen sincroniza Dart + iOS + Android. Ver ADR-0013 e spec `api-contract-shared`.
```

- [ ] **Step 2: Adicionar 3 linhas em Blueprint Seção 2.10**

Localizar tabela "Monorepo tooling" (Seção 2.10) e adicionar antes da linha final:

```markdown
| Native bridges codegen | `pigeon` | `^26.3.4` |
| Theme tokens codegen | `theme_tailor` + `theme_tailor_annotation` | `^3.1.3` |
| XML parse (parity tests) | `xml` | `^6.5.0` |
```

- [ ] **Step 3: Adicionar ADR-013 em Blueprint Seção 9**

Localizar tabela "ADRs previstos" e adicionar linha:

```markdown
| 0013 | Pigeon + Theme Tailor + gates anti-drift | spec api-contract-shared |
```

- [ ] **Step 4: Verificar e commitar**

```bash
git diff docs/Blueprint.md
git add docs/Blueprint.md
git commit -m "docs(blueprint): reference adr-013 in sections 2.2, 2.10, 9"
```

Expected: 3 hunks visíveis no diff, commit limpo.

---

### Task 3: Reorganizar `packages/shared` — identity (TDD)

**Files:**
- Create: `packages/shared/lib/src/identity/app_identity.dart`
- Delete: `packages/shared/lib/src/constants/app_identity.dart`
- Modify: `packages/shared/test/smoke_test.dart`
- Create: `packages/shared/lib/raro_shared.dart` (barrel)

- [ ] **Step 1: Escrever teste para nova localização**

Edit `packages/shared/test/smoke_test.dart` — substituir conteúdo inteiro por:

```dart
import 'package:raro_shared/raro_shared.dart';
import 'package:test/test.dart';

void main() {
  group('Family 1 — Identity', () {
    test('display name is "Raro Camera"', () {
      expect(AppIdentity.displayName, 'Raro Camera');
    });

    test('bundle id is com.rarocamera', () {
      expect(AppIdentity.bundleId, 'com.rarocamera');
    });

    test('application id matches bundle id', () {
      expect(AppIdentity.applicationId, AppIdentity.bundleId);
    });
  });
}
```

- [ ] **Step 2: Rodar teste — falha esperada**

```bash
bun --filter @raro/shared run test
```

Expected: `Could not resolve package raro_shared` ou `AppIdentity` não encontrado.

- [ ] **Step 3: Criar `packages/shared/lib/src/identity/app_identity.dart`**

```dart
abstract final class AppIdentity {
  static const String displayName = 'Raro Camera';
  static const String bundleId = 'com.rarocamera';
  static const String applicationId = 'com.rarocamera';
  static const String version = '1.0.0';
  static const int build = 1;
}
```

- [ ] **Step 4: Criar barrel `packages/shared/lib/raro_shared.dart`**

```dart
export 'src/identity/app_identity.dart';
```

- [ ] **Step 5: Deletar arquivo legado**

```bash
rm packages/shared/lib/src/constants/app_identity.dart
```

- [ ] **Step 6: Rodar teste — verde esperado**

```bash
bun --filter @raro/shared run test
```

Expected: 3 testes verdes.

- [ ] **Step 7: Commit**

```bash
git add packages/shared/
git commit -m "refactor(shared): move app_identity to identity/ with abstract final class"
```

---

### Task 4: Migrar voice + subscription para nova estrutura (TDD)

**Files:**
- Create: `packages/shared/lib/src/voice/voice_config.dart`
- Create: `packages/shared/lib/src/subscription/subscription.dart`
- Delete: `packages/shared/lib/src/constants/voice.dart`, `packages/shared/lib/src/constants/subscription.dart`
- Modify: `packages/shared/lib/raro_shared.dart`, `packages/shared/test/smoke_test.dart`

- [ ] **Step 1: Estender teste**

Edit `packages/shared/test/smoke_test.dart` — adicionar dentro de `main()`:

```dart
  group('Family 2 — Invariants', () {
    test('wake word is "Raro" (never "OkCamera")', () {
      expect(VoiceConfig.wakeWord, 'Raro');
    });

    test('free trial is 30 days', () {
      expect(SubscriptionConfig.freeTrialDays, 30);
    });

    test('monthly SKU matches Blueprint 2.4', () {
      expect(SubscriptionSkus.monthly, 'raro_premium_monthly_BRL_9_90');
    });

    test('yearly SKU matches Blueprint 2.4', () {
      expect(SubscriptionSkus.yearly, 'raro_premium_yearly_BRL_89_90');
    });

    test('entitlement is "premium"', () {
      expect(SubscriptionConfig.entitlement, 'premium');
    });
  });
```

- [ ] **Step 2: Rodar — falha esperada**

```bash
bun --filter @raro/shared run test
```

Expected: `VoiceConfig`/`SubscriptionConfig`/`SubscriptionSkus` undefined.

- [ ] **Step 3: Criar `packages/shared/lib/src/voice/voice_config.dart`**

```dart
abstract final class VoiceConfig {
  static const String wakeWord = 'Raro';
}
```

- [ ] **Step 4: Criar `packages/shared/lib/src/subscription/subscription.dart`**

```dart
abstract final class SubscriptionSkus {
  static const String monthly = 'raro_premium_monthly_BRL_9_90';
  static const String yearly = 'raro_premium_yearly_BRL_89_90';
}

abstract final class SubscriptionConfig {
  static const String entitlement = 'premium';
  static const int freeTrialDays = 30;
}
```

- [ ] **Step 5: Estender barrel**

Edit `packages/shared/lib/raro_shared.dart`:

```dart
export 'src/identity/app_identity.dart';
export 'src/subscription/subscription.dart';
export 'src/voice/voice_config.dart';
```

- [ ] **Step 6: Deletar legados**

```bash
rm packages/shared/lib/src/constants/voice.dart
rm packages/shared/lib/src/constants/subscription.dart
rmdir packages/shared/lib/src/constants
```

- [ ] **Step 7: Rodar — verde esperado**

```bash
bun --filter @raro/shared run test
```

Expected: 8 testes verdes.

- [ ] **Step 8: Commit**

```bash
git add packages/shared/
git commit -m "refactor(shared): move voice + subscription, formalize as abstract final class"
```

---

### Task 5: Exportar enums via barrel (TDD)

**Files:**
- Modify: `packages/shared/lib/raro_shared.dart`
- Modify: `packages/shared/test/smoke_test.dart`

- [ ] **Step 1: Estender teste**

Edit `packages/shared/test/smoke_test.dart` — adicionar:

```dart
  group('Family 5 — Domain enums', () {
    test('Lens has ultraWide and wide', () {
      expect(Lens.values, [Lens.ultraWide, Lens.wide]);
      expect(Lens.ultraWide.label, '0.5x');
      expect(Lens.wide.label, '1x');
    });

    test('Fps has 30 and 60', () {
      expect(Fps.values.map((f) => f.value), [30, 60]);
    });

    test('Resolution has 4 levels', () {
      expect(Resolution.values.length, 4);
    });

    test('BufferDuration has 15s and 30s', () {
      expect(BufferDuration.values.map((b) => b.value), [15, 30]);
    });

    test('ControlMode has voice and volume', () {
      expect(ControlMode.values, [ControlMode.voice, ControlMode.volume]);
    });

    test('AppLanguage has pt-BR, en, es', () {
      expect(AppLanguage.values.map((l) => l.tag), ['pt-BR', 'en', 'es']);
    });
  });
```

- [ ] **Step 2: Rodar — falha esperada**

```bash
bun --filter @raro/shared run test
```

Expected: `Lens`/`Fps`/etc. undefined no escopo do teste.

- [ ] **Step 3: Estender barrel**

Edit `packages/shared/lib/raro_shared.dart` — adicionar:

```dart
export 'src/enums/app_language.dart';
export 'src/enums/buffer_duration.dart';
export 'src/enums/control_mode.dart';
export 'src/enums/fps.dart';
export 'src/enums/lens.dart';
export 'src/enums/resolution.dart';
```

- [ ] **Step 4: Rodar — verde esperado**

```bash
bun --filter @raro/shared run test
```

Expected: 14 testes verdes.

- [ ] **Step 5: Commit**

```bash
git add packages/shared/
git commit -m "feat(shared): export enums via raro_shared barrel"
```

---

### Task 6: Migrar analytics events + criar payloads (TDD)

**Files:**
- Create: `packages/shared/lib/src/analytics/analytics_events.dart`
- Create: `packages/shared/lib/src/analytics/analytics_payloads.dart`
- Delete: `packages/shared/lib/src/events/analytics_events.dart`
- Modify: `packages/shared/lib/raro_shared.dart`, `packages/shared/test/smoke_test.dart`

- [ ] **Step 1: Estender teste**

Edit `packages/shared/test/smoke_test.dart` — adicionar:

```dart
  group('Family 6 — Analytics event names', () {
    test('event names follow snake_case pattern', () {
      const names = [
        AnalyticsEvents.appOpen,
        AnalyticsEvents.recordingStarted,
        AnalyticsEvents.planSelected,
        AnalyticsEvents.subscriptionActivated,
      ];
      for (final n in names) {
        expect(n, matches(RegExp(r'^[a-z][a-z0-9_]+$')));
      }
    });
  });

  group('Family 7 — Analytics payloads', () {
    test('RecordingStartedPayload.toMap returns expected keys/values', () {
      const p = RecordingStartedPayload(
        lens: Lens.wide,
        resolution: Resolution.fullHd1080,
        fps: Fps.fps60,
        trigger: ControlMode.voice,
        bufferDuration: BufferDuration.seconds15,
      );
      expect(p.toMap(), {
        'lens': '1x',
        'resolution': '1080p',
        'fps': 60,
        'trigger': 'voice',
        'buffer_duration': 15,
      });
    });

    test('PlanSelectedPayload.toMap returns sku key', () {
      const p = PlanSelectedPayload(sku: SubscriptionSkus.monthly);
      expect(p.toMap(), {'sku': 'raro_premium_monthly_BRL_9_90'});
    });

    test('LensSwitchedPayload.toMap returns from/to', () {
      const p = LensSwitchedPayload(from: Lens.ultraWide, to: Lens.wide);
      expect(p.toMap(), {'from': '0.5x', 'to': '1x'});
    });
  });
```

- [ ] **Step 2: Rodar — falha esperada**

```bash
bun --filter @raro/shared run test
```

Expected: 3 classes undefined.

- [ ] **Step 3: Criar `packages/shared/lib/src/analytics/analytics_events.dart`**

```dart
abstract final class AnalyticsEvents {
  static const String appOpen = 'app_open';
  static const String onboardingStarted = 'onboarding_started';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String permissionsGranted = 'permissions_granted';

  static const String recordingStarted = 'recording_started';
  static const String recordingEnded = 'recording_ended';
  static const String recordingFailed = 'recording_failed';

  static const String voiceWakeDetected = 'voice_wake_detected';
  static const String volumeTriggerUsed = 'volume_trigger_used';
  static const String lensSwitched = 'lens_switched';
  static const String resolutionChanged = 'resolution_changed';
  static const String fpsChanged = 'fps_changed';
  static const String bufferDurationChanged = 'buffer_duration_changed';
  static const String controlModeChanged = 'control_mode_changed';

  static const String lockEntered = 'lock_entered';
  static const String lockExited = 'lock_exited';

  static const String galleryOpened = 'gallery_opened';
  static const String videoShared = 'video_shared';
  static const String videoDeleted = 'video_deleted';

  static const String paywallShown = 'paywall_shown';
  static const String planSelected = 'plan_selected';
  static const String checkoutStarted = 'checkout_started';
  static const String subscriptionActivated = 'subscription_activated';
  static const String restorePurchases = 'restore_purchases';

  static const String languageChanged = 'language_changed';
  static const String xiaomiModalShown = 'xiaomi_modal_shown';
}
```

- [ ] **Step 4: Criar `packages/shared/lib/src/analytics/analytics_payloads.dart`**

```dart
import '../enums/buffer_duration.dart';
import '../enums/control_mode.dart';
import '../enums/fps.dart';
import '../enums/lens.dart';
import '../enums/resolution.dart';

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

  final String sku;

  Map<String, Object?> toMap() => {'sku': sku};
}

class LensSwitchedPayload {
  const LensSwitchedPayload({required this.from, required this.to});

  final Lens from;
  final Lens to;

  Map<String, Object?> toMap() => {'from': from.label, 'to': to.label};
}
```

- [ ] **Step 5: Estender barrel + remover legado**

Edit `packages/shared/lib/raro_shared.dart` — adicionar:

```dart
export 'src/analytics/analytics_events.dart';
export 'src/analytics/analytics_payloads.dart';
```

```bash
rm packages/shared/lib/src/events/analytics_events.dart
rmdir packages/shared/lib/src/events
```

- [ ] **Step 6: Rodar — verde esperado**

```bash
bun --filter @raro/shared run test
```

Expected: 18 testes verdes.

- [ ] **Step 7: Commit**

```bash
git add packages/shared/
git commit -m "feat(analytics): move events + add typed payloads"
```

---

### Task 7: Criar AppScreen + AppModal enums (TDD)

**Files:**
- Create: `packages/shared/lib/src/screens/app_screen.dart`
- Modify: `packages/shared/lib/raro_shared.dart`, `packages/shared/test/smoke_test.dart`

- [ ] **Step 1: Estender teste**

Edit `packages/shared/test/smoke_test.dart` — adicionar:

```dart
  group('Family 8 — AppScreen + AppModal', () {
    test('AppScreen paths are unique', () {
      final paths = AppScreen.values.map((s) => s.path).toList();
      expect(paths.toSet().length, paths.length, reason: 'duplicate path');
    });

    test('AppScreen analyticsNames are unique', () {
      final names = AppScreen.values.map((s) => s.analyticsName).toList();
      expect(names.toSet().length, names.length, reason: 'duplicate analyticsName');
    });

    test('AppModal analyticsNames are unique', () {
      final names = AppModal.values.map((m) => m.analyticsName).toList();
      expect(names.toSet().length, names.length);
    });

    test('AppScreen has 13 entries (Blueprint Seção 5)', () {
      expect(AppScreen.values.length, 13);
    });

    test('AppModal has 3 entries', () {
      expect(AppModal.values.length, 3);
    });
  });
```

- [ ] **Step 2: Rodar — falha esperada**

```bash
bun --filter @raro/shared run test
```

Expected: `AppScreen`/`AppModal` undefined.

- [ ] **Step 3: Criar `packages/shared/lib/src/screens/app_screen.dart`**

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

- [ ] **Step 4: Estender barrel**

Edit `packages/shared/lib/raro_shared.dart` — adicionar:

```dart
export 'src/screens/app_screen.dart';
```

- [ ] **Step 5: Rodar — verde esperado**

```bash
bun --filter @raro/shared run test
```

Expected: 23 testes verdes.

- [ ] **Step 6: Commit**

```bash
git add packages/shared/
git commit -m "feat(shared): add AppScreen + AppModal enums (family 8)"
```

---

### Task 8: Criar StorageKeys + BridgeChannels + PermissionsContract + ForbiddenTerms (TDD)

**Files:**
- Create: `packages/shared/lib/src/storage/storage_keys.dart`
- Create: `packages/shared/lib/src/bridges/bridge_channels.dart`
- Create: `packages/shared/lib/src/permissions/permissions_contract.dart`
- Create: `packages/shared/lib/src/contract/forbidden_terms.dart`
- Modify: `packages/shared/lib/raro_shared.dart`, `packages/shared/test/smoke_test.dart`

- [ ] **Step 1: Estender teste**

Edit `packages/shared/test/smoke_test.dart` — adicionar:

```dart
  group('Family 9 — StorageKeys', () {
    test('all keys follow raro.<domain>.<key>', () {
      const keys = [
        StorageKeys.onboardingCompleted,
        StorageKeys.selectedLanguage,
        StorageKeys.preferredResolution,
        StorageKeys.preferredFps,
        StorageKeys.preferredBufferDuration,
        StorageKeys.preferredControlMode,
        StorageKeys.xiaomiGuideShown,
        StorageKeys.firstLaunchAt,
        StorageKeys.lastLanguageDetected,
      ];
      for (final k in keys) {
        expect(k, matches(RegExp(r'^raro\.[a-z_]+\.[a-z_]+$')));
      }
    });
  });

  group('Family 3 — BridgeChannels', () {
    test('all channels start with com.rarocamera/', () {
      const channels = [
        BridgeChannels.camera,
        BridgeChannels.replayBuffer,
        BridgeChannels.voice,
        BridgeChannels.volume,
      ];
      for (final c in channels) {
        expect(c, startsWith('com.rarocamera/'));
      }
    });
  });

  group('Family 10 — PermissionsContract', () {
    test('iOS keys present', () {
      expect(PermissionsContract.ios.containsKey('NSCameraUsageDescription'), isTrue);
      expect(PermissionsContract.ios.containsKey('NSMicrophoneUsageDescription'), isTrue);
      expect(PermissionsContract.ios.containsKey('NSSpeechRecognitionUsageDescription'), isTrue);
    });

    test('Android permissions present', () {
      expect(PermissionsContract.android, contains('android.permission.CAMERA'));
      expect(PermissionsContract.android, contains('android.permission.RECORD_AUDIO'));
    });
  });

  group('Family 2/12 — ForbiddenTerms', () {
    test('contains OkCamera variants', () {
      expect(ForbiddenTerms.all, contains('OkCamera'));
      expect(ForbiddenTerms.all, contains('Ok Camera'));
      expect(ForbiddenTerms.all, contains('hey OkCamera'));
    });
  });
```

- [ ] **Step 2: Rodar — falha esperada**

```bash
bun --filter @raro/shared run test
```

- [ ] **Step 3: Criar `packages/shared/lib/src/storage/storage_keys.dart`**

```dart
abstract final class StorageKeys {
  static const String onboardingCompleted = 'raro.onboarding.completed';
  static const String selectedLanguage = 'raro.language.selected';
  static const String preferredResolution = 'raro.camera.resolution';
  static const String preferredFps = 'raro.camera.fps';
  static const String preferredBufferDuration = 'raro.replay.buffer_duration';
  static const String preferredControlMode = 'raro.control.mode';
  static const String xiaomiGuideShown = 'raro.xiaomi.guide_shown';
  static const String firstLaunchAt = 'raro.first.launch_at';
  static const String lastLanguageDetected = 'raro.language.detected';
}
```

- [ ] **Step 4: Criar `packages/shared/lib/src/bridges/bridge_channels.dart`**

```dart
abstract final class BridgeChannels {
  static const String camera = 'com.rarocamera/camera';
  static const String replayBuffer = 'com.rarocamera/replay_buffer';
  static const String voice = 'com.rarocamera/voice';
  static const String volume = 'com.rarocamera/volume';
}
```

- [ ] **Step 5: Criar `packages/shared/lib/src/permissions/permissions_contract.dart`**

```dart
class PermissionMessage {
  const PermissionMessage({
    required this.ptBr,
    required this.en,
    required this.es,
  });

  final String ptBr;
  final String en;
  final String es;
}

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
      ptBr:
          'A Raro Camera usa reconhecimento de voz no dispositivo para detectar "Raro".',
      en: 'Raro Camera uses on-device speech recognition to detect "Raro".',
      es:
          'Raro Camera usa reconocimiento de voz en el dispositivo para detectar "Raro".',
    ),
  };

  static const List<String> android = [
    'android.permission.CAMERA',
    'android.permission.RECORD_AUDIO',
  ];
}
```

- [ ] **Step 6: Criar `packages/shared/lib/src/contract/forbidden_terms.dart`**

```dart
abstract final class ForbiddenTerms {
  static const List<String> all = [
    'OkCamera',
    'Ok Camera',
    'hey OkCamera',
    'okCamera',
    'ok_camera',
  ];
}
```

- [ ] **Step 7: Estender barrel**

Edit `packages/shared/lib/raro_shared.dart` — adicionar:

```dart
export 'src/bridges/bridge_channels.dart';
export 'src/contract/forbidden_terms.dart';
export 'src/permissions/permissions_contract.dart';
export 'src/storage/storage_keys.dart';
```

- [ ] **Step 8: Rodar — verde esperado**

```bash
bun --filter @raro/shared run test
```

Expected: 28 testes verdes.

- [ ] **Step 9: Commit**

```bash
git add packages/shared/
git commit -m "feat(shared): add storage keys, bridge channels, permissions, forbidden terms"
```

---

### Task 9: Atualizar imports em apps/mobile para barrel

**Files:**
- Modify: `apps/mobile/test/smoke_test.dart`
- Modify: outros consumers do shared se houver

- [ ] **Step 1: Listar imports atuais**

```bash
grep -rn "package:raro_shared" apps/mobile/lib apps/mobile/test
```

Expected: lista. Identificar qualquer `package:raro_shared/src/...` (subpath import).

- [ ] **Step 2: Trocar para barrel**

Para cada arquivo encontrado, substituir `import 'package:raro_shared/src/...';` por `import 'package:raro_shared/raro_shared.dart';`.

`apps/mobile/test/smoke_test.dart` provavelmente é o único — manter os 3 imports atuais consolidados em 1.

- [ ] **Step 3: Rodar test e analyze**

```bash
bun --filter @raro/mobile run analyze
bun --filter @raro/mobile run test
```

Expected: zero issues, smoke test verde.

- [ ] **Step 4: Commit**

```bash
git add apps/mobile/
git commit -m "refactor(mobile): use raro_shared barrel import"
```

---

### Task 10: Adicionar Pigeon + Theme Tailor + xml ao apps/mobile

**Files:**
- Modify: `apps/mobile/pubspec.yaml`

- [ ] **Step 1: Adicionar deps**

Em `apps/mobile/pubspec.yaml`, dentro de `dependencies:` (em ordem alfabética), adicionar:

```yaml
  theme_tailor_annotation: ^3.1.3
  xml: ^6.5.0
```

Dentro de `dev_dependencies:`, adicionar:

```yaml
  pigeon: ^26.3.4
  theme_tailor: ^3.1.3
```

- [ ] **Step 2: Rodar pub get**

```bash
bun --filter @raro/mobile run pub:get
```

Expected: `Got dependencies!`, nenhum erro de version solve.

- [ ] **Step 3: Verificar analyze**

```bash
bun --filter @raro/mobile run analyze
```

Expected: zero issues.

- [ ] **Step 4: Commit**

```bash
git add apps/mobile/pubspec.yaml apps/mobile/pubspec.lock
git commit -m "build(deps): add pigeon, theme_tailor, xml for anti-drift codegen"
```

---

### Task 11: Criar 4 Pigeon schemas + gerar saídas

**Files:**
- Create: `apps/mobile/pigeons/{camera,replay_buffer,voice,volume}_api.dart`
- Modify: `apps/mobile/package.json` (script `pigeon`)
- Generated (commitar): 4× `_api.g.dart`, 4× `*Api.g.swift`, 4× `*Api.g.kt`

- [ ] **Step 1: Criar diretórios de saída**

```bash
mkdir -p apps/mobile/pigeons
mkdir -p apps/mobile/lib/core/native_bridges/generated
mkdir -p apps/mobile/ios/Runner/Native/Generated
mkdir -p apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/generated
```

- [ ] **Step 2: Criar `apps/mobile/pigeons/camera_api.dart`**

```dart
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
  void cameraPing();
}

@FlutterApi()
abstract class CameraFlutterApi {
  void cameraReady();
}
```

(Motivo de `cameraPing`/`cameraReady`: Pigeon não aceita `@HostApi` totalmente vazio em todas as versões. Métodos triviais garantem codegen válido e serão substituídos pela spec do bridge.)

- [ ] **Step 3: Criar `apps/mobile/pigeons/replay_buffer_api.dart`**

```dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/core/native_bridges/generated/replay_buffer_api.g.dart',
  dartOptions: DartOptions(),
  swiftOut: 'ios/Runner/Native/Generated/ReplayBufferApi.g.swift',
  swiftOptions: SwiftOptions(),
  kotlinOut: 'android/app/src/main/kotlin/com/rarocamera/raro_mobile/generated/ReplayBufferApi.g.kt',
  kotlinOptions: KotlinOptions(package: 'com.rarocamera.raro_mobile.generated'),
  dartPackageName: 'raro_mobile',
))
@HostApi()
abstract class ReplayBufferHostApi {
  void replayBufferPing();
}

@FlutterApi()
abstract class ReplayBufferFlutterApi {
  void replayBufferReady();
}
```

- [ ] **Step 4: Criar `apps/mobile/pigeons/voice_api.dart`**

```dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/core/native_bridges/generated/voice_api.g.dart',
  dartOptions: DartOptions(),
  swiftOut: 'ios/Runner/Native/Generated/VoiceApi.g.swift',
  swiftOptions: SwiftOptions(),
  kotlinOut: 'android/app/src/main/kotlin/com/rarocamera/raro_mobile/generated/VoiceApi.g.kt',
  kotlinOptions: KotlinOptions(package: 'com.rarocamera.raro_mobile.generated'),
  dartPackageName: 'raro_mobile',
))
@HostApi()
abstract class VoiceHostApi {
  void voicePing();
}

@FlutterApi()
abstract class VoiceFlutterApi {
  void voiceReady();
}
```

- [ ] **Step 5: Criar `apps/mobile/pigeons/volume_api.dart`**

```dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/core/native_bridges/generated/volume_api.g.dart',
  dartOptions: DartOptions(),
  swiftOut: 'ios/Runner/Native/Generated/VolumeApi.g.swift',
  swiftOptions: SwiftOptions(),
  kotlinOut: 'android/app/src/main/kotlin/com/rarocamera/raro_mobile/generated/VolumeApi.g.kt',
  kotlinOptions: KotlinOptions(package: 'com.rarocamera.raro_mobile.generated'),
  dartPackageName: 'raro_mobile',
))
@HostApi()
abstract class VolumeHostApi {
  void volumePing();
}

@FlutterApi()
abstract class VolumeFlutterApi {
  void volumeReady();
}
```

- [ ] **Step 6: Adicionar script `pigeon` em `apps/mobile/package.json`**

Edit `apps/mobile/package.json` — adicionar dentro de `scripts`:

```json
    "pigeon": "dart run pigeon --input pigeons/camera_api.dart && dart run pigeon --input pigeons/replay_buffer_api.dart && dart run pigeon --input pigeons/voice_api.dart && dart run pigeon --input pigeons/volume_api.dart",
```

- [ ] **Step 7: Rodar pigeon codegen**

```bash
bun --filter @raro/mobile run pigeon
```

Expected: 4 mensagens de sucesso. 12 arquivos gerados.

- [ ] **Step 8: Verificar saídas**

```bash
ls apps/mobile/lib/core/native_bridges/generated/
ls apps/mobile/ios/Runner/Native/Generated/
ls apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/generated/
```

Expected: 4 `.g.dart`, 4 `.g.swift`, 4 `.g.kt`.

- [ ] **Step 9: Verificar que generated Dart compila**

```bash
bun --filter @raro/mobile run analyze
```

Expected: zero issues (ou warnings sobre unused — aceitáveis em schemas iniciais).

- [ ] **Step 10: Commit**

```bash
git add apps/mobile/pigeons/ apps/mobile/lib/core/native_bridges/ apps/mobile/ios/Runner/Native/ apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/generated/ apps/mobile/package.json
git commit -m "feat(bridge): add 4 pigeon schemas with codegen pipeline"
```

---

### Task 12: Criar Theme Tailor tokens + codegen + aplicar no MaterialApp

**Files:**
- Create: `apps/mobile/lib/core/theme/raro_theme.dart`
- Create: `apps/mobile/lib/core/theme/raro_theme_data.dart`
- Generated (commitar): `apps/mobile/lib/core/theme/raro_theme.tailor.dart`
- Modify: `apps/mobile/lib/app.dart`

- [ ] **Step 1: Criar `apps/mobile/lib/core/theme/raro_theme.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

part 'raro_theme.tailor.dart';

@TailorMixin()
class RaroColors extends ThemeExtension<RaroColors>
    with _$RaroColorsTailorMixin {
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

  @override
  final Color bgDeep;
  @override
  final Color bgElev;
  @override
  final Color bgCard;
  @override
  final Color ink;
  @override
  final Color inkDim;
  @override
  final Color inkFaint;
  @override
  final Color border;
  @override
  final Color borderBright;
  @override
  final Color raroRed;

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
class RaroRadii extends ThemeExtension<RaroRadii> with _$RaroRadiiTailorMixin {
  const RaroRadii({
    required this.card,
    required this.button,
    required this.pill,
    required this.chip,
    required this.sheetTop,
    required this.phone,
  });

  @override
  final double card;
  @override
  final double button;
  @override
  final double pill;
  @override
  final double chip;
  @override
  final double sheetTop;
  @override
  final double phone;

  static const RaroRadii dark = RaroRadii(
    card: 16,
    button: 16,
    pill: 999,
    chip: 10,
    sheetTop: 24,
    phone: 50,
  );
}

@TailorMixin()
class RaroSpacing extends ThemeExtension<RaroSpacing>
    with _$RaroSpacingTailorMixin {
  const RaroSpacing({
    required this.x05,
    required this.x1,
    required this.x2,
    required this.x3,
    required this.x4,
    required this.x5,
    required this.x6,
    required this.x7,
    required this.x10,
    required this.x12,
  });

  @override
  final double x05;
  @override
  final double x1;
  @override
  final double x2;
  @override
  final double x3;
  @override
  final double x4;
  @override
  final double x5;
  @override
  final double x6;
  @override
  final double x7;
  @override
  final double x10;
  @override
  final double x12;

  static const RaroSpacing dark = RaroSpacing(
    x05: 2,
    x1: 4,
    x2: 8,
    x3: 12,
    x4: 16,
    x5: 20,
    x6: 24,
    x7: 28,
    x10: 40,
    x12: 48,
  );
}

@TailorMixin()
class RaroDurations extends ThemeExtension<RaroDurations>
    with _$RaroDurationsTailorMixin {
  const RaroDurations({
    required this.logoBreathe,
    required this.recPulse,
    required this.lensSwitchBlur,
    required this.focusRing,
    required this.gradShift,
    required this.planHueSpin,
    required this.touchActive,
  });

  @override
  final Duration logoBreathe;
  @override
  final Duration recPulse;
  @override
  final Duration lensSwitchBlur;
  @override
  final Duration focusRing;
  @override
  final Duration gradShift;
  @override
  final Duration planHueSpin;
  @override
  final Duration touchActive;

  static const RaroDurations dark = RaroDurations(
    logoBreathe: Duration(milliseconds: 3400),
    recPulse: Duration(milliseconds: 1200),
    lensSwitchBlur: Duration(milliseconds: 220),
    focusRing: Duration(milliseconds: 1200),
    gradShift: Duration(milliseconds: 5000),
    planHueSpin: Duration(milliseconds: 6000),
    touchActive: Duration(milliseconds: 120),
  );
}
```

(Gradient/Typography ficam de fora desta primeira leva — entram em spec de design system. Justificativa: exigem mais decisões e validação visual via goldens.)

- [ ] **Step 2: Rodar build_runner**

```bash
bun --filter @raro/mobile run codegen
```

Expected: gera `apps/mobile/lib/core/theme/raro_theme.tailor.dart`. Sem erro.

- [ ] **Step 3: Verificar saída**

```bash
ls apps/mobile/lib/core/theme/raro_theme.tailor.dart
```

Expected: arquivo existe.

- [ ] **Step 4: Criar `apps/mobile/lib/core/theme/raro_theme_data.dart`**

```dart
import 'package:flutter/material.dart';

import 'raro_theme.dart';

ThemeData buildRaroDarkTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: RaroColors.dark.bgDeep,
    extensions: const <ThemeExtension<dynamic>>[
      RaroColors.dark,
      RaroRadii.dark,
      RaroSpacing.dark,
      RaroDurations.dark,
    ],
  );
}
```

- [ ] **Step 5: Aplicar em `apps/mobile/lib/app.dart`**

Adicionar import no topo:

```dart
import 'package:raro_mobile/core/theme/raro_theme_data.dart';
```

Localizar o `MaterialApp(...)` e adicionar:

```dart
      theme: buildRaroDarkTheme(),
```

- [ ] **Step 6: Verificar analyze + test**

```bash
bun --filter @raro/mobile run analyze
bun --filter @raro/mobile run test
```

Expected: zero issues, smoke test continua verde.

- [ ] **Step 7: Commit**

```bash
git add apps/mobile/lib/core/theme/ apps/mobile/lib/app.dart
git commit -m "feat(theme): add theme tailor tokens (colors, radii, spacing, durations)"
```

---

### Task 13: Criar gate `forbidden_literals_test.dart`

**Files:**
- Create: `apps/mobile/test/contract/forbidden_literals_test.dart`

- [ ] **Step 1: Criar diretório**

```bash
mkdir -p apps/mobile/test/contract
```

- [ ] **Step 2: Criar `apps/mobile/test/contract/forbidden_literals_test.dart`**

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:raro_shared/raro_shared.dart';

const _excludedSuffixes = ['.g.dart', '.tailor.dart', '.freezed.dart'];

bool _isExcluded(String path) {
  for (final s in _excludedSuffixes) {
    if (path.endsWith(s)) return true;
  }
  return path.contains('/generated/');
}

Iterable<File> _scanDart(String rootRelative) sync* {
  final dir = Directory(rootRelative);
  if (!dir.existsSync()) return;
  for (final e in dir.listSync(recursive: true)) {
    if (e is File && e.path.endsWith('.dart') && !_isExcluded(e.path)) {
      yield e;
    }
  }
}

void main() {
  group('Family 2/12 — forbidden terms', () {
    test('no OkCamera variant in lib or shared', () {
      final hits = <String>[];
      for (final f in [
        ..._scanDart('lib'),
        ..._scanDart('../../packages/shared/lib'),
      ]) {
        final content = f.readAsStringSync();
        for (final term in ForbiddenTerms.all) {
          if (content.contains(term)) hits.add('${f.path}: $term');
        }
      }
      expect(hits, isEmpty,
          reason: 'forbidden term found:\n${hits.join("\n")}');
    });
  });

  group('Family 3 — channel literal isolation', () {
    test('no "com.rarocamera/" literal outside bridges/', () {
      final hits = <String>[];
      for (final f in _scanDart('../../packages/shared/lib')) {
        if (f.path.contains('/bridges/')) continue;
        if (f.readAsStringSync().contains('com.rarocamera/')) hits.add(f.path);
      }
      for (final f in _scanDart('lib')) {
        final c = f.readAsStringSync();
        if (c.contains("'com.rarocamera/") || c.contains('"com.rarocamera/')) {
          hits.add(f.path);
        }
      }
      expect(hits, isEmpty,
          reason:
              'channel literal outside canonical source:\n${hits.join("\n")}');
    });
  });

  group('Family 2 — SKU literal isolation', () {
    test('no "raro_premium_" literal outside subscription/', () {
      final hits = <String>[];
      for (final f in _scanDart('../../packages/shared/lib')) {
        if (f.path.contains('/subscription/')) continue;
        if (f.readAsStringSync().contains('raro_premium_')) hits.add(f.path);
      }
      for (final f in _scanDart('lib')) {
        if (f.readAsStringSync().contains('raro_premium_')) hits.add(f.path);
      }
      expect(hits, isEmpty,
          reason: 'SKU literal outside canonical source:\n${hits.join("\n")}');
    });
  });

  group('Family 11 — hex color isolation', () {
    test('no Color(0xFF...) outside core/theme/', () {
      final pattern = RegExp(r'Color\(0x[0-9A-Fa-f]{8}\)');
      final hits = <String>[];
      for (final f in _scanDart('lib')) {
        if (f.path.contains('/core/theme/')) continue;
        if (pattern.hasMatch(f.readAsStringSync())) hits.add(f.path);
      }
      expect(hits, isEmpty,
          reason: 'hex color outside core/theme:\n${hits.join("\n")}');
    });
  });
}
```

- [ ] **Step 3: Rodar — esperado verde (estado atual já limpo)**

```bash
cd apps/mobile && flutter test test/contract/forbidden_literals_test.dart
```

Expected: 4 grupos verdes. Se houver hit, é drift legítimo — corrigir e re-rodar.

- [ ] **Step 4: Commit**

```bash
git add apps/mobile/test/contract/forbidden_literals_test.dart
git commit -m "test(contract): add forbidden_literals gate (terms, channels, skus, hex)"
```

---

### Task 14: Criar info_plist_parity_test + android_manifest_parity_test (testes que documentam drift)

**Files:**
- Create: `apps/mobile/test/contract/info_plist_parity_test.dart`
- Create: `apps/mobile/test/contract/android_manifest_parity_test.dart`

- [ ] **Step 1: Criar `apps/mobile/test/contract/info_plist_parity_test.dart`**

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:raro_shared/raro_shared.dart';
import 'package:xml/xml.dart';

XmlDocument _readPlist() {
  return XmlDocument.parse(
    File('ios/Runner/Info.plist').readAsStringSync(),
  );
}

String? _plistString(XmlDocument doc, String key) {
  final dict = doc.rootElement.findElements('dict').single;
  final children = dict.children.whereType<XmlElement>().toList();
  for (var i = 0; i < children.length; i++) {
    if (children[i].localName == 'key' && children[i].innerText == key) {
      if (i + 1 < children.length) return children[i + 1].innerText;
    }
  }
  return null;
}

void main() {
  group('Family 10 — Info.plist parity', () {
    final doc = _readPlist();

    test('CFBundleDisplayName == AppIdentity.displayName', () {
      expect(_plistString(doc, 'CFBundleDisplayName'), AppIdentity.displayName);
    });

    test('CFBundleIdentifier matches AppIdentity.bundleId or variable', () {
      final v = _plistString(doc, 'CFBundleIdentifier');
      expect(
        v == AppIdentity.bundleId || v == r'$(PRODUCT_BUNDLE_IDENTIFIER)',
        isTrue,
        reason: 'got: $v',
      );
    });

    test('NSCameraUsageDescription present', () {
      expect(_plistString(doc, 'NSCameraUsageDescription'), isNotNull);
    });

    test('NSMicrophoneUsageDescription present', () {
      expect(_plistString(doc, 'NSMicrophoneUsageDescription'), isNotNull);
    });

    test('NSSpeechRecognitionUsageDescription present', () {
      expect(_plistString(doc, 'NSSpeechRecognitionUsageDescription'), isNotNull);
    });
  });
}
```

- [ ] **Step 2: Rodar — falha esperada por drift**

```bash
cd apps/mobile && flutter test test/contract/info_plist_parity_test.dart
```

Expected: `CFBundleDisplayName == AppIdentity.displayName` FALHA com `Expected: 'Raro Camera' Actual: 'Raro Mobile'`. Outras chaves podem falhar se ausentes.

Esse é o gate documentando o drift. Será corrigido na Task 16.

- [ ] **Step 3: Criar `apps/mobile/test/contract/android_manifest_parity_test.dart`**

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:raro_shared/raro_shared.dart';
import 'package:xml/xml.dart';

void main() {
  group('Family 10 — AndroidManifest parity', () {
    final manifest = XmlDocument.parse(
      File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
    );

    test('declared permissions are superset of PermissionsContract.android', () {
      final declared = manifest
          .findAllElements('uses-permission')
          .map((e) => e.getAttribute('android:name'))
          .whereType<String>()
          .toSet();
      for (final required in PermissionsContract.android) {
        expect(declared, contains(required),
            reason:
                'missing permission: $required (declared: $declared)');
      }
    });
  });
}
```

- [ ] **Step 4: Rodar**

```bash
cd apps/mobile && flutter test test/contract/android_manifest_parity_test.dart
```

Expected: pode falhar se manifest não declarou permissions. Será corrigido na Task 16.

- [ ] **Step 5: Commit (testes podem estar vermelhos — proposital)**

```bash
git add apps/mobile/test/contract/
git commit -m "test(contract): add info_plist + android_manifest parity gates"
```

---

### Task 15: Criar gates restantes — screen paths + bridge channels + analytics events

**Files:**
- Create: `apps/mobile/test/contract/screen_paths_unique_test.dart`
- Create: `apps/mobile/test/contract/bridge_channels_parity_test.dart`
- Create: `apps/mobile/test/contract/analytics_events_used_test.dart`

- [ ] **Step 1: Criar `apps/mobile/test/contract/screen_paths_unique_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_shared/raro_shared.dart';

void main() {
  group('Family 8 — AppScreen + AppModal uniqueness', () {
    test('AppScreen paths are unique', () {
      final paths = AppScreen.values.map((s) => s.path).toList();
      expect(paths.toSet().length, paths.length);
    });

    test('AppScreen analyticsNames are unique', () {
      final names = AppScreen.values.map((s) => s.analyticsName).toList();
      expect(names.toSet().length, names.length);
    });

    test('AppModal analyticsNames are unique', () {
      final names = AppModal.values.map((m) => m.analyticsName).toList();
      expect(names.toSet().length, names.length);
    });
  });
}
```

- [ ] **Step 2: Criar `apps/mobile/test/contract/bridge_channels_parity_test.dart`**

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:raro_shared/raro_shared.dart';

const _expectedFiles = {
  'pigeons/camera_api.dart': BridgeChannels.camera,
  'pigeons/replay_buffer_api.dart': BridgeChannels.replayBuffer,
  'pigeons/voice_api.dart': BridgeChannels.voice,
  'pigeons/volume_api.dart': BridgeChannels.volume,
};

void main() {
  group('Family 3/4 — Pigeon schemas reference canonical channels', () {
    test('each pigeons/*.dart exists and references its channel suffix', () {
      for (final entry in _expectedFiles.entries) {
        final f = File(entry.key);
        expect(f.existsSync(), isTrue, reason: 'missing ${entry.key}');
        final content = f.readAsStringSync();
        final last = entry.value.split('/').last;
        expect(content.contains(last), isTrue,
            reason: '${entry.key} does not reference "$last"');
      }
    });

    test('BridgeChannels.camera ends with /camera', () {
      expect(BridgeChannels.camera, endsWith('/camera'));
    });
  });
}
```

- [ ] **Step 3: Criar `apps/mobile/test/contract/analytics_events_used_test.dart`**

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Iterable<File> _scanDart(String root) sync* {
  final dir = Directory(root);
  if (!dir.existsSync()) return;
  for (final e in dir.listSync(recursive: true)) {
    if (e is File &&
        e.path.endsWith('.dart') &&
        !e.path.endsWith('.g.dart') &&
        !e.path.endsWith('.tailor.dart') &&
        !e.path.contains('/generated/')) {
      yield e;
    }
  }
}

void main() {
  group('Family 6 — analytics logEvent uses AnalyticsEvents.*', () {
    test('no logEvent with string literal name', () {
      final hits = <String>[];
      final pattern = RegExp(r"logEvent\s*\(\s*name:\s*'([^']+)'");
      for (final f in _scanDart('lib')) {
        final content = f.readAsStringSync();
        for (final m in pattern.allMatches(content)) {
          hits.add('${f.path}: ${m.group(1)}');
        }
      }
      expect(hits, isEmpty,
          reason: 'logEvent with literal:\n${hits.join("\n")}');
    });
  });
}
```

- [ ] **Step 4: Rodar suite contract completa**

```bash
cd apps/mobile && flutter test test/contract/
```

Expected: forbidden_literals + screen_paths + bridge_channels + analytics_events verdes. `info_plist_parity` ainda vermelho (drift pendente). `android_manifest_parity` depende do estado atual do manifest.

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/test/contract/
git commit -m "test(contract): add screen + bridge + analytics gates"
```

---

### Task 16: Corrigir drift Info.plist + AndroidManifest

**Files:**
- Modify: `apps/mobile/ios/Runner/Info.plist`
- Possibly Modify: `apps/mobile/android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Localizar drift no Info.plist**

```bash
grep -n "Raro Mobile" apps/mobile/ios/Runner/Info.plist
```

Expected: `10:	<string>Raro Mobile</string>`.

- [ ] **Step 2: Trocar para "Raro Camera"**

Edit `apps/mobile/ios/Runner/Info.plist` linha do `<string>Raro Mobile</string>`:

De:
```xml
	<string>Raro Mobile</string>
```

Para:
```xml
	<string>Raro Camera</string>
```

- [ ] **Step 3: Verificar/adicionar chaves de permissão obrigatórias**

```bash
grep -E "NSCameraUsageDescription|NSMicrophoneUsageDescription|NSSpeechRecognitionUsageDescription" apps/mobile/ios/Runner/Info.plist
```

Se alguma faltar, adicionar antes do `</dict>` final:

```xml
	<key>NSCameraUsageDescription</key>
	<string>A Raro Camera precisa da câmera para gravar vídeos.</string>
	<key>NSMicrophoneUsageDescription</key>
	<string>A Raro Camera precisa do microfone para capturar áudio.</string>
	<key>NSSpeechRecognitionUsageDescription</key>
	<string>A Raro Camera usa reconhecimento de voz no dispositivo para detectar "Raro".</string>
```

(Adicionar apenas as que estiverem ausentes.)

- [ ] **Step 4: Verificar AndroidManifest**

```bash
grep -E "android.permission.CAMERA|android.permission.RECORD_AUDIO" apps/mobile/android/app/src/main/AndroidManifest.xml
```

Se faltar alguma, abrir `apps/mobile/android/app/src/main/AndroidManifest.xml` e adicionar logo após a abertura de `<manifest ...>`:

```xml
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
```

- [ ] **Step 5: Rodar contract tests — todos verdes esperados**

```bash
cd apps/mobile && flutter test test/contract/
```

Expected: 6 arquivos contract todos verdes.

- [ ] **Step 6: Verificar grep zerou drift**

```bash
grep -r "Raro Mobile" apps/ packages/ docs/ || echo "OK: sem drift"
```

Expected: `OK: sem drift`.

- [ ] **Step 7: Commit**

```bash
git add apps/mobile/ios/Runner/Info.plist apps/mobile/android/app/src/main/AndroidManifest.xml
git commit -m "fix(identity): correct ios display name + ensure permission keys"
```

---

### Task 17: Hook block-forbidden-terms + settings + lefthook step

**Files:**
- Create: `.claude/hooks/block-forbidden-terms.sh`
- Modify: `.claude/settings.json`
- Modify: `lefthook.yml`
- Modify: `apps/mobile/package.json`

- [ ] **Step 1: Criar `.claude/hooks/block-forbidden-terms.sh`**

```bash
#!/usr/bin/env bash
# block-forbidden-terms.sh — bloqueia termos de marca proibidos
# Trigger: PreToolUse (Write, Edit, MultiEdit)
# Recebe stdin JSON com {tool_input: {content|new_string: "..."}}
set -euo pipefail

input="$(cat)"

content="$(printf '%s' "$input" | python3 -c "
import json, sys
try:
    d = json.loads(sys.stdin.read())
    ti = d.get('tool_input') or {}
    parts = [ti.get('content',''), ti.get('new_string','')]
    print('\n'.join([p for p in parts if p]))
except Exception:
    pass
")"

if [ -z "$content" ]; then
  exit 0
fi

# Lista canônica precisa bater com packages/shared/lib/src/contract/forbidden_terms.dart
for term in 'OkCamera' 'Ok Camera' 'hey OkCamera' 'okCamera' 'ok_camera'; do
  if printf '%s' "$content" | grep -qF "$term"; then
    echo "🚫 block-forbidden-terms: detected \"$term\". Wake word is \"Raro\" — see ADR-0009 + CLAUDE.md Seção 11." >&2
    exit 1
  fi
done

exit 0
```

- [ ] **Step 2: Tornar executável**

```bash
chmod +x .claude/hooks/block-forbidden-terms.sh
```

- [ ] **Step 3: Testar bloqueio**

```bash
echo '{"tool_input":{"file_path":"foo.dart","content":"const x = \"OkCamera\";"}}' | .claude/hooks/block-forbidden-terms.sh
echo "exit code: $?"
```

Expected: stderr `🚫 block-forbidden-terms: detected "OkCamera"...` + exit code 1.

- [ ] **Step 4: Testar permissão**

```bash
echo '{"tool_input":{"file_path":"foo.dart","content":"const wake = \"Raro\";"}}' | .claude/hooks/block-forbidden-terms.sh
echo "exit code: $?"
```

Expected: exit code 0, sem stderr.

- [ ] **Step 5: Registrar hook em `.claude/settings.json`**

Edit `.claude/settings.json` — no array `PreToolUse[0].hooks`, adicionar (após `warn-adr-drift.sh`):

```json
          { "type": "command", "command": ".claude/hooks/block-forbidden-terms.sh" }
```

(Não esquecer da vírgula no item anterior.)

- [ ] **Step 6: Adicionar script `test:contract` em `apps/mobile/package.json`**

Edit `apps/mobile/package.json` — em `scripts`, adicionar (antes do `"test":` existente para manter ordem):

```json
    "test:contract": "flutter test test/contract/",
```

- [ ] **Step 7: Adicionar step em `lefthook.yml` pre-push**

Edit `lefthook.yml` — em `pre-push.jobs`, adicionar:

```yaml
    - name: contract-tests
      run: bun --filter @raro/mobile run test:contract
```

- [ ] **Step 8: Verificar lefthook**

```bash
lefthook validate || echo "lefthook tooling may not be installed locally; ok"
```

- [ ] **Step 9: Commit**

```bash
git add .claude/ lefthook.yml apps/mobile/package.json
git commit -m "feat(harness): add block-forbidden-terms hook + pre-push contract gate"
```

---

### Task 18: CHANGELOG + session log

**Files:**
- Modify: `docs/10-CHANGELOG.md`
- Create: `docs/sessions/0002-api-contract-shared.md`
- Modify: `docs/sessions/0001-INDEX.md`

- [ ] **Step 1: Adicionar entrada em CHANGELOG**

Edit `docs/10-CHANGELOG.md` — adicionar no topo, logo após qualquer cabeçalho introdutório:

```markdown
## [Unreleased] — 2026-05-26

### Added
- **packages/shared 0.2.0**: reorganized into 12 anti-drift families (identity, voice, subscription, enums, screens, analytics events + payloads, storage, bridges, permissions, contract). Barrel export at `raro_shared.dart`. ADR-0013.
- Pigeon ^26.3.4 + 4 schemas in `apps/mobile/pigeons/` generating Dart + Swift + Kotlin native bridge contracts.
- Theme Tailor ^3.1.3 with `RaroColors`, `RaroRadii`, `RaroSpacing`, `RaroDurations` as `ThemeExtension`s in `apps/mobile/lib/core/theme/`.
- 6 contract gate tests in `apps/mobile/test/contract/` (forbidden literals, info plist parity, android manifest parity, screen uniqueness, bridge parity, analytics gate).
- `.claude/hooks/block-forbidden-terms.sh` blocking `OkCamera`/variants in Write/Edit/MultiEdit.
- `lefthook` pre-push step running `test:contract`.

### Fixed
- `ios/Runner/Info.plist` `CFBundleDisplayName` corrected from `"Raro Mobile"` to `"Raro Camera"`.

### Changed
- Blueprint Sections 2.2, 2.10, 9 reference ADR-0013.
```

- [ ] **Step 2: Criar session log**

```bash
ls docs/sessions/
```

Identificar próximo número. Criar `docs/sessions/0002-api-contract-shared.md`:

```markdown
# Session 0002 — api-contract-shared

- **Date:** 2026-05-26
- **Branch:** `feat/api-contract-shared`
- **Spec:** `docs/superpowers/specs/2026-05-25-api-contract-shared-design.md`
- **Plan:** `docs/superpowers/plans/2026-05-26-api-contract-shared.md`
- **ADR:** 0013

## Summary

Implementou o contrato anti-drift do projeto materializando 12 famílias em fonte única (packages/shared barrel), adicionando Pigeon (4 schemas) e Theme Tailor (4 ThemeExtensions), criando 6 testes contract em `apps/mobile/test/contract/`, hook `block-forbidden-terms.sh`, lefthook pre-push gate e corrigindo drift do `Info.plist`.

## Files touched

(gerado por `git log --stat develop..HEAD`)

## Verification

- `bun --filter @raro/shared run test`: 28+ verdes
- `bun --filter @raro/mobile run analyze`: zero issues
- `bun --filter @raro/mobile run test`: smoke + 6 contract suites verdes
- `grep -r "Raro Mobile" .`: vazio
- `grep -rE "OkCamera|Ok Camera|hey OkCamera|okCamera" apps/ packages/ docs/ .claude/`: vazio
- `.claude/hooks/block-forbidden-terms.sh` testado bloqueando + permitindo
```

- [ ] **Step 3: Atualizar INDEX**

Edit `docs/sessions/0001-INDEX.md` — adicionar linha após cabeçalho da tabela:

```markdown
| [0002](0002-api-contract-shared.md) | 2026-05-26 | api-contract-shared (rm-2 spec bloqueante) | `feat/api-contract-shared` | (commits da sessão) |
```

- [ ] **Step 4: Bump version em packages/shared**

Edit `packages/shared/pubspec.yaml` — `version: 0.1.0` → `version: 0.2.0`.

- [ ] **Step 5: Commit**

```bash
git add docs/ packages/shared/pubspec.yaml
git commit -m "docs(session): record api-contract-shared + bump shared to 0.2.0"
```

---

### Task 19: Validação final end-to-end

- [ ] **Step 1: Rodar tudo do zero**

```bash
bun install
bun --filter @raro/mobile run pub:get
bun --filter @raro/mobile run pigeon
bun --filter @raro/mobile run codegen
bun --filter @raro/shared run test
bun --filter @raro/mobile run analyze
bun --filter @raro/mobile run test
```

Expected: tudo verde, zero warnings.

- [ ] **Step 2: Verificar drift zerado**

```bash
grep -r "Raro Mobile" apps/ packages/ docs/ || echo "OK"
grep -rE "OkCamera|Ok Camera|hey OkCamera|okCamera" apps/ packages/ docs/ .claude/ || echo "OK"
```

Expected: `OK` em ambos.

- [ ] **Step 3: Build iOS smoke**

```bash
cd apps/mobile && flutter clean && flutter build ios --no-codesign --debug
```

Expected: build sucesso.

- [ ] **Step 4: Build Android smoke**

```bash
cd apps/mobile && flutter build apk --debug
```

Expected: build sucesso.

- [ ] **Step 5: Invocar validator subagent**

Via Agent tool:

```
description: Validate api-contract-shared spec completion
subagent_type: validator
prompt: Audite cumprimento da spec docs/superpowers/specs/2026-05-25-api-contract-shared-design.md no branch feat/api-contract-shared. Verifique cada Observable goal contra estado atual do repo. Liste qualquer item não cumprido. Não modifique arquivos. Reporte em ≤300 palavras.
```

Expected: validator confirma cumprimento ou lista pendências objetivas.

- [ ] **Step 6: Resolver pendências do validator (se houver)**

Para cada item listado, criar commit de fix correspondente.

- [ ] **Step 7: Push branch (sem PR automático)**

```bash
git push -u origin feat/api-contract-shared
```

Não criar PR sem confirmação explícita do usuário.

---

## Done when

- [ ] Todas atomic tasks 1-19 ✅
- [ ] `bun --filter @raro/shared run test`: 28+ testes verdes
- [ ] `bun --filter @raro/mobile run analyze`: zero issues
- [ ] `bun --filter @raro/mobile run test`: smoke + 6 contract suites verdes
- [ ] `bun --filter @raro/mobile run pigeon`: 4 schemas geram 12 arquivos (4 dart + 4 swift + 4 kotlin)
- [ ] `bun --filter @raro/mobile run codegen`: theme tailor gera `.tailor.dart`
- [ ] `flutter build ios --no-codesign --debug` sucesso
- [ ] `flutter build apk --debug` sucesso
- [ ] `grep -r "Raro Mobile" .` retorna vazio
- [ ] `grep -rE "OkCamera|Ok Camera|hey OkCamera|okCamera" .` retorna vazio
- [ ] Hook `block-forbidden-terms.sh` testado bloqueando + permitindo
- [ ] ADR-0013 commitado em `docs/decisions/`
- [ ] Blueprint atualizado (Seções 2.2, 2.10, 9)
- [ ] CHANGELOG atualizado
- [ ] Session log 0002 criado + INDEX atualizado
- [ ] `packages/shared` versão bumped para 0.2.0
- [ ] Validator subagent confirma cumprimento da spec
- [ ] Branch `feat/api-contract-shared` ready for review

## Rollback plan

Se algo der errado:

1. `git revert <commit>` (não `reset --hard`) — preserva histórico
2. Atualizar `docs/10-CHANGELOG.md` com nota de revert
3. Spec marcada como `Superseded by ...` ou `Reverted` se for o caso
4. Session log 0003 documenta motivo
5. **Não** deletar branch antes do revert estar mergeado em `develop`

---

## Self-review (executado em 2026-05-26)

- **Spec coverage:** cada uma das 12 famílias tem task correspondente. Família 1 (identity) → Task 3 + 14 + 16. Família 2 (invariants) → Task 4 + 8 + 13. Família 3 (channels) → Task 8 + 11 + 15. Família 4 (bridge methods) → Task 11. Família 5 (enums) → Task 5. Família 6 (events) → Task 6 + 15. Família 7 (payloads) → Task 6. Família 8 (screens) → Task 7 + 15. Família 9 (storage) → Task 8. Família 10 (permissions) → Task 8 + 14 + 16. Família 11 (tokens) → Task 12 + 13. Família 12 (copy) → escopo declarado out-of-scope na spec; gate documentado mas implementação deferida.
- **Placeholders:** nenhum `TBD`, `TODO`, `implement later`, ou bloco vazio. Todo step tem código completo ou comando com expected output.
- **Type consistency:** `AppScreen.path`/`AppScreen.analyticsName` consistente em Tasks 7, 15. `BridgeChannels.{camera, replayBuffer, voice, volume}` consistente em Tasks 8, 11, 15. `PermissionsContract.ios` (Map) + `.android` (List) consistente em Tasks 8, 14, 16. `RaroColors.dark`/`RaroRadii.dark`/etc. consistente em Task 12.
- **Ordem:** tasks dependentes de barrel `raro_shared.dart` (criado em Task 3) só rodam depois. Tasks 14 (gates de parity) e 16 (correção de drift) ordenadas para que gate falhe primeiro e fix vede em seguida — TDD em manifesto.
- **TDD:** Tasks 3-8 escrevem teste antes do código. Tasks 13-15 (gates) escrevem teste primeiro. Task 16 corrige código pra deixar gate da Task 14 verde.
- **Commits granulares:** 19 commits suggested, cada um com 1 mudança lógica e mensagem conventional válida.
