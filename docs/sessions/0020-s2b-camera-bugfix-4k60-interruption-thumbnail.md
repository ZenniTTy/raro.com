# 0020 — S2.B: correção dos 2 bugs da câmera (4K60 + interrupção) + 1 bug de thumbnail descoberto no device

- **Data:** 2026-06-04 → 2026-06-05
- **Duração:** ~5h (TDD lógica pura + nativo device-validated + 2 subagents de auditoria + 1 workflow de análise de harness + 3 ciclos de build/device)
- **Participantes:** Eduardo Rodrigues + Claude Code (Opus 4.8)
- **Branch:** `feat/camera-native-bridge`
- **Commits:** `a56a208` (fix gallery thumbnail), `c393e6c` (fix camera 4K60 + interrupção)

## Objetivo

Corrigir os **2 bugs pré-existentes da câmera** diagnosticados na sessão 0019 (causa-raiz já mapeada em `docs/superpowers/plans/2026-06-04-camera-format-and-interruption-bugs.md`): **Bug 1** = trocar resolução não reconfigurava a sessão (4K60 gravava 1080p caladinho), regido pelo **ADR-0021**; **Bug 2** = `AVError -11847 OperationInterrupted` ao abrir Settings virava "Falha ao gravar" genérico. Escopo do Bug 1 travado upfront com o usuário como **completo (ADR-0021 inteiro: lente física/virtual)**, não o mínimo.

## Contexto inicial

Pós-sessão 0019 (Task B0: pipeline unificado de gravação `.mp4` + ADR-0021 criado decidindo virtual=default / 4K60=opt-in lente física). Branch com working tree limpo, `/prime` rodado, iPhone 12 conectado/pareado (mas com a build instrumentada da 0019). ADR-0021 e ADR-0020 já Accepted, cobrindo a decisão de produto do Bug 1.

## O que foi feito

### Gate de processo (antes de tocar código)
- **adr-guardian** rodado antes de qualquer edição: ambos os bugs tocam o contrato Pigeon (Bug 2 = novo `CameraErrorCode.sessionInterrupted`; Bug 1 = `CameraCapabilities` para combos reais). **Veredito GO sem ADR novo**: Bug 1 coberto pelo ADR-0021 (a shape do DTO é decisão de implementação, não de ADR); Bug 2 é extensão aditiva coberta por bugfix. Achado: `warn-adr-drift.sh` NÃO dispara em `pigeons/` (só em `lib/core/native_bridges/`), então o source Pigeon não é tratado como gatilho de ADR pelo hook.

### Bug 2 — guard de interrupção (TDD na lógica pura + nativo)
- Flag `isInterrupted` no `CameraManager` (set em `wasInterruptedNotification`, limpa em `interruptionEndedNotification` + `startSession`); guards em `startRecording`/`setFormat` rejeitando com `CameraErrorCode.sessionInterrupted` (novo no Pigeon) em vez de propagar o `-11847` cru.
- **Removido o `onError(.sessionFailed("session interrupted"))` espontâneo** da interrupção — interrupção transitória não é falha; era a fonte do contágio "Falha ao gravar".
- Função pura `cameraErrorMessage` (TDD red-green 4/4) mapeia código→mensagem distinta; `camera_screen` mostra "Câmera interrompida. Tente novamente." em vez de "Falha ao gravar". XCTest nativo `CameraErrorMapperTests` (4) pina o mapeamento do enum.

### Bug 1 — resolução real 4K60 (ADR-0021, contrato + nativo + Dart/UI)
- **Contrato Pigeon:** `CameraCapabilities` trocou o produto cartesiano (`supportedResolutions × supportedFps`) por `List<FormatCapability{resolution, fps, requiresPhysicalLens}>` (combos reais, device-agnostic). Re-codegen Dart+Swift+Kotlin.
- **Nativo:** `discoverCapabilities` lê `device.formats` reais do device virtual **E** da lente física (`builtInWideAngleCamera`), com merge (virtual preferido, física só para combos exclusivos) — funções puras `resolutionForDimensions`/`mergeFormatCapabilities` testáveis (XCTest `CameraManagerCapabilitiesTests` 6/6). `selectDevice` escolhe a física para 4K60 (`uhd4k+fps60`), virtual para o resto. `applyFormat` **falha-alto** (`throw formatUnsupported`) — removido o fallback silencioso que gravava resolução errada. `setFormat` reconfigura a sessão (remove/add input) ao trocar device virtual↔física, com guard de gravação ativa (ADR-0020) e **restauração do zoom virtual ao voltar de 4K60**.
- **Dart/UI:** ligou `setFormat` ao `ref.listen(settings)` (antes só atualizava `_format` local — raiz do bug); HUD dinâmico (não mais hardcoded "1080p · 60FPS"); `LensSwitcher` desabilita 0.5× em 4K60 com microcopy "indisponível em 4K60"; Settings filtra catálogo por capabilities reais (`format_catalog` TDD 9/9), oculta FPS em 4K60; `setResolution(uhd4k60)` coage `fps=60` (estado consistente). Novo `capabilities_provider` keepAlive desacopla capabilities do ciclo de vida da sessão.
- **PROVA no iPhone 12** via dump do vault (`devicectl copy from appDataContainer`) + ffprobe: **4K60 gravou `3840×2160@60` real**, 4K30/1080p/720p todos distintos. Antes (clipes pré-fix): tudo 1080p. Evidência de hardware, não percepção.

### Bug 3 — thumbnail some ao reinstalar (DESCOBERTO na validação device)
- Relatado pelo usuário durante a validação: as thumbnails sumiam a cada rebuild (caíam no fallback gradiente "capas coloridas"). Causa-raiz confirmada via inspeção do sidecar dumpado: `thumbnailPath` salvo como **path absoluto com o UUID do container iOS** (`/var/mobile/Containers/Data/Application/<UUID>/...`), que o iOS regenera a cada instalação. O `.jpg` físico continuava no vault; só o path ficava stale. O vídeo nunca sofreu porque `filePath` já era recomputado por id.
- Fix: `VaultService._toEntity` recomputa o `thumbnailPath` por id (existência do `.jpg`) em vez de confiar no sidecar. 3 testes de regressão (path stale ignorado, recomputado por id, null sem `.jpg`) + ajuste de 2 testes que pinavam o comportamento antigo. Validado no device (thumbnails reaparecem). Memória nova `raro-pattern-ios-container-uuid-stale-absolute-path`.

### Auditoria independente (boas práticas)
- **validator** (read-only) auditou o nativo contra o ADR-0021: achou o **item G** (bloqueador real) — `setFormat` não reaplicava `applyVirtualLensZoom` ao voltar de 4K60, deixando o zoom contínuo (assinatura do produto) num estado default → corrigido. + item E (unlock perdido em caminho de erro → `defer`). Confirmou ausência de deadlock no `outputQueue.sync`.
- **code-reviewer** achou 3 (todos válidos, todos aplicados): (1) `ref.listen` reconfigurava a sessão em **qualquer** mudança de settings (idioma/buffer) causando pisca → gate por mudança real de format; (2) fps stale ao escolher uhd4k60 → coerção fps=60; (3) `availableFpsFor` dead code → removido (anti-entropia).

**Gates finais:** analyze 0 · Dart 255/255 · XCTest nativo 10 novos exit 0 · iOS `✓ Built 46.9MB` · **device validado pelo usuário** (os 3 bugs). 2 commits Conventional, 0 `--no-verify`.

## O que NÃO foi feito (e por quê)

- **Replay buffer (B2/B3 da S2.B)** — o objetivo maior da Sprint 2.B continua pendente; estes bugs eram pré-condição. O pipeline unificado (B0, sessão 0019) já está no lugar; o replay vem na próxima sessão.
- **Tap-to-focus Android / lens switch Android** — fora de escopo (Sprint 3).
- **`thumbnailPath` no sidecar** — segue sendo escrito (em `attachThumbnail`) embora ignorado na leitura. Não removido por ser refactor de passagem (Surgical Changes); inofensivo, possível débito futuro.
- **Limpeza dos `.mov` antigos do vault** — vídeos pré-B0 seguem órfãos no device (decisão ADR-0020 "vault novo"); reinstalar limpa.

## Aprendizados / surpresas

- **O fallback silencioso era o vilão invisível.** O `applyFormat` escolhia "o format mais próximo" sem erro quando o pedido não existia — então 4K virava 1080p caladinho. A suíte de 255 testes Dart + analyze 0 NÃO pegariam isso; só a **prova objetiva em device** (dump do vault via `devicectl copy from appDataContainer` + `ffprobe`) revelou `3840×2160@60` real onde antes tudo saía 1080p. Lição reforçada: para caminho que decide formato gravado, teste verde ≠ correto — precisa de prova de hardware.
- **`device.formats` de device virtual ≠ capability de hardware** (reforço da 0019): o 4K60 existe no iPhone 12 mas vive na lente **física** (`builtInWideAngleCamera`), não no virtual (`builtInDualWideCamera`) que o RARO usa pelo zoom contínuo. `discoverCapabilities` precisou ler os dois e marcar `requiresPhysicalLens`.
- **Reconfigurar device reseta o `videoZoomFactor`** (achado do validator, item G): ao voltar de 4K60-física para o virtual, o `setFormat` trocava o input mas não reaplicava `applyVirtualLensZoom` → o zoom contínuo (assinatura do produto) travava no default. Bloqueador real pego na auditoria read-only antes do device. Virou corolário na memória `raro-pattern-ios-avcapture-iphone12-dualwide-zoom-mapping`.
- **Path absoluto persistido morre na reinstalação** (Bug 3, descoberto no device): o `thumbnailPath` no sidecar carregava o UUID do container iOS, que muda a cada install; o `.jpg` físico sobrevivia, só o path ficava stale. O vídeo nunca sofreu porque `filePath` já era recomputado por id — a cura foi aplicar o mesmo padrão à thumbnail. Memória `raro-pattern-ios-container-uuid-stale-absolute-path`.
- **O método multi-camada funcionou e pagou:** adr-guardian ANTES de tocar o contrato (e foi ele, não o hook, que flagrou o gap do `warn-adr-drift` em `pigeons/`); TDD na lógica pura (cameraErrorMessage 4/4, format_catalog 9/9) + XCTest nativo (10 novos) onde a integração AVFoundation não alcança; validator read-only pegou o item G + E; code-reviewer pegou mais 3 (reconfig em qualquer settings change, fps stale em 4K60, dead code). Cada camada pegou algo que a anterior não pegaria.
- **XCTest novo não é auto-descoberto** — exigiu 4 inserções manuais no `project.pbxproj` por arquivo; esquecer qualquer uma = teste some do alvo sem erro, suite verde sem rodar asserts. Virou memória `raro-pattern-ios-xctest-pbxproj-4-insertions`.

### Decisão de harness (workflow adversarial: 3 lentes → verificação → síntese)

Avaliados 8 candidatos contra o critério §11 (só vira regra se impacto não-recuperável OU >1 feature OU não cabe em memória); 1 rejeitado, 3 duplicados consolidados. Veredito:

- **MUST (auto-modificação do harness — aguardando aprovação do usuário):**
  1. `warn-adr-drift.sh` passa a vigiar `apps/mobile/pigeons/*.dart` (fonte do contrato Pigeon) — hoje só cobre `lib/core/native_bridges/*` (saída gerada); 1 linha no `case`. Passa §11 (>1 feature: todo contrato Pigeon).
  2. CLAUDE.md §10: nova linha de gate exigindo **prova ffprobe de formato em iPhone físico** para qualquer toque no caminho resolução/fps/codec (selectDevice, applyFormat/setFormat, discoverCapabilities, AVAssetWriter settings, FormatCapability/CameraCapabilities). Passa §11 (impacto não-recuperável: vídeo do usuário na resolução errada + >1 feature).
- **SHOULD (memória — já aplicado, não é harness):** corolário do reset de `videoZoomFactor` (anexado à memória dualwide); 4 inserções pbxproj para XCTest (memória nova).
- **OPTIONAL:** sumário por suite no runner XCTest (torna órfão visível sem grep manual).
- **REJEITADO:** memória "validator pega o que widget mock não pega" — princípio já consolidado em `raro-pattern-flutter-async-native-state-needs-notifier` (Meta-lição) + subagent validator + gate §10 existentes; o único conteúdo novo era um exemplo, e o bug foi pego antes do merge (recuperável). A frase "fallback silencioso é proibido" foi deixada FORA do gate §10 por já viver no código (`throw formatUnsupported`) e sob §11 (swallow de erro).

## Próximos passos

- **Próxima sessão (S2.B replay buffer):** B2 `ReplayBuffer.swift` (ring encoded fragmented-MP4, contrato no `replay_buffer_api.dart` dedicado, `saveReplay` async) → B3 provider `@riverpod` Notifier reativo → B-Gate device. Escrever red-before-green os órfãos vault-race + ref-after-dispose (`2026-06-04-orphan-guards-hardening.md`).
- Avaliar mudanças de harness propostas (ver Aprendizados).
- Pendência operacional resolvida: build limpa reinstalada no iPhone 12 nesta sessão (não está mais com a versão instrumentada da 0019).

## Referências

- ADR-0021 (4K60 lente física vs zoom virtual): [../decisions/0021-4k60-physical-lens-vs-virtual-zoom.md](../decisions/0021-4k60-physical-lens-vs-virtual-zoom.md)
- ADR-0020 (pipeline unificado): [../decisions/0020-unified-capture-pipeline-videodataoutput.md](../decisions/0020-unified-capture-pipeline-videodataoutput.md)
- Plano de bugfix: [../superpowers/plans/2026-06-04-camera-format-and-interruption-bugs.md](../superpowers/plans/2026-06-04-camera-format-and-interruption-bugs.md)
- Sessão anterior: [0019-s2b-task-b0-recording-pipeline-migration.md](0019-s2b-task-b0-recording-pipeline-migration.md)
- Memória nova: `raro-pattern-ios-container-uuid-stale-absolute-path`
