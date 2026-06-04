# 0021 — 4K60 (lente física) vs zoom virtual contínuo: virtual por default, 4K60 opt-in

- **Data:** 2026-06-04
- **Status:** Accepted
- **Relaciona:** ADR-0015 (camera native bridge strategy — VirtualCameraStrategy única), ADR-0020 (pipeline unificado), ADR-0016 (harness E2E / validação device).
- **Decisores:** Eduardo Rodrigues
- **Contexto:** Bug descoberto na validação device da Task B0 (sessão 0019) — selecionar "4K 60fps" nas Settings não muda a resolução real (grava 1080p). Investigação revelou um conflito de hardware que exige decisão de produto.

## Contexto

Durante o B-Gate da Task B0, a validação no iPhone 12 físico revelou que selecionar 4K@60fps grava 1080p silenciosamente (o fps muda para 60, a resolução não). Investigação (workflows de pesquisa adversarial, sessão 0019) estabeleceu os fatos:

1. **O iPhone 12 base TEM 4K@60fps nativo (SDR).** Confirmado na spec oficial da Apple (`support.apple.com/en-us/111876`): "4K video recording at 24 fps, 25 fps, 30 fps, or 60 fps". A única limitação real do base vs Pro é o HDR Dolby Vision (base: até 4K30; Pro: até 4K60) — **não** a captura SDR padrão.

2. **O 4K@60 vive na lente FÍSICA, não na virtual.** O `CameraManager.selectDevice` (`apps/mobile/ios/Runner/Native/Camera/CameraManager.swift`, ~linhas 408-434) retorna o **device virtual** (`builtInDualWideCamera`) PRIMEIRO para ambas as lentes — escolha do ADR-0015, que prioriza o zoom 0.5×↔1× contínuo (smooth switchover). O `.formats` do device virtual só expõe combinações que rodam em contexto multi-cam/virtual-switchover, que a Apple capa em ~4K30. O format `3840×2160@60` existe apenas no `.formats` da lente física `builtInWideAngleCamera`. (Confirmado em device: o dump de `formats>=60fps` do virtual no iPhone 12 vai no máximo até `1920×1440@60`.)

3. **Mutual exclusividade no iPhone 12:** não é possível ter 4K60 **e** zoom virtual contínuo ao mesmo tempo. Ou se usa a lente física (4K60, mas o 0.5× vira troca discreta de input — e o ultra-wide nem grava 4K60 no iPhone 12), ou se usa a virtual (zoom contínuo suave, mas teto ~4K30).

4. **"Forçar" 4K60 onde não há é descartado.** Como o hardware tem 4K60 nativo, upscale (1080→4K) ou interpolação (30→60) seriam enganosos (qualidade falsa, risco App Review Guideline 2.3) e desnecessários.

5. **Como apps de câmera resolvem (pesquisa):** apps profissionais (Kino/Lux, Filmic Pro, Blackmagic Camera) escolhem a **lente física** e abandonam o zoom contínuo — porque o cliente deles é o operador deliberado, para quem qualidade óptica vence flexibilidade. Kino (FAQ): *"We cannot both offer top quality video capture with pro tools while keeping that smooth zooming effect. We have to choose one. We chose the best quality."* Filmic Pro chegou a ter a câmera virtual e a **removeu** (v6.14) porque ela desabilita controles manuais e troca de lente de forma imprevisível.

## Opções consideradas

1. **Manter virtual sempre (status quo do ADR-0015), capar 4K a 30fps.**
   - Prós: preserva o zoom 0.5×↔1× contínuo (assinatura do produto); zero conflito; menor mudança.
   - Contras: 4K60 fica indisponível neste device; a UI precisa parar de oferecê-lo.

2. **Lente física como default (como os apps pro), 4K60 prioritário.**
   - Prós: qualidade máxima; 4K60 funciona.
   - Contras: perde o zoom contínuo (vira troca discreta com blackout); contraria o ADR-0015 e o posicionamento do RARO ("apontar e capturar sem fricção").

3. **Virtual por default + 4K60 como opt-in explícito na lente física.** (escolhida)
   - Prós: preserva a experiência central (zoom suave) para o usuário comum; oferece 4K60 honestamente para quem escolhe conscientemente; UI nunca oferece o impossível.
   - Contras: dois caminhos de device a manter; UI de zoom condicional ao formato; mais complexidade.

4. **Forçar 4K60 via upscale/interpolação.**
   - Prós: nenhum real.
   - Contras: enganoso, qualidade falsa, risco App Review. Descartado.

## Decisão

**Opção 3.** O RARO mantém a **câmera virtual como default** (zoom 0.5×↔1× contínuo, ADR-0015 preservado) e oferece **4K@60fps como opção avançada opt-in** que troca para a lente física.

Justificativa de produto: o RARO é sobre **"nunca perder o momento"** (hands-free, wake word, replay buffer). O zoom contínuo suave É a feature que faz "apontar e capturar" funcionar sem fricção — diferente dos apps de cineasta (operador deliberado), o público do RARO não para para escolher lente. 4K60 vs 4K30 é um ganho de fidelidade que o público majoritariamente não nota em vídeo de momento espontâneo; o custo (perder o zoom fluido) é alto. Logo, o default prioriza fluidez; 4K60 é "para quem sabe o que está fazendo".

**Princípio não-negociável:** a UI **nunca** oferece combinações que o device não entrega. O estado atual (oferecer "4K60" e gravar 1080p caladinho) é enganoso e é eliminado. O catálogo de resolução/fps passa a ser filtrado pelo `AVCaptureDevice.format` real do device.

Comportamento detalhado (a implementar em sessões futuras):

- **Default:** device virtual, zoom contínuo, resoluções até 4K30.
- **4K60:** opção avançada em **Settings** (não toggle na tela de câmera — convenção do app nativo: qualidade/fps é decisão global pré-gravação). Rótulo carrega o trade-off: ex. "4K60 (lente fixa)".
- **Ao ativar 4K60:** `selectDevice` passa a usar `builtInWideAngleCamera` (física); o controle de zoom na tela de câmera vira **seletor de lente discreto**; o 0.5× (ultra-wide) fica **desabilitado com microcopy** ("indisponível em 4K60") — não some, não dá blackout, não dá erro.
- **`discoverCapabilities`** passa a reportar resoluções/fps **reais** do device (hoje retorna lista hardcoded `[.hd720, .fhd1080, .uhd4k] × [.fps30, .fps60]` — `CameraManager.swift:135-139`), não combos inexistentes.
- **Falhar alto, não baixo:** quando o usuário pede explicitamente um format que não existe, propagar erro/telemetria visível em vez do fallback silencioso atual (`applyFormat`, branch de fallback) — para o próximo bug deste tipo não passar despercebido.

## Consequências

- **Positivas:**
  - Preserva a assinatura do produto (zoom contínuo) para o caso de uso central.
  - 4K60 disponível honestamente para quem opta.
  - UI deixa de enganar (combos reais apenas).
  - Alinhado com a convenção do app nativo do iPhone (resolução em Settings; 0.5× degrada em 4K60).

- **Negativas / riscos:**
  - `selectDevice` ganha lógica condicional (físico vs virtual conforme o format pedido) — toca hot path de câmera (gate §10: validação em iPhone físico obrigatória).
  - Controle de zoom da UI passa a depender do formato ativo (slider contínuo vs seletor discreto).
  - Trocar de device (virtual↔física) ao mudar para/de 4K60 exige reconfiguração de sessão (begin/commitConfiguration + remove/add input) — coordenar com o pipeline de gravação do ADR-0020 (não trocar durante gravação).
  - Dois caminhos de device a testar.

- **Como reverter:** novo ADR. Reverter para o ADR-0015 puro (virtual sempre) significa remover a opção 4K60 e voltar a capar em 4K30 — sem o engano do fallback silencioso.

## Implementação (escopo de sessões futuras — NÃO nesta sessão)

Documentado em `docs/superpowers/plans/2026-06-04-camera-format-and-interruption-bugs.md` (Bug 1). Quebra sugerida:
1. Nativo: `selectDevice` condicional (físico para 4K60) + `discoverCapabilities` reais + `applyFormat` falha-alto.
2. Dart/UI: ligar `setFormat` ao `ref.listen(settings)` (hoje não chama — `camera_screen.dart:~168`); UI de zoom condicional ao formato; Settings expõe 4K60 com microcopy; filtrar catálogo por capabilities reais.
3. Validação device (gate §10): 4K60 grava `3840×2160@60` real (ffprobe); 0.5× desabilitado com microcopy em 4K60; zoom contínuo intacto no default.

## Referências

- ADR-0015 (VirtualCameraStrategy): [0015-camera-native-bridge-strategy.md](0015-camera-native-bridge-strategy.md)
- ADR-0020 (pipeline unificado): [0020-unified-capture-pipeline-videodataoutput.md](0020-unified-capture-pipeline-videodataoutput.md)
- Plano de bugfix: [../superpowers/plans/2026-06-04-camera-format-and-interruption-bugs.md](../superpowers/plans/2026-06-04-camera-format-and-interruption-bugs.md)
- Apple spec iPhone 12: `support.apple.com/en-us/111876` ("4K at 24/25/30/60 fps"; HDR Dolby Vision até 4K30 no base)
- Apple docs: `AVCaptureDevice.formats`, `builtInWideAngleCamera`, `builtInDualWideCamera`, `isMultiCamSupported`
- Kino (Lux) FAQ (escolha lente física vs zoom contínuo); Filmic Pro v6.14 release notes (remoção da Zoom lens); Blackmagic Camera (seletor de lente discreto + zoom digital)
- Código: `CameraManager.swift` `selectDevice` (~408-434), `discoverCapabilities` (135-139), `applyFormat` fallback (~487-514)
- Sessão 0019 (descoberta + pesquisa): `docs/sessions/0019-*.md`
- Memória `raro-pattern-ios-avcapture-iphone12-dualwide-zoom-mapping`
