# Spec — Câmera full-bleed (fidelidade visual Android/iOS)

> Data: 2026-07-16 · Status: design aprovado pelo dono (6 seções) · aguarda revisão da spec escrita
> Origem: teste do preview APK no Galaxy M54 (Android 16/SDK 36) revelou 4 problemas visuais na câmera. Decisão do dono: câmera vira **full-bleed** (vídeo até a borda, controles flutuando) nas 2 plataformas, divergindo do protótipo aprovado (que tem moldura) — divergência registrada.

---

## 1. Contexto e problema

A `CameraScreen` renderiza o preview dentro de uma **moldura**: `Expanded > Padding(horizontal 12) > ClipRRect(radius 16) > _Viewport`, entre `_TopBar` e `_BottomControls` numa `Column`. No Galaxy M54 isso produziu 4 problemas:

| # | Sintoma no device | Causa |
|---|---|---|
| 1 | Tarja preta em cima/baixo | A `Column` reserva espaço pro TopBar/BottomControls; o preview fica só no `Expanded` do meio (moldura). |
| 2 | Topo cortado | `_TopBar` usa `padding top: 60` hardcoded (`camera_screen.dart:391`), não o inset real do aparelho — corta no M54. |
| 3 | Buffer/HUD não aparecem como esperado | bufferPill/bufferBar/HUD vivem dentro do `_Viewport` emoldurado, não flutuando sobre o vídeo full-bleed. |
| 4 | Popup de assinatura cortado ("Talvez depois") | `SubscriptionPopup`/`PrerollConfirmation` são filhos soltos do Stack sem `SafeArea` — ficam sob a navbar. |

## 2. Descoberta que simplifica o escopo

Leitura do código (`_Viewport`, `camera_screen.dart:441-496`) revelou: **o `_Viewport` JÁ é um Stack full-bleed em camadas** — preview `Positioned.fill` no fundo (linha 447-450), overlays decorativos com `IgnorePointer` (grid/grain — hit-testing já resolvido), buffer pill / HUD / lens como `Positioned`. A arquitetura full-bleed **já existe dentro do `_Viewport`**.

O que trava o full-bleed é apenas a **moldura em volta** (`Padding` + `ClipRRect` + estar num `Expanded` da `Column`). Portanto o trabalho é **menor** que reestruturar: remover a moldura e reorganizar o `build` principal, reusando o `_Viewport` como está.

## 3. Escopo

**Nesta fatia:**
1. Câmera full-bleed: preview/viewport ocupa a tela toda; `_TopBar` e `_BottomControls` viram overlays por cima, com `SafeArea` (respiro de status bar + navbar responsivo, não hardcoded).
2. `SubscriptionPopup` + `PrerollConfirmation` com `SafeArea`.
3. Golden tests **com insets reais** (o que os goldens atuais não fazem) + design-fidelity vs protótipo.
4. Registro da divergência full-bleed vs protótipo (ADR leve / nota Blueprint).

**Fora (Bloco 3, sessões futuras):**
- Gravação Android ("Falha ao gravar") — stub proposital.
- Foco por toque Android (OnTouchListener nativo) — o full-bleed prepara a área de foco, mas o wiring nativo é outra fatia.
- Ring de foco visual (nativo).
- Qualquer mudança de contrato Pigeon / Swift / Kotlin.

## 4. Arquitetura full-bleed

**De `Column` para `Stack` em camadas** (de baixo pra cima):
```
Scaffold(body: Stack [
  Positioned.fill → _Viewport(...)          // preview + overlays internos, tela toda, SEM moldura
  SafeArea(child: Column [                    // camada de controles com respiro de insets
    _TopBar,                                  // (remove o padding top:60 hardcoded)
    Spacer(),                                 // empurra os controles pro rodapé
    _BottomControls,
  ]),
  if (_prerollConfirmationSeconds != null) SafeArea(child: PrerollConfirmation(...)),
  if (_popupVisible) SafeArea(child: SubscriptionPopup(...)),
])
```

**Racional:**
- O `_Viewport` como `Positioned.fill` ocupa a tela inteira. Perde o `Padding(horizontal 12)` e o `ClipRRect(radius 16)` — é isso que dá o full-bleed. NÃO reestruturar o interior do `_Viewport` (já é correto).
- `_TopBar` e `_BottomControls` sobem para uma `Column` dentro de `SafeArea`, com `Spacer` entre eles: TopBar cola no topo (respeitando status bar), BottomControls no rodapé (respeitando navbar). Ambos flutuam sobre o preview.
- `_TopBar` perde o inset top hardcoded: `EdgeInsets.fromLTRB(20, 60, 20, 12)` → `EdgeInsets.fromLTRB(20, 0, 20, 12)` — o `SafeArea` dá o respiro responsivo por aparelho. Mantém horizontal (20) e inferior (12).

**⚠️ Colisão de camadas a resolver (achado da verificação adversarial 2026-07-16):**
O `_Viewport` JÁ posiciona elementos no topo e no rodapé: `BufferPill` em `Positioned(top:12, right:12)` (`camera_screen.dart:467-471`) e a `Row [HudInfoBar, LensSwitcher]` em `Positioned(bottom:12, left:12, right:12)` (`:472-493`). Sobrepor `_TopBar` (topo) e `_BottomControls` (rodapé) na mesma tela full-bleed COLIDE com esses — `_BottomControls` cobriria o HUD/Lens; `_TopBar` (wordmark RARO) sobreporia o BufferPill. **Isto é uma regressão visual real que o design DEVE tratar.** **Decisão do dono (2026-07-16): empilhar com folga** — `_TopBar` (RARO) no topo com o `BufferPill` logo ABAIXO dele; `HudInfoBar`+`LensSwitcher` ACIMA da fileira `_BottomControls` (REC/galeria/settings). Ajustar os offsets `top`/`bottom` dos `Positioned` do `_Viewport` (hoje `top:12`/`bottom:12`) para acomodar TopBar/BottomControls sem sobreposição, empilhados verticalmente. NÃO unificar numa camada só (mais código/risco — Surgical). Um golden-com-insets (§5) DEVE incluir um cenário que detecta oclusão entre essas camadas.

**Hit-testing (Seção 2 do design):** grid/grain têm `IgnorePointer` (toque passa). PORÉM `CameraCenterHint`/`VoiceListeningIndicator` estão em `Center(...)` SEM `IgnorePointer` (`camera_screen.dart:463-466`) — a área central NÃO é incondicionalmente livre. Hoje isso é irrelevante (foco por toque Android é stub, Bloco 3), mas NÃO afirmar que o hit-testing central está resolvido. Garantir/adicionar `IgnorePointer` aos overlays centrais pertence à fatia de foco-Android (FORA daqui, §3). Nesta fatia, só garantir que a `Column` de controles com `Spacer` não introduz um fundo opaco cobrindo o centro.

## 5. Validação (o que evita repetir o erro da A2)

O erro anterior (SafeArea que criou tarja preta) passou porque o teste era estrutural ("existe SafeArea?"), não visual. Correção:

1. **Golden tests com insets reais (alchemist).** Renderizar `CameraScreen` com `MediaQuery(viewPadding: EdgeInsets(top: status, bottom: navbar))` — NÃO zero. Um golden com inset teria capturado a tarja preta. Cenários: câmera ready + not-ready; com/sem popup.
2. **design-fidelity-checker vs protótipo** (`docs/briefing/prototype/Prototipo-RARO.html` linha 824+). Ressalva: o protótipo tem moldura e nós fomos full-bleed (divergência intencional) — o checker vai apontar a moldura; isso é ESPERADO. Valida o resto (buffer presente, HUD, lens, copy, cores) 1:1.
3. **Prova no device (M54)** como confirmação final (não mais o único método): APK + fotos confirmam o resultado real.

O autor (Claude) DEVE inspecionar o PNG do golden e comparar com o alvo ANTES de entregar. Ver a imagem, não só rodar o teste.

## 6. Arquivos a tocar

| Arquivo | Mudança |
|---|---|
| `lib/features/camera/presentation/camera_screen.dart` | `build` principal: `Column` → `Stack` em camadas (§4). `_TopBar`: `EdgeInsets.fromLTRB(20,60,20,12)` → `EdgeInsets.fromLTRB(20,0,20,12)` (SafeArea supre o top). Resolver colisão TopBar/BottomControls vs BufferPill/HUD do viewport (§4). |
| `lib/features/camera/presentation/camera_preview_widget.dart` | Provável intocado (já expõe `showOverlays:false`). Confirmar. |
| `_Viewport` (em camera_screen.dart) | Intocado internamente (já é full-bleed). Só sai da moldura. |
| Golden tests câmera (novos + regenerar existentes) | Golden com insets reais; regenerar baselines que mudam com o full-bleed. |
| ADR leve / nota Blueprint | Registrar divergência full-bleed vs protótipo. |

## 7. Contratos / não-regressão

- **Zero contrato Pigeon / enums / Swift / Kotlin.** `camera_screen.dart` só consome tipos gerados (`PigeonFormat`, `mapPigeonErrorCode`) — não define nem regenera. Verificado.
- **iOS:** tela compartilhada, então o full-bleed muda o iOS junto (coerência intencional). Regenerar/revisar goldens iOS de câmera se existirem. Build iOS compila.
- **Fallback not-ready:** preservar o `ColoredBox(bgDeep)` quando `!cameraReady` (`camera_screen.dart:450`) — full-bleed com fundo preto enquanto abre.
- Suíte Dart verde (citar total exato, não assumir).

## 8. Critérios de sucesso (DoD)

1. No M54: preview ocupa a tela toda, sem tarja preta; TopBar visível (topo não cortado); buffer pill + HUD + lens sobre o vídeo; popup de assinatura inteiro (não cortado).
2. Golden com insets reais: renderiza full-bleed correto (autor inspeciona o PNG).
3. design-fidelity vs protótipo: só a moldura diverge (documentado); resto bate.
4. `analyze` + `test` Dart verdes.
5. Build iOS compila; goldens iOS revisados.
6. Divergência registrada (ADR/Blueprint).
7. Diff sem `.swift`, sem regen Pigeon.

---

## Adendos pós-implementação (2026-07-16, auditoria pré-session-end)

Desvios conscientes descobertos/decididos na implementação — o código é a verdade; esta seção reconcilia a spec:

1. **1 linha de Kotlin foi necessária** (contradiz §3/§7 "zero Kotlin"): `PreviewView.ImplementationMode.COMPATIBLE` em `CameraPlatformView.kt`. Sem ela, o SurfaceView default fura a tela no full-bleed e ENGOLE todos os overlays Flutter (provado no M54: controles sumiram; o "popup cortado" original era o mesmo buraco). Commit `6793ed3`, ADR-0027, memória `raro-pattern-android-surfaceview-fullbleed-eats-overlays`.
2. **Popups NÃO ficaram em SafeArea** (contradiz §3.2/§4): `PrerollConfirmation` retorna `Positioned` (exige ser filho direto do Stack — SafeArea no meio quebra o parent data; teste pegou a regressão). O corte real do popup era o buraco do SurfaceView (item 1). `PrerollConfirmation` ajustado para `bottom: viewPadding+124` (não sobrepor os controles que subiram com o SafeArea).
3. **Offsets dos overlays viraram responsivos a insets** (a spec fixava 56/150 como ponto de partida): `overlayTop = viewPadding.top+16`, `overlayBottom = viewPadding.bottom+112` — hardcoded quebrava em devices com insets maiores (Dynamic Island ~59px; o full-bleed vale pro iOS).
4. **DoD §8.3 (design-fidelity)**: executado via workflow de auditoria (design-fidelity-checker, 2026-07-16). Resultado: moldura diverge (coberta pelo ADR-0027); 7 gaps menores pré-existentes registrados como backlog no session log (bufferBar nunca implementada, estado desarmado do BufferPill, grad-line dos controles, glow do REC, cores da lens pill, botão close do topo, literais fora de .arb → Bloco 4.6).
5. **DoD §8.2**: golden ganhou 2º cenário (popup inteiro sobre o full-bleed). Cenários recording/voice/not-ready ficam como melhoria futura.
