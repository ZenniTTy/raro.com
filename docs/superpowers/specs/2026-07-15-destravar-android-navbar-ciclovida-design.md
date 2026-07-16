# Spec — Destravar Android: navbar (edge-to-edge) + câmera sobrevive a Configurações

> Data: 2026-07-15 · Status: causas provadas no device (M54, Android 16/SDK 36); aguarda revisão do dono
> Origem: sessão de preview APK Android revelou 5 problemas. Esta fatia ataca os 2 que são BUGS que impedem o uso básico. Features (gravação/foco/ring) vão para o Bloco 3 dedicado.
> Decisão de escopo do dono (2026-07-15): fatiar em "destravar Android" (2 bugs) vs "Bloco 3 câmera" (features), respeitando CLAUDE.md §6.

---

## 1. Contexto

App iOS-first. Ao gerar o APK preview e testar no Galaxy M54 (SM-M546B, **Android 16 / SDK 36**, One UI), apareceram 5 problemas. Classificados por natureza:

| # | Problema | Natureza | Nesta fatia? |
|---|---|---|---|
| 1 | Gravar → "Falha ao gravar" | Feature ausente (stub proposital) | ❌ Bloco 3 |
| 2 | Foco por toque não funciona | Feature ausente (sem OnTouchListener; ring é nativo) | ❌ Bloco 3 |
| 3 | **Câmera morre ao voltar de Configurações** | **Bug (ordem surface-vs-bind)** | ✅ **SIM** |
| 4 | **Navbar sobrepõe botões (5 telas)** | **Bug (edge-to-edge Android 15+)** | ✅ **SIM** |
| 5 | (mesmo que #4, outras telas) | idem | ✅ SIM |

Os 2 bugs desta fatia tornam o app **inutilizável** no Android: #4 impede tocar botões; #3 mata a câmera ao navegar. As features (#1, #2) são paridade Android pendente, não impedem o uso do que existe.

## 2. Escopo

**Nesta fatia (1 entregável fechado — "destravar Android"):**
1. **Navbar/edge-to-edge:** as 5 telas sem `SafeArea` passam a respeitar os insets do sistema — botões deixam de ficar sob a barra de navegação do Android.
2. **Câmera sobrevive a Configurações:** ir para Configurações e voltar mantém a câmera viva.

**Fora (Bloco 3 câmera, sessão dedicada depois):**
- Gravação CameraX `VideoCapture` (3.1).
- Foco por toque + ring de foco nativo (parte de 3.x). O ring do iOS é NATIVO (Swift/CALayer, `FocusRingConfig.swift`) — não vem "de graça" no Android; é trabalho novo. Descoberto na verificação adversarial 2026-07-15.
- Replay buffer, voz, ultra-wide, Xiaomi, contract tests.

## 3. Bug #4 — Navbar / edge-to-edge

### Causa-raiz (provada)
- Device: Android 16 / SDK 36. A partir do Android 15 (SDK 35), o SO **força edge-to-edge** — o app desenha atrás das barras de sistema. Fonte primária: Flutter docs `default-systemuimode-edge-to-edge` (Context7 `/flutter/website`, 2026-07-15): *"Android enforces edge-to-edge mode for all apps targeting Android 15 or later. Flutter apps targeting Android 15 (default from Flutter 3.27) automatically opt into edge-to-edge."*
- `MainActivity.kt` não trata insets (usa default do embedding Flutter).
- **5 de 10 rotas de produção não usam `SafeArea`:** `splash`, `permissions`, `camera`, `settings`, `gallery`. As outras 5 rotas de produção já tratam insets: `preview`, `paywall`, `checkout` (via `SafeArea` em `*_screen.dart`) + `onboarding_page_1` e `onboarding_page_2` (via `SafeArea` nas páginas). Confirmado por grep + verificação adversarial 2026-07-15. (Nota: há um 9º arquivo `*_screen.dart`, o `camera_test_harness_screen`, que já tem `SafeArea` mas é harness gated por `RARO_HARNESS`, não rota de produção — fora do escopo.)

### Abordagem (decisão do dono: migrar de verdade, não opt-out)
A doc oficial dá 2 caminhos: (a) opt-out via `android:windowOptOutEdgeToEdgeEnforcement=true` no `styles.xml` — **rejeitado**, a própria doc avisa que é temporário e o SO removerá; (b) **migrar** tratando insets. Escolhido (b) — futuro-à-prova, e melhora o iOS também (notch/Dynamic Island).

**Desenho:** envolver o conteúdo de cada uma das 5 telas em `SafeArea` (ou tratar `MediaQuery.viewPadding`/`padding` onde `SafeArea` não couber, ex: tela com fundo full-bleed que deve ir até a borda mas com controles afastados). Regra: o **preview da câmera** deve continuar full-bleed (vídeo até a borda), mas os **botões/controles** sobre ele respeitam os insets — então na `camera_screen` o `SafeArea` vai nos controles, não no preview.

### Risco / atenção
- `camera_screen` é o caso delicado: aplicar `SafeArea` ingênuo no widget todo cortaria o preview full-bleed. O `SafeArea` deve envolver só a camada de controles (a barra de botões), não o `CameraPreviewWidget`.
- `splash` pode não precisar de `SafeArea` visual (é transitória), mas se tem algo tocável/legível perto da borda, incluir.

## 4. Bug #3 — Câmera morre ao voltar de Configurações

### Causa-raiz (PROVADA no device, log M54 15:22:47–15:23:04)
Sequência real capturada:
```
15:22:47  CLOSED            ← tela velha: autoDispose → stopSession → unbindAll ✓
15:22:58  OPENING           ← tela nova: initState → _startSession → bind (você voltou)
15:22:58  open completed errorCode=null   ← câmera REABRIU limpa
15:23:03  Failed to get Surfaces: isActive=true, surfaces=[]   ← ✱ bind sem surface ✱
15:23:03  CLOSING → CLOSED  ← morre 5s depois (timeout do CameraX)
```

**Mecânica (código + log):**
- `CameraController` é `@riverpod` **autoDispose** (`camera_controller.dart:25`). Sair da `CameraScreen` (via `context.go(p06Settings)` — o router SUBSTITUI a stack, `router.dart`) remove os observers → autoDispose → `ref.onDispose(() => stopSession().ignore())` (`camera_controller.dart:32-33`, fire-and-forget) → `unbindAll` + `preview=null`, e a `PlatformView` faz `surfaceProvider=null` no `dispose()` (`CameraPlatformView.kt:23`).
- Voltar (via `context.go(p05Camera)`) reconstrói a `CameraScreen` → `initState` → `addPostFrameCallback` → `_startSession` (`camera_screen.dart:78-82`) → nativo `startSession` (`CameraManager.kt:88-98`). Na linha 95, `surfaceProvider?.let(...)` — mas a nova `PlatformView` **ainda não montou/setou** o `surfaceProvider` (é `null` neste instante). A linha 96 binda o `preview` **sem surface**. → `surfaces=[]` → CameraX espera 5s e derruba.
- O `CameraManager` é uma **instância única de vida longa por engine** (`MainActivity.kt:15`, criada uma vez em `configureFlutterEngine`, compartilhada por todas as telas porque o `FlutterEngine` persiste — não é `object`/singleton Kotlin, mas a propriedade que o fix usa é a mesma: é a MESMA instância em câmera→settings→câmera). O `surfaceProvider`/`preview` têm ciclos de vida **desacoplados**, sem garantia de ordem. O setter de `surfaceProvider` (`CameraManager.kt:46-49`) só liga a surface se `preview` já existe — não cobre o caso "surface chega depois do bind já ter falhado".

**Correção anterior (errada) descartada:** a hipótese inicial "initState não re-roda" estava factualmente errada — com `context.go`, a tela É reconstruída e `_startSession` re-roda. Verificação adversarial + log provaram. A causa real é a ordem surface-vs-bind, não a re-execução do initState.

### Desenho do fix (Kotlin-only, iOS intocado)
Acoplar bind e surface no `CameraManager`: o `bindToLifecycle` do `preview` só deve acontecer quando **ambos** config e `surfaceProvider` estão presentes; e quando a surface chega **depois** (setter), re-bindar se necessário.

Opção de implementação (a detalhar no plano):
- Guardar a config pendente. `startSession` sem surface → não binda ainda, marca "aguardando surface". O setter de `surfaceProvider`, ao receber a surface, dispara o bind (ou re-bind) com a config pendente. Isso torna a ordem irrelevante — funciona seja surface-antes-do-bind ou bind-antes-da-surface. **Invariante duro (não negociável):** o bind só ocorre quando config E surface estão presentes; se a surface chega depois, re-bindar.
- **A idempotência do stop é requisito obrigatório (DoD), não opcional.** O hazard é real e confirmado no código: `stopSession` (`CameraManager.kt:107-111`) faz `unbindAll()`+`preview=null`+`currentConfig=null`, então um `stopSession().ignore()` fire-and-forget da instância velha (chamado no `ref.onDispose`) pode derrubar um bind mais novo. O fix DEVE garantir que um stop stale não anule uma sessão mais nova. Mecânica candidata (a detalhar no plano): token de geração de sessão que invalida `stopSession` de gerações anteriores.

### Por que Kotlin-only aqui
O bug é da coordenação nativa surface↔bind, que vive no `CameraManager.kt`/`CameraPlatformView.kt`. Não exige mudança Dart. O `refreshAfterSettingsReturn()` que existe (`camera_controller.dart:93`) é usado só no harness de teste — NÃO será o veículo do fix (seria tratar no Dart um problema de ordem que é nativo). iOS 100% intocado.

## 5. Princípio de blindagem do iOS

| Camada | Muda? |
|---|---|
| Swift (iOS) | **Não.** Zero `.swift`. |
| Contrato Pigeon | **Não.** Sem regen. |
| Kotlin (Android) | Bug #3 (coordenação surface↔bind). |
| Dart (compartilhado) | Bug #4 (`SafeArea` nas 5 telas) — afeta iOS, mas MELHORA (notch). Provar com suíte + build iOS. |

## 6. Tratamento de erro
- Navbar: `SafeArea` é declarativo, sem caminho de erro. Cuidado é visual (não cortar preview full-bleed).
- Câmera: se a surface nunca chega (ex: PlatformView falha ao montar), o `startSession` fica "aguardando surface" sem bindar — estado seguro (câmera não abre em vez de abrir preta). Logar via `Log.w(TAG, ...)`. Sem `catch {}` vazio (CLAUDE.md §11).

## 7. Testes e gates
**Dart:**
- Widget test: as 5 telas renderizam conteúdo dentro dos insets (assert que os controles não ficam em `Offset` sob a navbar simulada via `MediaQuery` com `viewPadding`).
- Não-regressão: suíte Dart completa verde (rodar `bun run --filter '@raro/mobile' test` e citar o total exato reportado — NÃO assumir número).

**Device (M54) — CLAUDE.md §10:**
| Gate | Prova |
|---|---|
| Navbar usável | Screenshot/observação: os botões das 5 telas ficam ACIMA da navbar e são tocáveis |
| Câmera sobrevive a Config | Reproduzir câmera→Config→voltar: log SEM `Failed to get Surfaces`; preview renderiza; sem `CLOSED` órfão |
| iOS não regride | `bun run --filter '@raro/mobile' test` verde + `flutter build ios --debug --no-codesign` compila |
| Diff limpo | Nenhum `.swift`, nenhum regen Pigeon |

## 8. Arquivos a tocar

**Dart (bug #4 navbar):**
- `lib/features/settings/presentation/settings_screen.dart`
- `lib/features/splash/presentation/splash_screen.dart`
- `lib/features/permissions/presentation/permissions_screen.dart`
- `lib/features/camera/presentation/camera_screen.dart` (SafeArea só nos controles, preview full-bleed)
- `lib/features/gallery/presentation/gallery_screen.dart`

**Kotlin (bug #3 câmera):**
- `android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraManager.kt` (acoplar surface↔bind, config pendente, idempotência do stop)
- possivelmente `CameraPlatformView.kt` (ordem do set/clear de surfaceProvider)

**Testes:**
- Widget test de insets nas 5 telas (novo).

## 9. Critérios de sucesso (DoD desta fatia)
1. As 5 telas: botões acima da navbar, tocáveis no M54.
2. Câmera→Config→voltar mantém preview vivo (log sem `Failed to get Surfaces`).
3. `analyze` + `test` Dart verdes (total citado, não assumido).
4. Build iOS compila.
5. Diff sem `.swift` e sem regen Pigeon.
