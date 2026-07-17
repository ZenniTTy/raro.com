# Câmera full-bleed (fidelidade visual) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A câmera vira full-bleed — preview ocupa a tela toda, controles empilhados por cima sem tarja preta, topo não cortado, buffer/HUD/lens visíveis, popup de assinatura inteiro.

**Architecture:** Reorganizar o `build` da `CameraScreen` de `Column` para `Stack` em camadas: preview/`_Viewport` como `Positioned.fill` (sem moldura), `_TopBar`+`_BottomControls` como overlays dentro de `SafeArea`, empilhados com folga para não colidir com o `BufferPill`/`HUD`/`LensSwitcher` que o `_Viewport` já posiciona. Validação por golden-com-insets.

**Tech Stack:** Flutter/Dart (Riverpod 3, Material), alchemist (goldens), device de prova Galaxy M54 (Android 16/SDK 36).

## Global Constraints

- Layout Dart puro: zero `.swift`, zero Kotlin, zero regen Pigeon. Verificar no diff final.
- iOS muda junto (tela compartilhada) — coerência intencional. Build iOS compila; goldens iOS revisados.
- Full-bleed diverge do protótipo (que tem moldura) — divergência de produto aprovada pelo dono, registrar (ADR leve / nota Blueprint).
- Sem `catch{}` vazio (não se aplica a layout, mas manter padrão). Imports absolutos `package:raro_mobile/...`.
- Commits Conventional: subject lowercase, header ≤100, sem MAIÚSCULAS no subject, sem `--no-verify`. Scope `camera`.
- **Verificar a branch antes de cada commit** (`git branch --show-current` = `feat/camera-fullbleed`). Não commitar em develop.
- `flutter_tester` órfão trava commit: se travar, `pkill -f "flutter_tester --disable-vm-service"`.
- Limitação conhecida: o preview (PlatformView) NÃO renderiza em golden test — aparece em branco. O golden valida o LAYOUT dos overlays + ausência de tarja preta (o bug que importa), não o vídeo.

---

## Task 1: Golden-com-insets que captura a tarja preta (RED antes do fix)

Escrever o golden ANTES de mexer no layout, para ele FALHAR mostrando a tarja preta (a moldura atual reserva espaço pro TopBar/BottomControls). Isso prova que o teste detecta o bug — a rede que faltou na A2.

**Files:**
- Create: `apps/mobile/test/features/camera/presentation/camera_fullbleed_golden_test.dart`
- Test dir (goldens gerados): `apps/mobile/test/features/camera/presentation/goldens/`

**Interfaces:**
- Consumes: `CameraScreen` (constrói via harness com overrides — ver camera_screen_test.dart:126-169 para o padrão de mocks).
- Produces: golden baseline `camera_fullbleed*.png`.

- [ ] **Step 1: Escrever o golden test da CameraScreen com insets reais**

Reusar o padrão de mocks do `camera_screen_test.dart` (harness com `cameraRepositoryProvider`, `settingsStoreProvider`, `voice*`, etc.). Envolver a `CameraScreen` num `MediaQuery` com `viewPadding` simulando status bar + navbar do Android:

```dart
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:raro_mobile/core/theme/raro_theme_data.dart';
// + os imports/mocks do camera_screen_test.dart (copiar _FakeSettingsStore,
//   _StubVoiceRepository, _MockCameraRepository, buildRepo, e os provider imports)

void main() {
  goldenTest(
    'camera_fullbleed',
    fileName: 'camera_fullbleed',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'ready with android insets',
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(400, 860),
              viewPadding: EdgeInsets.only(top: 40, bottom: 48),
              padding: EdgeInsets.only(top: 40, bottom: 48),
            ),
            child: ProviderScope(
              overrides: [/* mesmos overrides do harness camera_screen_test */],
              child: MaterialApp(
                theme: buildRaroDarkTheme(),
                home: const CameraScreen(
                  onGallery: _noop, onSettings: _noop, onSeePlans: _noop,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

void _noop() {}
```

Nota: copiar o bloco de mocks/overrides literal do `camera_screen_test.dart` (linhas 33-169) — o harness já monta a CameraScreen com todas as deps. O `buildRepo(hasPermission: true)` deixa a câmera "ready".

- [ ] **Step 2: Rodar e gerar o baseline (que mostra a tarja preta)**

Run: `bun run --filter '@raro/mobile' test -- test/features/camera/presentation/camera_fullbleed_golden_test.dart --update-goldens`
Expected: gera `goldens/camera_fullbleed.png`. **Abrir o PNG e confirmar visualmente** que há tarja preta em cima/baixo (o bug atual) — isso prova que o golden captura o estado errado. Anotar no commit que este baseline é o "antes" (com bug).

- [ ] **Step 3: Commit do golden que documenta o bug**

```bash
git branch --show-current  # confirmar feat/camera-fullbleed
git add apps/mobile/test/features/camera/presentation/camera_fullbleed_golden_test.dart \
        apps/mobile/test/features/camera/presentation/goldens/camera_fullbleed.png
git commit -m "test(camera): golden-com-insets da camera (baseline com tarja preta, pre-fix)"
```

## Task 2: Full-bleed — remover moldura + overlays com SafeArea

Reorganizar o `build` principal. O `_Viewport` interno fica intocado (já é full-bleed); só sai da moldura. `_TopBar`/`_BottomControls` viram overlays. Empilhar com folga (decisão do dono) para não colidir com BufferPill (top) e HUD/Lens (bottom) do viewport.

**Files:**
- Modify: `apps/mobile/lib/features/camera/presentation/camera_screen.dart` (build principal ~321-382; `_TopBar` ~385-406; offsets do `_Viewport` ~467-493)

**Interfaces:**
- Consumes: `_Viewport`, `_TopBar`, `_BottomControls` (existentes).
- Produces: layout full-bleed. Sem mudança de assinatura de widget.

- [ ] **Step 1: Reescrever o build principal para Stack full-bleed**

Trocar o `body:` (hoje `Stack > Column[_TopBar, _GradLine, Expanded(Padding(ClipRRect(_Viewport))), _BottomControls]`) por camadas:

```dart
    return Scaffold(
      backgroundColor: colors.bgDeep,
      body: Stack(
        children: [
          Positioned.fill(
            child: _Viewport(
              cameraReady: cameraReady,
              recording: recording,
              elapsed: _elapsed,
              voiceState: voiceState,
              controlMode: controlMode,
              bufferDuration: bufferDuration,
              lens: shell.lens,
              lensLabel: shell.hudLensLabel,
              resolutionLabel: resolutionLabel(_format.resolution),
              fpsLabel: fpsLabel(_format.fps),
              ultraWideEnabled: !_is4k60,
              onToggleBuffer: () => ref
                  .read(settingsControllerProvider.notifier)
                  .toggleBufferDuration(),
              onSelectLens: _onSelectLens,
              onTapHud: widget.onSettings,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const _TopBar(),
                const Spacer(),
                _BottomControls(
                  recording: recording,
                  replayArmed: replayArmed,
                  replayWindowSeconds: replayWindowSeconds,
                  onGallery: widget.onGallery,
                  onSettings: widget.onSettings,
                  onRecTap: _onRecTap,
                ),
              ],
            ),
          ),
          if (_prerollConfirmationSeconds != null)
            SafeArea(
              child: PrerollConfirmation(
                key: ValueKey('preroll-confirm-$_prerollConfirmationSeconds'),
                seconds: _prerollConfirmationSeconds!,
              ),
            ),
          if (_popupVisible)
            SafeArea(
              child: SubscriptionPopup(
                onSubscribe: () {
                  _dismissPopup();
                  widget.onSeePlans();
                },
                onLater: _dismissPopup,
              ),
            ),
        ],
      ),
    );
```

Removidos: o `Column` externo, o `_GradLine`, o `Expanded`, o `Padding(horizontal:12)`, o `ClipRRect(radius:16)`. O `_Viewport` vai direto em `Positioned.fill`.

- [ ] **Step 2: Remover o inset top hardcoded do _TopBar**

Em `_TopBar.build` (~390), trocar `EdgeInsets.fromLTRB(20, 60, 20, 12)` por `EdgeInsets.fromLTRB(20, 0, 20, 12)` — o `SafeArea` agora dá o respiro do topo:

```dart
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Center(
        child: Text('RARO', style: /* inalterado */),
      ),
    );
```

- [ ] **Step 3: Ajustar offsets do _Viewport para empilhar com folga (anti-colisão)**

No `_Viewport.build`, o `BufferPill` está em `Positioned(top:12, right:12)` e o HUD/Lens em `Positioned(bottom:12, ...)`. Com o `_TopBar` agora no topo (dentro do SafeArea) e o `_BottomControls` no rodapé, empurrar esses para não colidir: BufferPill mais abaixo do TopBar, HUD/Lens mais acima dos BottomControls. Aumentar os offsets:

```dart
        // BufferPill: era top:12 -> abaixo do _TopBar (que ocupa ~topo + wordmark)
        Positioned(
          top: 56,
          right: 12,
          child: BufferPill(duration: bufferDuration, onTap: onToggleBuffer),
        ),
        // HUD/Lens Row: era bottom:12 -> acima do _BottomControls (fileira de botoes ~88px)
        Positioned(
          left: 12,
          right: 12,
          bottom: 96,
          child: Row(/* HudInfoBar + LensSwitcher, inalterado */),
        ),
```

Os valores exatos (56, 96) são ponto de partida — o golden (Task 3) confirma se há folga suficiente; ajustar se o PNG mostrar sobreposição.

- [ ] **Step 4: Verificar que analyze passa**

Run: `bun run --filter '@raro/mobile' analyze`
Expected: `No issues found!`. Corrigir imports órfãos se `_GradLine`/`ClipRRect` deixarem símbolo não usado.

- [ ] **Step 5: Commit do layout**

```bash
git branch --show-current  # feat/camera-fullbleed
git add apps/mobile/lib/features/camera/presentation/camera_screen.dart
git commit -m "feat(camera): layout full-bleed (preview tela toda + controles em safearea)"
```

## Task 3: Regenerar golden e validar o full-bleed visualmente

- [ ] **Step 1: Regenerar o golden com o novo layout**

Run: `bun run --filter '@raro/mobile' test -- test/features/camera/presentation/camera_fullbleed_golden_test.dart --update-goldens`
Expected: atualiza `goldens/camera_fullbleed.png`.

- [ ] **Step 2: Inspecionar o PNG — SEM tarja preta, SEM colisão**

**Abrir o PNG e confirmar visualmente** (o autor DEVE ver a imagem):
- Não há tarja preta em cima/baixo (o preview/placeholder ocupa a tela toda).
- `_TopBar` (RARO) no topo, `BufferPill` logo abaixo, sem sobreposição.
- HUD/Lens acima dos BottomControls, sem sobreposição.
- Se houver colisão, voltar à Task 2 Step 3 e ajustar os offsets. Repetir até limpo.

- [ ] **Step 3: Adicionar cenário com popup (valida fix #4)**

Adicionar um segundo `GoldenTestScenario` ao teste com `_popupVisible` simulado (via override do subscription store para não-assinante + pump do timer), confirmando que o `SubscriptionPopup` aparece INTEIRO dentro do SafeArea (não cortado). Regenerar e inspecionar.

- [ ] **Step 4: Rodar a suíte inteira (não-regressão)**

Run: `bun run --filter '@raro/mobile' test`
Expected: todos verdes — CITAR o total exato reportado. Outros goldens de câmera (ex: lens_chip_row) não devem mudar. Se algum golden de tela cheia regredir, é esperado pelo full-bleed: regenerar e revisar o diff visual.

- [ ] **Step 5: Commit**

```bash
git branch --show-current  # feat/camera-fullbleed
git add apps/mobile/test/features/camera/presentation/
git commit -m "test(camera): golden full-bleed sem tarja + cenario popup"
```

## Task 4: Prova no device (M54) + registro da divergência

**Files:**
- Create: nota de divergência (ADR leve ou seção no Blueprint — ver Step 3).

- [ ] **Step 1: Build release e instalar no M54**

```bash
cd apps/mobile && flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```
Expected: `✓ Built ... app-release.apk` + `Success`. (Requer M54 conectado + operador humano.)

- [ ] **Step 2: Validar no device os 4 problemas**

No M54, abrir a câmera e confirmar visualmente (anexar fotos ao PR):
1. Sem tarja preta — vídeo ocupa a tela toda.
2. Topo (RARO) não cortado.
3. Buffer pill + HUD + lens visíveis sobre o vídeo, sem sobreposição com RARO/botões.
4. Popup de assinatura aparece inteiro (não cortado) — aguardar o timer de 450ms.

- [ ] **Step 3: Registrar a divergência full-bleed vs protótipo**

Criar nota curta em `docs/decisions/` (ADR leve) OU seção no Blueprint documentando: "Câmera adota full-bleed (preview até a borda, controles flutuando) divergindo do protótipo P05 (que tem viewport emoldurado). Decisão de produto do dono, 2026-07-16. Vale iOS+Android." Commitar com scope `docs` ou `blueprint`.

## Task 5: Não-regressão iOS + fechar

- [ ] **Step 1: Build iOS compila**

Run (overrides SPM do CLAUDE.md §13):
```bash
cd apps/mobile && GIT_CONFIG_COUNT=2 \
  GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all \
  GIT_CONFIG_KEY_1=protocol.file.allow GIT_CONFIG_VALUE_1=always \
  flutter build ios --debug --no-codesign 2>&1 | tail -10
```
Expected: `✓ Built ... Runner.app`.

- [ ] **Step 2: Diff limpo (sem swift/pigeon)**

```bash
git diff origin/develop --name-only | grep -E "\.swift$|generated.*camera_api|pigeons/" && echo "!!! TEM NATIVO" || echo "OK: layout Dart puro"
```
Expected: `OK: layout Dart puro`.

- [ ] **Step 3: finishing-a-development-branch**

Invocar `superpowers:finishing-a-development-branch` para push + PR de `feat/camera-fullbleed` → `develop`.

---

## Self-Review (autor)

**Spec coverage:**
- #1 tarja preta (spec §3) → Task 2 (Positioned.fill) + Task 1/3 (golden captura) ✓
- #2 topo cortado (spec §3) → Task 2 Step 2 (SafeArea + remover top:60) ✓
- #3 buffer/HUD (spec §3) → Task 2 Step 3 (offsets anti-colisão) ✓
- #4 popup cortado (spec §3) → Task 2 Step 1 (SafeArea no popup) + Task 3 Step 3 (golden) ✓
- Colisão de camadas (spec §4, achado adversarial) → Task 2 Step 3 + Task 3 Step 2 (inspeção) ✓
- Validação golden-com-insets (spec §5) → Task 1 + Task 3 ✓
- Registro divergência (spec §3/§6) → Task 4 Step 3 ✓
- Não-regressão iOS + zero nativo (spec §7) → Task 5 ✓
- Escopo: gravação/foco/ring ausentes de todas as tasks ✓

**Placeholder scan:** offsets 56/96 marcados como "ponto de partida, golden confirma" — não é placeholder, é valor inicial com critério de ajuste. Mocks do golden dizem "copiar de camera_screen_test.dart:33-169" (código real existente, referência precisa). ✓

**Type consistency:** `_Viewport`/`_TopBar`/`_BottomControls` usados com as mesmas assinaturas do código atual. ✓

**Risco conhecido:** o preview não renderiza em golden (limitação documentada); o golden valida layout/tarja, o device valida o vídeo real (Task 4). Coberto.
