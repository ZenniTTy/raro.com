# 0036 — Android destravado (navbar + ciclo de vida) + câmera full-bleed provada no M54

- **Data:** 2026-07-15 → 2026-07-16
- **Duração:** ~2 dias (sessão longa, 2 fatias + auditoria)
- **Participantes:** Eduardo Rodrigues + Claude Code (Opus 4.8)
- **Branch:** `feat/camera-native-bridge` (PR #3, mergeado) → `feat/camera-fullbleed` (PR #4, aberto)
- **Commits:** PR #3: `57d2099`, `73c5795`, `7246a44`, `dec017b`, `c4ab1e2`, `2a5b263`, `c72ab68` (merge `ec81caa`). PR #4: `ba599ef`, `aac1751`, `a31d14c`, `6adb217`, `6793ed3`, `daeab6c`, `4c9c534`, `8e521e5`.

## Objetivo

Original: gerar APK preview para o cliente (roadmap `roadmap-apk-preview-cliente-android.md`). O teste no Galaxy M54 (Android 16/SDK 36) revelou 5 problemas e a sessão pivotou (com decisões explícitas do dono) para duas fatias de correção: (1) "destravar Android" e (2) "câmera full-bleed".

## Contexto inicial

Bloco 1 (Firebase) fechado na 0035. App iOS-first; Android tinha só o esqueleto da câmera. Primeiro teste real do app num Android físico (M54 do dono).

## O que foi feito

**Preparação (roadmap APK):** permissão `INTERNET` faltava no manifest release (Firebase Android mudo em silêncio) — `57d2099`. APK gerado, instalado, Firebase provado no device (`SESSION_START` logado).

**Fatia 1 — destravar Android (PR #3, MERGEADO em develop):**
- Navbar edge-to-edge (Android 15+ força; 5 telas sem SafeArea, botões intocáveis): SafeArea em gallery/permissions/settings/splash + teste `navbar_safe_area_test` — `dec017b`.
- Câmera morria ao voltar de Configurações: causa provada no log do device (`Failed to get Surfaces: surfaces=[]` — bind antes da surface chegar; 2 hipóteses erradas antes, corrigidas por verificação adversarial + log). Fix `bindIfReady`+`pendingConfig` no `CameraManager.kt` — `2a5b263`. Token de geração (B2) PULADO: a race temida não se manifestou (Simplicity First).
- SafeArea na câmera (c4ab1e2) REVERTIDO (c72ab68): criou tarja preta — o protótipo... na verdade o dono decidiu full-bleed (fatia 2).

**Fatia 2 — câmera full-bleed (PR #4, ABERTO):**
- Spec + plano com verificação adversarial (pegou 2 blockers de design antes do código: ring de foco é nativo/não vem "de graça"; colisão de camadas TopBar/BufferPill).
- Golden-com-insets (alchemist, `pumpOnce` contra animação infinita) — baseline com moldura ANTES do fix, inspecionado visualmente a cada iteração — `a31d14c`.
- Layout full-bleed: `_Viewport` em `Positioned.fill`, `_TopBar`/`_BottomControls` em SafeArea, moldura removida — `6adb217`. Teste pegou regressão real (SafeArea quebrava o `Positioned` do PrerollConfirmation; revertido nos popups).
- **Fix decisivo:** `PreviewView.ImplementationMode.COMPATIBLE` (1 linha Kotlin, desvio documentado): o SurfaceView default fura a tela no full-bleed e ENGOLE todos os overlays Flutter (controles sumiram; o "popup cortado" original era o mesmo buraco) — `6793ed3`.
- **Kit de inspeção remota adb** (pedido do dono): `screencap` + wake + `svc power stayon usb` + tap — validação visual direta do M54 sem fotos manuais. Provou: vídeo borda a borda, controles, popup INTEIRO.
- ADR-0027 (divergência full-bleed vs protótipo P05, decisão de produto) — `daeab6c`.

**Auditoria pré-fechamento (workflow 3 lentes: bugs silenciosos, spec-drift, design-fidelity):** 17 achados. Corrigidos: RecIndicator sob a status bar (`4c9c534`), cenário popup no golden (item do DoD que faltava), offsets hardcoded → responsivos a `viewPadding` (Dynamic Island ~59px quebraria; full-bleed vale pro iOS), PrerollConfirmation sobrepondo o REC button, adendo pós-implementação na spec reconciliando os desvios — `8e521e5`. Suíte final: **331 testes verdes**, analyze limpo, build iOS compila, diff sem `.swift`/Pigeon.

## O que NÃO foi feito (e por quê)

- **Envio do APK ao cliente** (objetivo original): adiado pelo dono — corrigir os problemas de usabilidade primeiro. Roadmap continua válido; gerar APK novo pós-merge do PR #4.
- **Gravação Android / foco por toque / ring de foco**: Bloco 3, fora das duas fatias por decisão explícita (stubs continuam lançando "not implemented").
- **Validação perceptual do full-bleed no iPhone 12**: o layout é compartilhado e muda o iOS; compila + suíte verde, mas olho humano no device ficou pra próxima sessão iOS (registrado no ADR-0027).
- **Gaps de fidelidade pré-existentes** (auditoria design-fidelity): bufferBar do protótipo nunca implementada; estado desarmado do BufferPill; grad-line na base dos controles; glow do REC fraco; cores da lens pill; botão close do topo; "indisponível em 4K60" fora de `.arb` (i18n = Bloco 4.6). Backlog de polish da câmera.
- **Cenários recording/voice/not-ready no golden**: melhoria futura anotada no adendo da spec.
- **Merge do PR #4**: aguarda revisão do dono.

## Aprendizados / surpresas

- **SurfaceView + PlatformView full-bleed = overlays engolidos** (memória `raro-pattern-android-surfaceview-fullbleed-eats-overlays`): o bug mais enganoso da sessão — o "popup cortado" reportado no início era ISSO, não SafeArea. Fix de 1 linha (COMPATIBLE/TextureView).
- **Kit adb de inspeção remota** muda o jogo: screencap preto com tamanho idêntico repetido = tela dormindo (checar `mWakefulness`), não o app. Com TextureView o vídeo aparece na captura.
- **Verificação adversarial pagou 3×**: pegou causa-raiz errada do ciclo de vida (didPopNext não dispara com context.go), colisão de camadas no design, e 3 bugs silenciosos de offset na auditoria final.
- **Golden-com-insets é a rede que faltava**: o erro da tarja preta (c4ab1e2) passou em teste estrutural; goldens renderizados com `viewPadding` real + inspeção do PNG pelo autor pegam layout errado antes do device.
- **Surface-bind race** (memória `raro-pattern-android-camerax-surface-bind-race-on-return`): nunca bindar Preview sem surface; acoplar com `bindIfReady`.
- **Edge-to-edge Android 15+** (memória `raro-pattern-android-15-edge-to-edge-safearea`): SafeArea nas telas de conteúdo; câmera é exceção full-bleed.
- **Commitei na develop por engano** (spec do full-bleed): corrigido com `git branch -f` + branch nova; verificar `git branch --show-current` antes de TODO commit.

## Próximos passos

- **Dono:** revisar/mergear PR #4 (full-bleed). Depois gerar APK novo e retomar o envio ao cliente (roadmap preview) com bilhete honesto.
- Próxima sessão de código: **Bloco 2 (RevenueCat)** conforme PLANO-MESTRE, OU Bloco 3 (gravação Android) se o dono preferir manter o momentum Android — decidir na abertura.
- Sessão iOS: validação perceptual do full-bleed no iPhone 12 (ADR-0027).
- Backlog registrado: polish de fidelidade da câmera (7 itens da auditoria).

## Referências

- Specs: `2026-07-15-destravar-android-navbar-ciclovida-design.md`, `2026-07-16-camera-fullbleed-fidelidade-android-design.md` (com adendo de auditoria)
- Plans: `2026-07-15-destravar-android-navbar-ciclovida.md`, `2026-07-16-camera-fullbleed-fidelidade.md`, `roadmap-apk-preview-cliente-android.md`
- ADRs: **ADR-0027** (câmera full-bleed diverge do protótipo)
- PRs: **#3 destravar-android (MERGEADO)**, **#4 camera-fullbleed (ABERTO)**
- Memórias novas: `raro-pattern-android-camerax-surface-bind-race-on-return`, `raro-pattern-android-15-edge-to-edge-safearea`, `raro-pattern-android-surfaceview-fullbleed-eats-overlays`
