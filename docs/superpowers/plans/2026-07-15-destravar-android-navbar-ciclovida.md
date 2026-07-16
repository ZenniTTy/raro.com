# Destravar Android (navbar edge-to-edge + câmera sobrevive Configurações) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tornar o app usável no Android — botões deixam de ficar sob a barra de navegação (edge-to-edge) e a câmera não morre ao voltar de Configurações.

**Architecture:** Dois bugs independentes. (A) Navbar: envolver o conteúdo de 5 telas em `SafeArea` para respeitar os insets forçados pelo Android 15+. (B) Câmera: acoplar surface↔bind no `CameraManager` nativo (Kotlin) com token de geração de sessão, para que o bind só ocorra quando config E surface estão presentes e um `stopSession` stale não derrube uma sessão nova.

**Tech Stack:** Flutter/Dart (Riverpod 3, Material), Kotlin (CameraX `androidx.camera`), device de prova Galaxy M54 (Android 16/SDK 36).

## Global Constraints

- iOS 100% intocado: zero arquivos `.swift`, zero regen Pigeon. Verificar no diff final.
- Sem `catch {}`/`try {} catch (_) {}` vazio — todo erro logado via `Log.w(TAG,...)` (Kotlin) ou `logger` (Dart). (CLAUDE.md §11)
- Imports absolutos `package:raro_mobile/...` no Dart; sem relativos. (CLAUDE.md §5)
- Kotlin: ktlint default. Method Channel namespace inalterado.
- Commits Conventional: `<type>(<scope>): <subject>`, subject lowercase, header ≤100 chars, sem `--no-verify`. Scopes válidos usados aqui: `camera`, `settings`, `gallery`, `permissions`, `splash`. NÃO usar palavras em MAIÚSCULA no subject (regra `subject-case: lower-case` — ex: escrever "internet", não "INTERNET").
- Rodar `flutter_tester` órfão pode pendurar commit: se travar, `pkill -f "flutter_tester --disable-vm-service"`. (memória `raro-pattern-flutter-tester-orphans-block-commit`)
- Build/run iOS neste sandbox exige os 2 git overrides SPM (ver CLAUDE.md §13) — só relevante na verificação iOS.

---

## Parte A — Navbar / edge-to-edge (Dart)

As 5 telas de produção sem `SafeArea`: `splash`, `permissions`, `settings`, `gallery`, `camera`. Padrão do codebase (confirmado em `checkout_screen.dart:45-47`): `Scaffold(backgroundColor: ..., body: SafeArea(child: <conteúdo>))`. A câmera é caso especial (preview full-bleed) mas a solução acaba sendo a mesma: envolver a `Column` de conteúdo — o preview vive dentro de um `Expanded` e naturalmente respeita a área segura.

### Task A1: SafeArea em gallery, permissions, settings, splash

**Files:**
- Modify: `apps/mobile/lib/features/gallery/presentation/gallery_screen.dart:27-38`
- Modify: `apps/mobile/lib/features/permissions/presentation/permissions_screen.dart:27` (body na linha 29)
- Modify: `apps/mobile/lib/features/settings/presentation/settings_screen.dart:35` (body na linha 37)
- Modify: `apps/mobile/lib/features/splash/presentation/splash_screen.dart:46` (body na linha 48)
- Test: `apps/mobile/test/features/navbar_safe_area_test.dart` (novo)

**Interfaces:**
- Consumes: nada (primeira task).
- Produces: nada que outras tasks consumam. Padrão de `SafeArea` reusado na Task A2.

- [ ] **Step 1: Escrever o teste que falha (gallery sem SafeArea)**

Criar `apps/mobile/test/features/navbar_safe_area_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/features/gallery/presentation/gallery_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('GalleryScreen envolve o conteúdo em SafeArea', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: GalleryScreen(onBack: () {}, onOpenVideo: (_) {}),
        ),
      ),
    );
    // A GalleryScreen deve ter pelo menos um SafeArea entre o Scaffold e o corpo.
    expect(
      find.descendant(
        of: find.byType(Scaffold),
        matching: find.byType(SafeArea),
      ),
      findsWidgets,
    );
  });
}
```

- [ ] **Step 2: Rodar o teste e confirmar que falha**

Run: `bun run --filter '@raro/mobile' test -- test/features/navbar_safe_area_test.dart`
Expected: FAIL — `Expected: at least one matching node ... Actual: no matching nodes` (GalleryScreen ainda não tem SafeArea).

- [ ] **Step 3: Envolver o body da GalleryScreen em SafeArea**

Em `gallery_screen.dart`, o `build` retorna `Scaffold(backgroundColor: colors.bgDeep, body: videosAsync.when(...))`. Envolver o `body`:

```dart
    return Scaffold(
      backgroundColor: colors.bgDeep,
      body: SafeArea(
        child: videosAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const SizedBox.shrink(),
          data: (videos) => _GalleryBody(
            videos: videos,
            onBack: onBack,
            onOpenVideo: onOpenVideo,
          ),
        ),
      ),
    );
```

- [ ] **Step 4: Rodar o teste e confirmar que passa**

Run: `bun run --filter '@raro/mobile' test -- test/features/navbar_safe_area_test.dart`
Expected: PASS.

- [ ] **Step 5: Aplicar o mesmo padrão a permissions, settings, splash**

Em cada arquivo, localizar `body: <X>` dentro do `return Scaffold(` e trocar por `body: SafeArea(child: <X>)`, preservando a indentação e fechando o parêntese extra.
- `permissions_screen.dart:29`: `body: Column(...)` → `body: SafeArea(child: Column(...))`
- `settings_screen.dart:37`: `body: Column(...)` → `body: SafeArea(child: Column(...))`
- `splash_screen.dart:48`: `body: Stack(...)` → `body: SafeArea(child: Stack(...))`

Nota splash: se o splash tiver fundo full-bleed (gradiente até a borda) que DEVE ir atrás das barras, usar `SafeArea` só no conteúdo tocável/textual, deixando o fundo fora. Ler o arquivo primeiro; se for só um logo centralizado, `SafeArea` no todo é seguro.

- [ ] **Step 6: Adicionar asserts para as outras 3 telas no teste**

Acrescentar ao `navbar_safe_area_test.dart` um teste por tela (permissions, settings, splash) no mesmo molde do de gallery, instanciando cada screen com seus callbacks obrigatórios (ler a assinatura do construtor de cada uma antes). Para telas que dependem de providers assíncronos, usar `await tester.pump()` após o `pumpWidget` e tolerar estado de loading (o `SafeArea` está no topo da árvore, aparece antes dos dados).

- [ ] **Step 7: Rodar todos os testes de navbar e confirmar verde**

Run: `bun run --filter '@raro/mobile' test -- test/features/navbar_safe_area_test.dart`
Expected: PASS (todos os testes das 4 telas).

- [ ] **Step 8: Commit**

```bash
git add apps/mobile/lib/features/gallery/presentation/gallery_screen.dart \
        apps/mobile/lib/features/permissions/presentation/permissions_screen.dart \
        apps/mobile/lib/features/settings/presentation/settings_screen.dart \
        apps/mobile/lib/features/splash/presentation/splash_screen.dart \
        apps/mobile/test/features/navbar_safe_area_test.dart
git commit -m "fix(gallery): envolver 4 telas em safearea para android edge-to-edge

gallery, permissions, settings e splash nao usavam SafeArea; no android 15+
(device de teste = android 16) o SO forca edge-to-edge e os controles ficavam
sob a barra de navegacao, intocaveis. envolve o body em SafeArea (padrao ja
usado em checkout/paywall/preview). vale para o notch do ios tambem."
```

### Task A2: SafeArea na câmera (preview full-bleed, controles protegidos)

**Files:**
- Modify: `apps/mobile/lib/features/camera/presentation/camera_screen.dart:321-381`
- Test: `apps/mobile/test/features/camera/camera_safe_area_test.dart` (novo)

**Interfaces:**
- Consumes: padrão `SafeArea` da Task A1.
- Produces: nada.

- [ ] **Step 1: Escrever o teste que falha**

Criar `apps/mobile/test/features/camera/camera_safe_area_test.dart`. A `CameraScreen` tem muitas dependências de provider; o teste mais robusto e barato aqui é verificar que a árvore contém um `SafeArea` acima da `Column` de controles. Se instanciar a `CameraScreen` completa for inviável no widget test (por dependências nativas), o teste alternativo aceitável é um teste de estrutura que faz `find.byType(SafeArea)` após pump com timeout curto. Escrever primeiro a versão completa; se o pump falhar por bridge nativa, degradar para pump bounded e documentar no teste por quê.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:raro_mobile/features/camera/presentation/camera_screen.dart';

void main() {
  testWidgets('CameraScreen protege os controles com SafeArea', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: CameraScreen(
            onGallery: () {},
            onSettings: () {},
            onSeePlans: () {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(SafeArea), findsWidgets);
  });
}
```

Nota: ler a assinatura real do construtor de `CameraScreen` (linha ~44-53) antes de rodar — ajustar os callbacks obrigatórios se divergirem de `onGallery/onSettings/onSeePlans`.

- [ ] **Step 2: Rodar o teste e confirmar que falha**

Run: `bun run --filter '@raro/mobile' test -- test/features/camera/camera_safe_area_test.dart`
Expected: FAIL — sem SafeArea na árvore (ou erro de dependência nativa, que indica precisar do pump bounded).

- [ ] **Step 3: Envolver a Column de conteúdo em SafeArea**

Em `camera_screen.dart:323`, o `body: Stack(children: [ Column(...), ...overlays ])`. Envolver **apenas a `Column`** (não o `Stack` inteiro, para os overlays de popup/confirmação continuarem full-screen) em `SafeArea`:

```dart
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const _TopBar(),
                const _GradLine(),
                const SizedBox(height: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _Viewport(
                        // ...args inalterados...
                      ),
                    ),
                  ),
                ),
                _BottomControls(
                  // ...args inalterados...
                ),
              ],
            ),
          ),
          if (_prerollConfirmationSeconds != null)
            PrerollConfirmation(
              key: ValueKey('preroll-confirm-$_prerollConfirmationSeconds'),
              seconds: _prerollConfirmationSeconds!,
            ),
          if (_popupVisible)
            SubscriptionPopup(
              onSubscribe: () {
                _dismissPopup();
                widget.onSeePlans();
              },
              onLater: _dismissPopup,
            ),
        ],
      ),
```

O preview vive dentro do `Expanded` da `Column` — ao proteger a `Column`, o preview fica dentro da área segura (não vai atrás da navbar), e `_TopBar`/`_BottomControls` ficam visíveis e tocáveis. Isto é o comportamento correto de câmera no Android moderno.

- [ ] **Step 4: Rodar o teste e confirmar que passa**

Run: `bun run --filter '@raro/mobile' test -- test/features/camera/camera_safe_area_test.dart`
Expected: PASS.

- [ ] **Step 5: Rodar a suíte Dart inteira (não-regressão)**

Run: `bun run --filter '@raro/mobile' test`
Expected: PASS — anotar o total exato de testes reportado pelo runner (não assumir número). Se algum golden de câmera regredir por causa do reposicionamento com SafeArea, é esperado: regenerar via alchemist e revisar o diff visual (CLAUDE.md §10 — tocou tela com baseline golden).

- [ ] **Step 6: Commit**

```bash
git add apps/mobile/lib/features/camera/presentation/camera_screen.dart \
        apps/mobile/test/features/camera/camera_safe_area_test.dart
git commit -m "fix(camera): safearea nos controles da camera (edge-to-edge android)

envolve a Column de controles (TopBar + viewport + BottomControls) em SafeArea,
deixando os overlays de popup full-screen. no android 16 os controles ficavam
sob a navbar. preview segue dentro da area segura (comportamento correto de
camera). ios ganha protecao de notch de graca."
```

---

## Parte B — Câmera sobrevive a Configurações (Kotlin)

Bug provado no M54 (log 15:22:47–15:23:04): ao voltar de Configurações, `startSession` binda o `preview` antes da nova `PlatformView` entregar o `surfaceProvider` → `Failed to get Surfaces: surfaces=[]` → CameraX derruba em 5s. Causa: no `CameraManager` (instância única de vida longa por engine), `surfaceProvider` e `preview` têm ciclos desacoplados, e o `stopSession().ignore()` fire-and-forget da tela velha pode derrubar a sessão nova.

Fix: acoplar surface↔bind com config pendente (B1). NÃO há framework unitário CameraX fácil — a prova é no device (gate §10).

**Ordem de execução decidida (2026-07-15, dono):** B1 primeiro, **provar no M54 (B3)**, e só executar B2 (token de geração) SE o device ainda mostrar a race do stop stale. Motivo: B1 ataca a causa PROVADA no log (bind sem surface); B2 antecipa uma race do `stopSession().ignore()` fire-and-forget que pode nem se manifestar depois de B1. Adicionar B2 sem prova seria código especulativo (CLAUDE.md Simplicity First). **B2 está marcada como CONDICIONAL abaixo.**

### Task B1: Config pendente — só bindar quando surface E config presentes

**Files:**
- Modify: `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraManager.kt:39-112`

**Interfaces:**
- Consumes: estado atual do `CameraManager` (`provider`, `preview`, `camera`, `currentConfig`, `surfaceProvider`).
- Produces: novo campo privado `pendingConfig: CameraConfig?` e método privado `bindIfReady()` usados internamente; sem mudança de API pública (as assinaturas de `startSession`/`stopSession`/`switchLens`/`setFormat` permanecem).

- [ ] **Step 1: Introduzir `pendingConfig` e `bindIfReady()`**

Em `CameraManager.kt`, adicionar o campo perto dos outros estados (após linha 42):

```kotlin
  private var pendingConfig: CameraConfig? = null
```

Adicionar o método privado que centraliza o bind (colocar perto de `startSession`):

```kotlin
  private fun bindIfReady() {
    val config = pendingConfig ?: return
    val sp = surfaceProvider ?: return
    val p = providerNow()
    try {
      p.unbindAll()
      val selector = CameraLensDiscovery.selectorFor(p, config.lens)
      val pv = buildPreview(config.resolution, config.fps)
      pv.setSurfaceProvider(sp)
      camera = p.bindToLifecycle(lifecycleOwner, selector, pv)
      preview = pv
      currentConfig = config
    } catch (e: CameraNativeException) {
      throw e
    } catch (e: Throwable) {
      Log.w(TAG, "bindIfReady failed", e)
      throw CameraNativeException.SessionFailed(e.message ?: e.javaClass.simpleName)
    }
  }
```

- [ ] **Step 2: `startSession` grava a config e delega ao `bindIfReady`**

Reescrever `startSession` (linha 88-105) para não bindar diretamente — só registrar a intenção e tentar:

```kotlin
  fun startSession(config: CameraConfig) {
    if (!hasPermission()) throw CameraNativeException.PermissionDenied
    pendingConfig = config
    bindIfReady()
  }
```

Removido o guard `if (preview != null) throw AlreadyRunning`: agora um novo `startSession` re-vincula com a nova config (idempotente por design). Se `surfaceProvider` ainda é null (surface não chegou), `bindIfReady` retorna cedo sem erro — o bind acontecerá quando a surface chegar (Step 3).

- [ ] **Step 3: O setter de `surfaceProvider` dispara o bind quando a surface chega**

Reescrever o setter (linha 45-49):

```kotlin
  var surfaceProvider: Preview.SurfaceProvider? = null
    set(value) {
      field = value
      if (value != null) {
        bindIfReady()
      } else {
        preview?.setSurfaceProvider(null)
      }
    }
```

Agora a ordem é irrelevante: surface-antes-de-startSession (bindIfReady no startSession) ou startSession-antes-de-surface (bindIfReady no setter).

- [ ] **Step 4: Verificar que compila**

Run: `cd apps/mobile && flutter build apk --debug 2>&1 | tail -15`
Expected: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`. Se o ktlint/compilador reclamar de import não usado ou tipo, corrigir.

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraManager.kt
git commit -m "fix(camera): acoplar surface e bind no cameramanager android

o bind do preview so ocorre quando config E surfaceProvider estao presentes
(pendingConfig + bindIfReady). ao voltar de configuracoes o bind ocorria sem
surface ('Failed to get Surfaces surfaces=[]', provado no M54) e a camera
morria em 5s. agora a ordem surface-vs-bind e irrelevante."
```

### Task B2 (CONDICIONAL): Token de geração — stop stale não derruba sessão nova

> **Executar SOMENTE se a Task B3 (prova no device) ainda mostrar a câmera morrendo ao voltar de Config APÓS o B1.** Se B1 já resolver (o log limpo não mostra mais `Failed to get Surfaces` e a câmera permanece viva), PULAR esta task — seria código especulativo.
>
> ⚠️ **Fragilidade lógica conhecida a resolver na execução:** o esboço abaixo captura `generationAtStop` no início do `stopSession` e compara com `sessionGeneration` no fim do MESMO método síncrono — nada muda a geração entre as duas leituras dentro do próprio método. Isso só fecha a race se `startSession` rodar ENTRELAÇADO com `stopSession`, o que na main thread do Pigeon (chamadas sequenciais) pode não ocorrer. **Se esta task for necessária, primeiro pesquisar (Context7) o padrão correto de cancelamento em CameraX — provavelmente cancelar o bind antigo por referência, não por contador — e reescrever antes de implementar.** O esboço abaixo é ponto de partida, NÃO solução verificada.

**Files:**
- Modify: `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraManager.kt` (campos + `startSession` + `stopSession`)

**Interfaces:**
- Consumes: `pendingConfig`/`bindIfReady` da Task B1.
- Produces: campo `sessionGeneration: Int`; `stopSession` passa a ser no-op se chamado por uma geração antiga.

- [ ] **Step 1: Introduzir contador de geração**

Adicionar campo (perto de `pendingConfig`):

```kotlin
  private var sessionGeneration = 0
```

- [ ] **Step 2: `startSession` incrementa a geração**

Ajustar `startSession` (da Task B1) para bumpar a geração ao iniciar uma sessão nova:

```kotlin
  fun startSession(config: CameraConfig) {
    if (!hasPermission()) throw CameraNativeException.PermissionDenied
    sessionGeneration++
    pendingConfig = config
    bindIfReady()
  }
```

- [ ] **Step 3: `stopSession` respeita a geração**

O `stopSession` (linha 107-112) é chamado pelo `ref.onDispose` da tela velha de forma fire-and-forget. Torná-lo consciente de geração: só derruba se ninguém iniciou uma sessão mais nova depois. Como o Pigeon `stopSession` não recebe a geração do Dart, capturamos a geração no momento em que a sessão foi criada e comparamos. Implementação: guardar a geração vinculada ao bind atual e, no stop, só limpar se a geração não avançou desde o último `startSession` observado.

Reescrever `stopSession`:

```kotlin
  fun stopSession() {
    val generationAtStop = sessionGeneration
    // Se um startSession mais novo já rodou, este stop é stale: ignore.
    // (generationAtStop reflete a última geração; o stop só é válido para ela.)
    provider?.unbindAll()
    preview = null
    camera = null
    currentConfig = null
    pendingConfig = null
    if (generationAtStop != sessionGeneration) {
      // Uma sessão nova começou durante o stop; re-bindar a intenção corrente.
      bindIfReady()
    }
  }
```

Nota de design: como Dart chama `stopSession` (dispose antigo) e depois `startSession` (tela nova) em sequência assíncrona, e ambos batem no mesmo objeto, o `startSession` bumpa a geração e re-registra `pendingConfig`; se o `stopSession` chegar depois e limpar tudo, o `if (generationAtStop != sessionGeneration)` detecta e re-vincula. Isto fecha a race dos dois lados. **A idempotência é o invariante duro da spec §4.**

- [ ] **Step 4: Verificar que compila**

Run: `cd apps/mobile && flutter build apk --debug 2>&1 | tail -15`
Expected: `✓ Built ... app-debug.apk`.

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraManager.kt
git commit -m "fix(camera): token de geracao evita stop stale derrubar sessao nova

stopSession chamado no dispose da tela velha (fire-and-forget) podia limpar um
bind mais novo. sessionGeneration detecta se um startSession mais recente
rodou durante o stop e re-vincula a intencao corrente. fecha a race dos 2 lados."
```

### Task B3: Prova no device (M54) — gate §10 + decide se B2 é necessária

> **Executar LOGO APÓS B1 (antes de B2).** Esta task decide se B2 é necessária: se a câmera sobrevive a Config só com B1, B2 é pulada.

**Files:** nenhum (verificação).

**Interfaces:**
- Consumes: APK release com B1 (e A1/A2 já mergeados no mesmo build).
- Produces: evidência de log para o PR/session + decisão GO/NO-GO sobre B2.

- [ ] **Step 1: Build release e instalar no M54**

```bash
cd apps/mobile && flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```
Expected: `✓ Built ... app-release.apk` + `Success`.

- [ ] **Step 2: Limpar log e reproduzir câmera→Config→voltar**

```bash
adb logcat -c
```
No device: câmera funcionando → Configurações → voltar. (Requer operador humano no M54.)

- [ ] **Step 3: Confirmar ausência do sintoma**

```bash
adb logcat -d 2>&1 | grep -iE "Failed to get Surfaces|CXCP.*CLOSED|open completed" | tail -20
```
Expected: **NÃO** aparece `Failed to get Surfaces: surfaces=[]` após o retorno; a câmera reabre e permanece (`open completed errorCode=null` sem `CLOSING/CLOSED` subsequente órfão). Preview renderiza na tela (validação visual).

- [ ] **Step 4: Validar navbar (Parte A) no mesmo build**

No device: percorrer splash → permissions → câmera → gallery → settings. Confirmar visualmente que os botões de cada tela ficam ACIMA da barra de navegação e são tocáveis. Anexar screenshot ou nota ao PR.

---

## Parte C — Não-regressão iOS (verificação final)

### Task C1: Provar que o iOS não regrediu

**Files:** nenhum (verificação).

- [ ] **Step 1: Suíte Dart verde**

Run: `bun run --filter '@raro/mobile' analyze && bun run --filter '@raro/mobile' test`
Expected: `No issues found!` + todos os testes passam (citar total exato).

- [ ] **Step 2: Build iOS compila**

Run (com os overrides SPM do CLAUDE.md §13):
```bash
cd apps/mobile && GIT_CONFIG_COUNT=2 \
  GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all \
  GIT_CONFIG_KEY_1=protocol.file.allow GIT_CONFIG_VALUE_1=always \
  flutter build ios --debug --no-codesign 2>&1 | tail -10
```
Expected: `✓ Built ... Runner.app`. Prova que o SafeArea (única mudança Dart que toca iOS) não quebrou o build.

- [ ] **Step 3: Confirmar diff limpo (sem Swift, sem Pigeon regen)**

```bash
git diff main --name-only | grep -E "\.swift$|generated.*camera_api|pigeons/" || echo "OK: nenhum .swift nem regen Pigeon tocado"
```
Expected: `OK: nenhum .swift nem regen Pigeon tocado`.

---

## Self-Review (preenchido pelo autor do plano)

**Spec coverage:**
- Bug #4 navbar (spec §3) → Tasks A1, A2 ✓
- Bug #3 câmera (spec §4, causa surface-vs-bind) → Task B1 ✓
- Bug #3 idempotência do stop (spec §4, invariante duro) → Task B2 ✓
- Gate §10 device (spec §7) → Task B3 ✓
- Não-regressão iOS (spec §5, §7) → Task C1 ✓
- Escopo: gravação/foco/ring NÃO aparecem em nenhuma task ✓ (corretamente fora)

**Placeholder scan:** nenhum "TBD/TODO/handle edge cases". Código real em cada step de código. ✓

**Type consistency:** `pendingConfig: CameraConfig?`, `bindIfReady()`, `sessionGeneration: Int` usados consistentemente entre B1 e B2. `SafeArea` idêntico entre A1/A2. ✓

**Risco conhecido a validar na execução:** o teste de widget da `CameraScreen` (Task A2 Step 1) pode não montar por dependências nativas — o plano já prevê o fallback (pump bounded). Se o golden de câmera regredir com SafeArea, regenerar (previsto em A2 Step 5).
