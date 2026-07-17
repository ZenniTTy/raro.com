# ADR-0027 — Câmera full-bleed (divergência intencional do protótipo P05)

- Status: Aceito
- Data: 2026-07-16
- Decisor: dono do produto (Eduardo)

## Contexto

O protótipo P05 (`docs/briefing/prototype/Prototipo-RARO.html` linha 824+) desenha a câmera com o viewport **emoldurado**: margem lateral (`mx-3`), cantos arredondados (`rounded-2xl`), entre uma top bar e os controles inferiores. A implementação Flutter seguia o protótipo (Padding 12 + ClipRRect 16 numa Column).

No teste do preview APK num Galaxy M54 (Android 16), o dono avaliou o resultado real e decidiu que a câmera deve ser **full-bleed**: vídeo ocupando a tela inteira até as bordas, com todos os controles (wordmark, buffer pill, HUD, lentes, botões) flutuando por cima — padrão dos apps de câmera modernos.

## Decisão

A tela da câmera adota **full-bleed nas duas plataformas** (iOS e Android — a tela é compartilhada), divergindo conscientemente do protótipo:

- Preview/`_Viewport` em `Positioned.fill` (tela toda, sem moldura).
- `_TopBar` e `_BottomControls` como overlays em `SafeArea` (insets responsivos; o `top:60` hardcoded foi removido).
- Elementos do viewport reposicionados para empilhar com folga (BufferPill `top:56`, HUD/Lens `bottom:150`) sem colidir com os controles.
- Android: `PreviewView.ImplementationMode.COMPATIBLE` (TextureView) obrigatório — o SurfaceView default fura a tela e engole os overlays Flutter no full-bleed (provado no M54; o popup de assinatura "cortado" era o mesmo buraco).

## Consequências

- O gate de design-fidelity (§10) contra o P05 passa a ter uma exceção documentada: a **moldura do viewport** diverge por decisão de produto. Os demais elementos (cores, copy, buffer, HUD, lens, hierarquia) continuam devendo fidelidade ao protótipo.
- TextureView tem custo de GPU levemente maior que SurfaceView; aceito como preço do full-bleed com overlays. Reavaliar apenas se aparecer jank mensurável em gravação.
- Validação visual da câmera: golden-com-insets (`camera_fullbleed_golden_test.dart`) + screencap adb no device (o TextureView torna o vídeo capturável).
- Provado no M54 em 2026-07-16 (screencap: vídeo borda a borda + controles + popup inteiro). iOS: layout compartilhado compila e a suíte passa; validação perceptual no iPhone 12 pendente na próxima sessão iOS.
