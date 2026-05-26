# spec-001 — API Contract (packages/shared expansion)

> **Esta spec é bloqueante.** Todas as outras 19 specs dependem dela. Sem o API contract completo em `packages/shared/`, features vão duplicar tipos, criar enums divergentes e espalhar regras de negócio. Esta é a fundação tipada do app.

## Metadados

| Campo | Valor |
|---|---|
| **Sizing** | Medium |
| **Dependências** | Apenas bootstrap (Fases 1-5 completas) |
| **Bloqueia** | Specs 002 a 020 (todas) |
| **Owner** | Eduardo (decisão de domínio) + implementer agent |
| **Branch sugerido** | `feat/api-contract-shared` |

## Princípio (não negociável)

> **Toda type/enum/constant compartilhada entre features ou entre Dart e Native vive em `packages/shared/`.** Feature em `apps/mobile/lib/features/<f>/` **importa**, nunca duplica. Se você está prestes a escrever `enum X` num feature folder, pare: ou já existe em shared, ou é proposta nova para shared.

## Reading order

1. [docs/Blueprint.md](../Blueprint.md) — Seção 2 (stack), Seção 3 (arquitetura)
2. [docs/05-FEATURES.md](../05-FEATURES.md) — M01–M08 e seus tipos
3. [docs/06-SCREENS.md](../06-SCREENS.md) — P01–P10, M01–M03 (vai gerar `ScreenId` enum)
4. [docs/07-NATIVE-BRIDGES.md](../07-NATIVE-BRIDGES.md) — 4 Method Channels e contratos
5. [packages/shared/lib/raro_shared.dart](../../packages/shared/lib/raro_shared.dart) — exports atuais
6. ADRs relacionados: 0001 (stack), 0005 (Riverpod 3), 0009 (wake word), 0010 (dual plans), 0011 (volume control)

## Problem

Hoje `packages/shared/` tem 9 arquivos cobrindo identidade, voice config, subscription, 6 enums básicos e analytics events. Falta:

1. **Result types dos native bridges** — quando spec-007 (camera) for implementada, precisará retornar `{recordingId, filePath, duration, codec}`. Se essa shape não está em shared, ela será inventada em `lib/features/camera/data/` e depois duplicada em outra feature.
2. **State machines de domínio** — `RecordingState`, `SubscriptionStatus`, `PermissionStatus`, `VoiceListeningState`. Sem essas, cada feature inventa o próprio enum e os widgets viram `if state == 'idle'` strings mágicas.
3. **Error types padronizados** — sealed class `RaroError` com sub-types (`CameraError`, `BridgeError`, `SubscriptionError`). Sem isso, vai espalhar `Exception()` genéricos com `String message`.
4. **Screen IDs** — `enum ScreenId { p01Splash, ... }`. Sem isso, design-fidelity-checker recebe string ("P05") e validator não pode garantir match contra os ScreenId que existem.
5. **Theme tokens** parcialmente compartilhados — cores e tipos de gradient como enum (`RaroColor`, `RaroGradient`), implementação Flutter fica em `apps/mobile/lib/core/theme/`.
6. **Domain models de assinatura** — `Plan` (monthly | yearly com preço, trial, sku), `Entitlement`.

## Out of scope (FORA desta spec)

- Implementação Flutter dos tokens visuais (cores reais como `Color(0xFFff2d55)`) — fica em spec-004 (`theme-design-tokens`).
- Implementação dos Method Channels (Dart side) — fica em spec-007/008/009/010.
- Configuração do RevenueCat ou Firebase — fica em spec-002/003.
- Geração de `freezed` boilerplate — usaremos `sealed class` + `records` nativos do Dart 3, evitando dep extra (decisão a confirmar via researcher).

## Q-table

| # | Question | Answer |
|---|----------|--------|
| 1 | Usar `freezed` (gera code) ou Dart 3 `sealed class` + records (zero dep)? | Dart 3 nativo, sem freezed. Razão: menos build_runner pressure, código mais legível, Dart 3.11 já maduro. Se surgir caso edge (union types complexos), abrir ADR. |
| 2 | Equatable vs `operator ==` manual? | `operator ==` manual nos value objects (poucos), records do Dart 3 já cobrem equality automaticamente. Sem dep `equatable`. |
| 3 | Onde fica `ScreenId`? | `packages/shared/lib/src/ui/screen_id.dart` — não é constante de domínio, mas é compartilhado entre design-fidelity-checker, routing e analytics events. |
| 4 | Errors: sealed class única ou hierarquia por feature? | Sealed `RaroError` base + sub-sealed `BridgeError`, `CameraError`, `SubscriptionError`, `VoiceError`, `PermissionError`. Permite exhaustive pattern matching. |
| 5 | Theme tokens em shared ou em mobile? | Enum em shared (`RaroColor`, `RaroGradient` apenas identidade), valores em mobile (Color objects). Razão: shared é Dart-puro, sem dep Flutter. |
| 6 | `Plan` precisa de `Money` type? | Não inicialmente — usar `int priceCentavosBRL` + função utility `formatBRL()`. Evita prematura abstração de Money. |
| 7 | Versionar API contract com SemVer? | Sim — `packages/shared/pubspec.yaml` versão 0.1.0 → 0.2.0 quando spec-001 mergear. Breaking changes futuras = bump major mesmo dentro do monorepo. |

## Observable goals (testes em device — todos verificáveis)

- [ ] **G1**: `dart test packages/shared` passa todos os testes, incluindo testes novos de invariantes (sem duplicação, sem typo em const)
- [ ] **G2**: `flutter analyze apps/mobile` continua zero issues após mobile importar tipos novos
- [ ] **G3**: Smoke test do mobile (existente) continua verde — não pode quebrar nada
- [ ] **G4**: Importar `package:raro_shared/raro_shared.dart` em qualquer feature folder dá acesso aos novos tipos sem precisar import secundário
- [ ] **G5**: Teste de "no duplicate enum" — script grep que verifica que `apps/mobile/lib/` NÃO redefine enum/sealed que existe em shared
- [ ] **G6**: ADR 0013 escrito explicando decisão de Dart 3 sealed (não freezed) e versionamento

## Atomic micro-sprints (cada um é 1 commit)

### µ-sprint 1.1 — Result types dos native bridges

**Files:**
- `packages/shared/lib/src/bridges/camera_contract.dart`
- `packages/shared/lib/src/bridges/replay_buffer_contract.dart`
- `packages/shared/lib/src/bridges/voice_contract.dart`
- `packages/shared/lib/src/bridges/volume_contract.dart`
- `packages/shared/lib/raro_shared.dart` (adicionar exports)
- `packages/shared/test/bridges/contracts_test.dart`

**Tipos a definir:**

```dart
// camera_contract.dart
class LensDescriptor {
  const LensDescriptor({required this.lens, required this.focalLengthMm, required this.available});
  final Lens lens;
  final double focalLengthMm;
  final bool available;
}

class CameraCaptureResult {
  const CameraCaptureResult({required this.recordingId, required this.filePath, required this.durationMs, required this.codec});
  final String recordingId;
  final String filePath;
  final int durationMs;
  final VideoCodec codec;
}

enum VideoCodec { h264, h265 }
```

Análogo para `replay_buffer_contract.dart`, `voice_contract.dart`, `volume_contract.dart` — ver [docs/07-NATIVE-BRIDGES.md](../07-NATIVE-BRIDGES.md) para shapes completas.

**Verification:**
- `dart analyze packages/shared` zero
- `dart test packages/shared/test/bridges/contracts_test.dart` verde
- Cada contract tem teste de equality + serialization round-trip

**Commit:** `feat(shared): native bridges contracts (camera/replay/voice/volume) — spec-001 µ-sprint 1.1`

---

### µ-sprint 1.2 — Domain state machines

**Files:**
- `packages/shared/lib/src/domain/recording_state.dart`
- `packages/shared/lib/src/domain/subscription_status.dart`
- `packages/shared/lib/src/domain/permission_state.dart`
- `packages/shared/lib/src/domain/voice_listening_state.dart`
- `packages/shared/lib/raro_shared.dart` (exports)
- `packages/shared/test/domain/state_machines_test.dart`

**Tipos:**

```dart
enum RecordingState { idle, buffering, recording, paused, savingClip }

enum SubscriptionStatus { notSubscribed, trialing, active, expired, gracePeriod }

enum PermissionState { notRequested, granted, denied, permanentlyDenied }

enum VoiceListeningState { off, listening, restarting, error }
```

**Verification:**
- Cada enum tem teste de exhaustive pattern matching (compile-time guarantee)
- `dart test` verde

**Commit:** `feat(shared): domain state machines (recording, subscription, permission, voice) — spec-001 µ-sprint 1.2`

---

### µ-sprint 1.3 — Error types sealed

**Files:**
- `packages/shared/lib/src/errors/raro_error.dart` (sealed base)
- `packages/shared/lib/src/errors/bridge_error.dart`
- `packages/shared/lib/src/errors/camera_error.dart`
- `packages/shared/lib/src/errors/voice_error.dart`
- `packages/shared/lib/src/errors/subscription_error.dart`
- `packages/shared/lib/src/errors/permission_error.dart`
- `packages/shared/lib/raro_shared.dart` (exports)
- `packages/shared/test/errors/errors_test.dart`

**Estrutura:**

```dart
sealed class RaroError {
  const RaroError({required this.code, required this.message});
  final String code;
  final String message;
}

sealed class CameraError extends RaroError { ... }
final class CameraLensNotAvailable extends CameraError { ... }
final class CameraPermissionDenied extends CameraError { ... }
```

**Verification:**
- Exhaustive `switch` em `RaroError` cobre todos sub-types (compile-time check)
- `code` é único por erro (teste assert)

**Commit:** `feat(shared): sealed error hierarchy raro_error — spec-001 µ-sprint 1.3`

---

### µ-sprint 1.4 — ScreenId + theme tokens enums

**Files:**
- `packages/shared/lib/src/ui/screen_id.dart`
- `packages/shared/lib/src/ui/raro_color.dart`
- `packages/shared/lib/src/ui/raro_gradient.dart`
- `packages/shared/lib/src/ui/raro_font_family.dart`
- `packages/shared/lib/raro_shared.dart` (exports)
- `packages/shared/test/ui/screen_id_test.dart`

**Tipos:**

```dart
enum ScreenId {
  p01Splash, p02Onboarding1, p03Onboarding2, p04Permissions,
  p05Camera, p05aLock, p06Settings, p07Gallery, p08Preview,
  p09Paywall, p10Checkout, p11Terms, p12Privacy,
  m01SubscriptionPopup, m02XiaomiOnboarding, m03BluetoothConnected,
}

enum RaroColor {
  bgDeep, bgElev, bgCard, ink, inkDim, inkFaint,
  border, borderBright, raroRed,
}

enum RaroGradient { linear7Colors, radial5Colors, redRadial }

enum RaroFontFamily { spaceGrotesk, inter, jetBrainsMono }
```

**Verification:**
- `ScreenId` cobre todas telas listadas em `docs/06-SCREENS.md` (teste de count)
- `RaroColor` cobre tokens listados no Blueprint Seção 4.1 (teste)

**Commit:** `feat(shared): ui enums screen_id, raro_color, raro_gradient, raro_font_family — spec-001 µ-sprint 1.4`

---

### µ-sprint 1.5 — Domain models de subscription

**Files:**
- `packages/shared/lib/src/domain/plan.dart`
- `packages/shared/lib/src/domain/entitlement.dart`
- `packages/shared/lib/src/utils/money_format.dart`
- `packages/shared/lib/raro_shared.dart` (exports)
- `packages/shared/test/domain/plan_test.dart`

**Tipos:**

```dart
enum PlanType { monthly, yearly }

class Plan {
  const Plan({required this.type, required this.sku, required this.priceCentavosBRL, required this.trialDays});
  final PlanType type;
  final String sku;
  final int priceCentavosBRL;
  final int trialDays;
  String get formattedPrice => formatBRL(priceCentavosBRL);
}

class Entitlement {
  const Entitlement({required this.id, required this.isActive, required this.expirationDate});
  final String id;  // 'premium'
  final bool isActive;
  final DateTime? expirationDate;
}

String formatBRL(int centavos) => 'R\$ ${(centavos / 100).toStringAsFixed(2).replaceAll('.', ',')}';
```

**Verification:**
- `Plan(monthly).priceCentavosBRL == 990` e `formattedPrice == 'R$ 9,90'`
- `Plan(yearly).priceCentavosBRL == 8990` e `formattedPrice == 'R$ 89,90'`
- `Plan` consome `SubscriptionSkus.monthly`/`yearly` (não duplica)

**Commit:** `feat(shared): plan + entitlement domain models — spec-001 µ-sprint 1.5`

---

### µ-sprint 1.6 — Guard test "no duplicate enum"

**Files:**
- `packages/shared/test/no_duplicate_guard_test.dart`

**Test estratégia:**

```dart
test('apps/mobile/lib does not redefine any enum exported by raro_shared', () {
  final sharedEnums = scanEnumsInDir('packages/shared/lib');
  final mobileEnums = scanEnumsInDir('apps/mobile/lib');
  for (final e in mobileEnums) {
    expect(sharedEnums, isNot(contains(e.name)),
      reason: 'enum ${e.name} duplicada em ${e.path} — está em packages/shared, importe de lá');
  }
});
```

**Verification:**
- Teste roda como parte do `dart test packages/shared`
- Falha clara se alguém criar `enum Lens` em `apps/mobile/`

**Commit:** `test(shared): guard contra duplicação de enum entre shared e mobile — spec-001 µ-sprint 1.6`

---

### µ-sprint 1.7 — Versionamento + ADR 0013

**Files:**
- `packages/shared/pubspec.yaml` (bump version 0.1.0 → 0.2.0)
- `docs/decisions/0013-api-contract-shared-sealed-classes.md`
- `docs/10-CHANGELOG.md` (entry)
- `docs/index.md` (referenciar ADR 0013)

**ADR 0013 deve cobrir:**
- Decisão: Dart 3 sealed classes + records, sem freezed
- Decisão: SemVer no `packages/shared`
- Decisão: enums e domain types vivem em shared, NUNCA duplicados em feature folders
- Consequências e como reverter

**Verification:**
- `flutter pub get --directory=apps/mobile` resolve nova versão de shared
- ADR 0013 referenciado de `docs/index.md` e `docs/04-ROADMAP.md`
- `docs-lint` zero issues

**Commit:** `docs(blueprint): adr 0013 + bump shared 0.2.0 + changelog — spec-001 µ-sprint 1.7`

---

## Done when (definition of done desta spec)

- [ ] 7 micro-sprints completos com commits separados
- [ ] `dart test packages/shared` 100% verde (incluindo guard test)
- [ ] `flutter analyze apps/mobile` zero issues
- [ ] `flutter test apps/mobile` continua verde
- [ ] `bun run lint && bun run typecheck && bun run test` global zero issues
- [ ] `validator` agent confirma cumprimento da spec (zero gaps observáveis)
- [ ] ADR 0013 mergeado em `docs/decisions/`
- [ ] CHANGELOG atualizado
- [ ] Session log registrado em `docs/sessions/0002-*.md`
- [ ] Versão de `packages/shared` bumped para 0.2.0

## Hooks/Agents pipeline desta spec

- **PreToolUse `warn-adr-drift`**: vai disparar ao editar `pubspec.yaml` — ADR 0013 deve estar aberto antes
- **PostToolUse `format-dart`**: roda a cada Edit em `.dart`
- **PostToolUse `run-riverpod-codegen`**: NÃO se aplica (sem `@riverpod`)
- **SessionStart `reinject-roadmap`**: lembra que `wakeWord='Raro'`, `freeTrialDays=30` etc.
- **`adr-guardian`**: invocar antes de iniciar — confirma que mudança no `pubspec.yaml` precisa ADR 0013
- **`flutter-test-author`**: invocar para escrever testes red-first dos novos types
- **`implementer`**: agente principal que executa atomic tasks
- **`validator`**: invocar ao fim para audit independente

## Rollback plan

Se a spec precisar ser revertida:
1. `git revert <range de commits da spec-001>` (não `reset --hard`)
2. `packages/shared/pubspec.yaml` volta para 0.1.0
3. ADR 0013 marcado como `Reverted` (não deletado)
4. CHANGELOG nota a reversão
5. Specs dependentes (002-020) ficam bloqueadas até nova versão do contract

## Riscos

| Risco | Severidade | Mitigação |
|---|---|---|
| Dart 3 sealed classes ainda imaturos em produção | 🟡 Médio | Researcher valida cases de produção via Context7/pub.dev antes de µ-sprint 1.3 |
| Importar muito de shared deixa o tree-shaking sofrer | 🟢 Baixo | shared é Dart-puro, sem Flutter; tree-shaking funciona bem |
| Guard test do µ-sprint 1.6 lento (scan de filesystem) | 🟢 Baixo | Limita a `apps/mobile/lib/`; usa `Glob` package se ficar lento |
| Sobre-engenharia (tipos demais antes da feature usar) | 🟠 Alto | **Regra**: só inclua tipo nesta spec se já existe ≥1 spec do roadmap que VAI consumir. Sem "talvez precisa". |

## Referências

- [Blueprint Seção 2.5](../Blueprint.md)
- [Blueprint Seção 4](../Blueprint.md)
- [07-NATIVE-BRIDGES.md](../07-NATIVE-BRIDGES.md)
- ADR 0001 (stack), 0005 (Riverpod), 0009 (wake word), 0010 (dual plans), 0011 (volume)
- Dart 3 sealed classes: https://dart.dev/language/class-modifiers#sealed
