# Bloco Features de Produto — specs 010, 011, 013 a 016

> 6 specs de produto consumindo bridges + paywall. Estabelecem o **valor visível** do app para o usuário. Mistura de Medium e Large. Order dentro do bloco respeita dependências.

## spec-010 — volume-control

| Campo | Valor |
|---|---|
| **Sizing** | Medium |
| **Dependências** | spec-001 (VolumeEvent, BridgeError), spec-007 (camera + record toggle), spec-020 (settings — controlMode toggle) [parcial] |
| **Bloqueia** | nada direto |
| **Branch sugerido** | `feat/volume-control` |
| **Telas afetadas** | P05 (modo Volume OFF), M03 (Bluetooth Connected modal) |
| **ADRs** | 0011 (volume control), novo 0019 (contrato `com.rarocamera/volume`) |

### Problem

Modo "Volume OFF" em Settings → P06 habilita captura de botões físicos: `Volume +` inicia, `Volume −` finaliza. Fones BT (AirPods) que reportam botões como volume disparam modal M03 "Controle conectado". iOS workaround: observer em `AVAudioSession.outputVolume` com restore do volume anterior (não alterar áudio do device).

### Atomic micro-sprints

#### 10.1 — ADR 0019 + contract

**Commit:** `docs(blueprint): adr 0019 contrato volume bridge — spec-010 µ-sprint 10.1`

#### 10.2 — Dart wrapper + provider Riverpod

`volume_method_channel.dart`, `volume_event_channel.dart`, `volume_provider.dart`. **Commit:** `feat(bridge): dart wrapper volume — spec-010 µ-sprint 10.2`

#### 10.3 — iOS: `VolumeButtonObserver.swift`

**Stack validada WebSearch + Apple Developer Forums 2026-05-25:**

3 cuidados obrigatórios (ver memory `raro-pattern-ios-volume-button-kvo-app-store-review`):

1. `AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)` — NÃO `.playback` (ducka outros apps como Spotify)
2. **Restaurar `initialVolume` após capturar evento** — senão volume real do device aumenta a cada "Volume +" interpretado como REC start
3. `observer.invalidate()` no `deinit` — KVO via `NSKeyValueObservation` exige limpeza explícita

Detecção fones BT (para disparar M03):
- Check `AVAudioSession.currentRoute.outputs.first?.portType == .bluetoothA2DP || .bluetoothLE`
- Se primeira ocorrência, disparar M03 com flag persistida em `shared_preferences` (mostrar só 1x por device)

App Store review note (em `docs/setup/app-store-submission-notes.md`): "uses volume buttons as hands-free record control for camera app". Apple aceita esse uso para captura de mídia.

**Commit:** `feat(bridge): ios volume button observer com ambient + restore + bt detect — spec-010 µ-sprint 10.3`

#### 10.4 — Android: `VolumeButtonObserver.kt`

`KeyEvent.KEYCODE_VOLUME_UP/DOWN` em `MainActivity.dispatchKeyEvent()`. **Commit:** `feat(bridge): android volume button observer — spec-010 µ-sprint 10.4`

#### 10.5 — Modal M03 "Controle conectado"

Sheet com ícone bluetooth radial + título + card de instrução + CTA "OK, entendi". Disparado quando `VolumeEvent.source == 'bluetooth_headphone'`. **Commit:** `feat(volume): modal m03 controle bluetooth conectado — spec-010 µ-sprint 10.5`

#### 10.6 — Integração com record toggle

Volume+ → `cameraController.startRecord()`. Volume- → `stopRecord()`. Apenas quando `ControlMode == volume` em Settings. **Commit:** `feat(volume): integra volume buttons com record toggle — spec-010 µ-sprint 10.6`

#### 10.7 — Validator + design-fidelity (M03) + session log

**Commit:** `docs(volume): session log + validator spec-010 — spec-010 µ-sprint 10.7`

### Gates

- Contract test em ambas plataformas
- iOS: validar que `AVAudioSession.outputVolume` restore não vaza áudio
- Manual: testar com AirPods reais que disparam M03

---

## spec-011 — lock-mode

| Campo | Valor |
|---|---|
| **Sizing** | Medium |
| **Dependências** | spec-007 (camera + recording state) |
| **Bloqueia** | spec-020 (settings — lock toggle) |
| **Branch sugerido** | `feat/lock-mode` |
| **Telas afetadas** | P05a (tela escurecida) |
| **ADRs** | 0007 (lock mode vs battery profile) |

### Problem

Modo P05a escurece tela durante gravação para reduzir consumo de bateria. REC dot pulsante + timer mirror. Double-tap sai. iOS: `UIScreen.brightness` para minimum (restore on exit). Android: `Window.attributes.screenBrightness = 0.01`.

### Atomic micro-sprints

#### 11.1 — `LockModeService` em shared (interface)

Comportamento abstrato (entrar lock, sair lock, current state). **Commit:** `feat(shared): lock mode service contract — spec-011 µ-sprint 11.1`

#### 11.2 — iOS: brightness control

Method Channel simples ou plugin `screen_brightness` (researcher avalia). **Commit:** `feat(lock): ios brightness control — spec-011 µ-sprint 11.2`

#### 11.3 — Android: window attributes

**Commit:** `feat(lock): android window brightness control — spec-011 µ-sprint 11.3`

#### 11.4 — Tela P05a + double-tap gesture

`apps/mobile/lib/features/lock_mode/presentation/lock_screen.dart`. Mostra REC dot + timer mirrored do recording state. **Commit:** `feat(lock): tela p05a com rec dot e timer mirror — spec-011 µ-sprint 11.4`

#### 11.5 — Integração com camera_screen

Settings/HUD pode disparar lock mode. Lock mantém recording (não pausa). **Commit:** `feat(lock): integração com camera state — spec-011 µ-sprint 11.5`

#### 11.6 — Medição de consumo de bateria (DoD)

Test manual: gravar 10min em P05 vs P05a (lock) em iPhone real, medir % bateria. Alvo: redução ≥ 50% (Blueprint Seção 11). **Commit:** `test(lock): medição consumo bateria 50% redução vs tela acesa — spec-011 µ-sprint 11.6`

#### 11.7 — Validator + design-fidelity (P05a) + session log

**Commit:** `docs(lock): session log spec-011 — spec-011 µ-sprint 11.7`

### Gates

- `flutter-perf-auditor` valida que lock mode não causa frame drops
- Manual test de medição de bateria obrigatório (não automatizável)

---

## spec-013 — subscription-paywall

| Campo | Valor |
|---|---|
| **Sizing** | Large |
| **Dependências** | spec-001 (Plan, Entitlement, ScreenId), spec-003 (RevenueCat init), spec-012 (i18n se houver) |
| **Bloqueia** | spec-014 (checkout), gate de salvar vídeo (spec-015 gallery) |
| **Branch sugerido** | `feat/subscription-paywall` |
| **Telas afetadas** | P09 (Paywall), M01 (Popup Assinatura) |
| **ADRs** | 0010 (dual plans) |

### Problem

P09 com 2 cards lado a lado (mensal R$ 9,90 / anual R$ 89,90 com badge "MELHOR OFERTA"), free trial 30 dias, restaurar compras, CTA Assinar. M01 popup dispara em P05 quando user sem subscription tenta entrar.

### Pré-condições críticas (do RevenueCat dashboard, ANTES de implementar)

Validado via WebSearch RevenueCat docs 2026-05-25 (ver memory `raro-pattern-revenuecat-trial-app-store-connect`):

- [ ] **App Store Connect:** ambos SKUs com "Introductory Offer" = "Free 1 month" (Apple não permite "30 days" literal — "1 month" é o equivalente)
- [ ] **Google Play Console:** ambos SKUs com "Free trial offer" = 30 dias (literal)
- [ ] **RevenueCat dashboard:** In-App Purchase Key uploaded (para usar StoreKit 2 — Apple deprecou StoreKit 1 no WWDC 2024). Sem essa key, SDK cai para StoreKit 1 legado.
- [ ] **RevenueCat:** offerings com 2 packages (monthly + yearly), produto IDs sincronizados das lojas

Sem essas pré-condições, paywall mostra "30 dias grátis" mas trial não acontece — bug catastrófico. Validator deve confirmar com cliente antes do gate.

### Discrepância Apple vs Google no copy

- Apple "1 month" ≠ 30 dias exatos (ex: 15-fev → 15-mar = 28 dias)
- Google 30 dias = literal
- **Decisão para v1.0:** copy "30 dias grátis" universal (conforme protótipo). Disclaimer pequeno no paywall: "Período de teste varia entre lojas: 1 mês (App Store) ou 30 dias (Google Play)".
- Datas reais no checkout (P10) vêm de `CustomerInfo.entitlements['premium'].expirationDate` retornado por `Purchases.purchasePackage` — não calcular manualmente.

### Atomic micro-sprints

#### 13.1 — Paywall controller (Riverpod) + selectPlan logic

`paywall_controller.dart` (`@riverpod`) — observa Plans, expõe `selectedPlan`, `selectPlan(PlanType)`. **Commit:** `feat(paywall): controller riverpod com selectplan — spec-013 µ-sprint 13.1`

#### 13.2 — UI Paywall (P09)

`paywall_screen.dart` + widgets `plan_card.dart`, `feature_bullet.dart`. Cards lado a lado com border animado quando selected. Badge "MELHOR OFERTA" no anual. **Commit:** `feat(paywall): tela p09 com 2 plan cards animados — spec-013 µ-sprint 13.2`

#### 13.3 — Modal M01 popup assinatura

Disparado quando user sem `Entitlement.active` entra em P05 (delay 450ms). **Commit:** `feat(paywall): modal m01 popup assinatura em p05 — spec-013 µ-sprint 13.3`

#### 13.4 — Restaurar compras

Botão "Restaurar compras" → `subscriptionService.restore()` → atualiza state. **Commit:** `feat(paywall): restaurar compras via revenuecat — spec-013 µ-sprint 13.4`

#### 13.5 — i18n das strings (se spec-012 mergeada)

Mover strings para `.arb` (pt-BR + en + es). Se spec-012 ainda não mergeada, deixa inline e cria débito explícito. **Commit:** `feat(paywall): i18n strings paywall + m01 — spec-013 µ-sprint 13.5`

#### 13.6 — Goldens P09 + M01

`flutter test --update-goldens`. Diff visual aprovado em PR. **Commit:** `test(paywall): goldens p09 + m01 — spec-013 µ-sprint 13.6`

#### 13.7 — Validator + design-fidelity + session log

`design-fidelity-checker` valida P09 e M01 contra protótipo (atenção ao gradient border animado conic, badge MELHOR OFERTA rosa, "30 dias grátis" não "15"). **Commit:** `docs(paywall): session log spec-013 — spec-013 µ-sprint 13.7`

### Gates

- `design-fidelity-checker` obrigatório — P09 tem microinterações complexas (gradient border conic spinning)
- `researcher` confirma SKU IDs com cliente antes de hardcode
- i18n: "30 dias" não "15" em todos idiomas

---

## spec-014 — checkout

| Campo | Valor |
|---|---|
| **Sizing** | Medium |
| **Dependências** | spec-013 (paywall + Plan selecionado) |
| **Bloqueia** | gate completo de salvar |
| **Branch sugerido** | `feat/checkout` |
| **Telas afetadas** | P10 (Checkout) |
| **ADRs** | nenhum novo (cobre 0001 + 0010) |

### Problem

P10 com order summary + 2 payment tiles (Apple Pay / Google Play via RevenueCat) + CTA Confirmar. Fluxo: select method → confirm → RevenueCat purchase flow → success toast → volta P05 com Entitlement ativo.

### Atomic micro-sprints

#### 14.1 — Checkout controller + payment method selection

**Commit:** `feat(checkout): controller riverpod com selectpaymentmethod — spec-014 µ-sprint 14.1`

#### 14.2 — UI P10

Order summary card (logo + plano + período teste 30 dias + cobrança após). 2 tiles Apple/Google. Toast "✓ Assinatura ativa — 30 dias grátis" após sucesso. **Commit:** `feat(checkout): tela p10 com order summary e payment tiles — spec-014 µ-sprint 14.2`

#### 14.3 — Integração RevenueCat purchase flow

`subscriptionService.purchase(selectedPlan)`. Tratamento de erro (`SubscriptionError.userCancelled`, `.networkError`, etc.). **Commit:** `feat(checkout): integração revenuecat purchase com tratamento de erros — spec-014 µ-sprint 14.3`

#### 14.4 — Analytics events

`subscriptionActivated`, `checkoutStarted` disparam. **Commit:** `feat(analytics): eventos subscription activated em checkout — spec-014 µ-sprint 14.4`

#### 14.5 — Goldens + i18n

**Commit:** `feat(checkout): goldens p10 + i18n strings — spec-014 µ-sprint 14.5`

#### 14.6 — Validator + design-fidelity + session log

**Commit:** `docs(checkout): session log spec-014 — spec-014 µ-sprint 14.6`

### Gates

- `design-fidelity-checker` aprova P10
- Manual test em sandbox account de RevenueCat (App Store sandbox + Google Play test track)

---

## spec-015 — gallery

| Campo | Valor |
|---|---|
| **Sizing** | Medium |
| **Dependências** | spec-007 (recording files), spec-008 (replay buffer tags), spec-013 (entitlement gate) |
| **Bloqueia** | spec-016 (preview) |
| **Branch sugerido** | `feat/gallery` |
| **Telas afetadas** | P07 (Galeria) |

### Problem

Grid 3-cols com thumbs de vídeos gravados. Filtros: Todos / Hoje / Esta semana / Raro Replay. Dot indicator nos clips com replay preroll. Tocar thumb → P08 preview. **Gate: salvamento exigiu `Entitlement.active`** — se foi gravado em trial expirado, não está aqui.

### Atomic micro-sprints

#### 15.1 — `VideoLibraryService` em shared (interface)

`list()`, `byFilter(filter)`, `delete(id)`. **Commit:** `feat(shared): video library service contract — spec-015 µ-sprint 15.1`

#### 15.2 — Implementação Flutter (iOS PHPhotoLibrary, Android MediaStore)

`apps/mobile/lib/core/gallery/photo_library_service.dart`. Permissão `PHPhotoLibrary` (iOS) e `READ_MEDIA_VIDEO` (Android API 33+). **Commit:** `feat(gallery): photo library service ios+android — spec-015 µ-sprint 15.2`

#### 15.3 — UI P07 grid 3-cols com thumbnails estáticas

`gallery_screen.dart` + `widgets/video_thumb.dart`. Pills filtro (Todos/Hoje/Esta semana/Raro Replay). Thumb com duration label + dot indicator.

**CRÍTICO — NÃO usar `VideoPlayerController` para thumbs.** Galeria pode ter 100+ vídeos; instanciar N controllers causa OOM (issue #139347 do flutter/flutter, ver memory `raro-pattern-flutter-video-player-disposal`).

Pattern correto:
- Plugin `video_thumbnail ^0.5.x` (researcher confirma versão atual via pub.dev) extrai first frame como `Uint8List`
- Cache em `path_provider.getTemporaryDirectory()/thumbs/<videoId>.jpg`
- `Image.file(cachedThumb)` no grid — leve, rápido, sem leak
- VideoPlayerController só na P08 quando tap no thumb

**Commit:** `feat(gallery): tela p07 grid 3-cols com thumbnails estáticas cacheadas — spec-015 µ-sprint 15.3`

#### 15.4 — Filtros funcionais

Filtro por timestamp (Hoje, Esta semana) e por tag (Raro Replay). **Commit:** `feat(gallery): filtros hoje/semana/raro replay — spec-015 µ-sprint 15.4`

#### 15.5 — Perf: grid lazy + cacheWidth

`ListView.builder` lazy (vai virar GridView.builder), thumbs com `cacheWidth/cacheHeight`. `flutter-perf-auditor` invocado. **Commit:** `perf(gallery): grid lazy + thumb cache — spec-015 µ-sprint 15.5`

#### 15.6 — Goldens P07 + Validator

**Commit:** `docs(gallery): goldens p07 + session log spec-015 — spec-015 µ-sprint 15.6`

### Gates

- `flutter-perf-auditor` obrigatório (grid pode ter 100+ thumbs)
- Permissões iOS/Android validadas

---

## spec-016 — preview

| Campo | Valor |
|---|---|
| **Sizing** | Medium |
| **Dependências** | spec-015 (gallery) |
| **Bloqueia** | nada |
| **Branch sugerido** | `feat/preview` |
| **Telas afetadas** | P08 (Preview) |

### Problem

P08 com player do vídeo + scrubber + info (256MB / 02:30 / H.265) + bottom actions (Compartilhar / Delete / Info). Tap em thumb da P07 abre P08.

### Atomic micro-sprints

#### 16.1 — `video_player` integration com dispose seguro

**Stack validada WebSearch GitHub flutter issues 2026-05-25:**

`video_player ^2.11.1` (pub.dev current) tem histórico de memory leak documentado (issues #26383, #62280, #139347, #146550 — todas fechadas mas exigem pattern correto). Ver memory `raro-pattern-flutter-video-player-disposal`.

Pattern obrigatório:

```dart
class _PreviewScreenState extends ConsumerState<PreviewScreen> {
  late VideoPlayerController _controller;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        if (!_isDisposed && mounted) { // CRÍTICO: race condition guard
          setState(() {});
          _controller.play();
        }
      });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.dispose();
    super.dispose();
  }
}
```

**Verification:**
- Widget test simula navegação rápida (push + pop em <500ms) → sem crash, sem leak
- Manual test: abrir/fechar P08 50 vezes em loop → heap estável (Flutter DevTools)

**Commit:** `feat(preview): video_player com dispose seguro e race condition guard — spec-016 µ-sprint 16.1`

#### 16.2 — UI P08 com scrubber + info card

**Commit:** `feat(preview): tela p08 com player + scrubber + info — spec-016 µ-sprint 16.2`

#### 16.3 — Share Sheet via share_plus

CTA "Compartilhar" → `Share.shareXFiles([XFile(path)])`. **Commit:** `feat(preview): share sheet via share_plus — spec-016 µ-sprint 16.3`

#### 16.4 — Delete com confirmação

Action sheet "Tem certeza?" → `videoLibraryService.delete(id)` → volta P07. **Commit:** `feat(preview): delete com confirmação — spec-016 µ-sprint 16.4`

#### 16.5 — Goldens + Validator

**Commit:** `docs(preview): goldens p08 + session log spec-016 — spec-016 µ-sprint 16.5`

### Gates

- `design-fidelity-checker` aprova P08

---

## Validação cruzada do bloco features

Após 010 + 011 + 013 + 014 + 015 + 016 mergeados:

- [ ] 6 specs completas, todas mergeadas
- [ ] Fluxo completo de produto funciona end-to-end:
  - Boot → P05 → record (voice ou volume ou button) → stop → tentar salvar sem subscription → M01 popup → P09 → P10 → entitlement ativo → P07 galeria mostra clip → P08 preview → compartilhar
- [ ] Lock mode (P05a) testado em device real, reduz bateria 50%+
- [ ] Volume buttons (M03 modal) testado com AirPods reais
- [ ] Paywall testado em sandbox RevenueCat (Apple + Google)
- [ ] Gallery grid 3-cols com 100+ items: scroll smooth (60fps)
- [ ] `bun run lint && typecheck && test` zero issues
- [ ] Todos goldens regerados e aprovados visualmente
- [ ] Session logs em `docs/sessions/`
