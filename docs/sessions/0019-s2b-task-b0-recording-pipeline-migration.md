# 0019 — S2.B Task B0: migração do pipeline de gravação + diagnóstico de 2 bugs + ADR-0021

- **Data:** 2026-06-04
- **Duração:** ~5h (TDD + refactor nativo + múltiplos ciclos de build/device + 2 workflows de pesquisa + ADR)
- **Participantes:** Eduardo Rodrigues + Claude Code (Opus 4.8)
- **Branch:** `feat/camera-native-bridge`
- **Commits:** `f45cf98` (B0 migração), `2a1c95f` (plano bugfix), `539184c` (ADR-0021)

## Objetivo

Sprint 2 S2.B Task B0: migrar a gravação contínua de `AVCaptureMovieFileOutput` para o pipeline unificado `AVCaptureVideoDataOutput`+`AVAssetWriter` (pré-requisito do replay buffer — os dois outputs não coexistem, ADR-0020). Validar no iPhone 12 físico (gate §10). Escopo travado upfront como "só Task B0" (replay B2/B3 fica para próxima sessão).

## Contexto inicial

Pós-sessão 0018 (pré-flight S2.B: ADR-0020 criado, ADR-0018 superseded, ADR-0003 revisado). O ADR-0020 decidiu o pipeline unificado; a B0 é a primeira implementação dele. Branch com working tree limpo, `/prime` rodado, iPhone 12 conectado e pareado.

## O que foi feito

### B0 — migração da gravação (TDD onde dá + device gate onde TDD não alcança)
Decisão de método confirmada com o usuário (TDD aplica à lógica pura; integração AVFoundation só valida em device — XCTest com sample buffers fake é cego para o bug real, S2B-09 da auditoria):
- **TDD red-green** da migração `.mov`→`.mp4`: invertí `vault_service_test` (`endsWith('a1.mp4')`) e o XCTest `makeOutputURL` → RED confirmado pelo motivo certo (`Expected .mp4, Actual .mov`) → GREEN mínimo (`_videoFile` + `makeOutputURL` para `.mp4`) → suíte 240/240 + analyze 0.
- **Refactor `RecordingPipeline.swift`** (não-TDD, device-validated): de `MovieFileOutput` para `AVCaptureVideoDataOutput`+`AVCaptureAudioDataOutput` em **queue dedicada** (não a `sessionQueue`, p/ não competir com `focusAtAsync`); `AVAssetWriter(.mp4)` com `startSession(atSourceTime:)` no PTS do 1º buffer; `finishWriting(completionHandler:)` assíncrono (mantém `onRecordingFinished`); `canAdd` tratado como erro explícito (antes engolido); codec adaptativo HEVC/H264 sobre `recommendedVideoSettingsForAssetWriter` (validado como boas-práticas via pesquisa, não suposição).
- **PROVA no iPhone 12** (via dump do vault com `devicectl copy from` + ffprobe): 4 `.mp4` reais gerados, **HEVC 1080×1920 + áudio AAC sincronizado**, thumbnail `.jpg` gerado, preview reproduz. A B0 funciona.

### Diagnóstico de 2 bugs PRÉ-EXISTENTES (systematic-debugging, evidência de device)
O usuário relatou "falha ao gravar" + "resolução não muda" + "galeria com mock/capas coloridas". Investigação com logs reais (`idevicesyslog`, dump do vault) provou que **nenhum é regressão da B0**:
- **Galeria mock/capas coloridas:** são os 7-8 vídeos `.mov` antigos (pré-B0) que a galeria não acha mais (path agora `.mp4`); 6 nunca tiveram `.jpg` → fallback gradiente. Decisão ADR-0020 "vault novo" — lixo benigno.
- **Bug 1 — resolução não muda (4K sai 1080p):** `ref.listen(settingsControllerProvider)` em `camera_screen.dart:~168` atualiza `_format` local mas **nunca chama `setFormat`** na sessão. Confirmado pré-existente: os `.mov` antigos (MovieFileOutput) também eram todos 1080p.
- **Bug 2 — "Falha ao gravar" em fluxo de Settings:** `AVFoundationErrorDomain -11847 (OperationInterrupted)` — abrir Settings tira o app de foreground → sessão AVCapture interrompida (`HangTracer: no longer foreground` + `session interruption ended — resuming`); operar nesse gap dispara o erro que vira "Falha ao gravar". Causa-raiz confirmada via syslog.
- Documentados em `docs/superpowers/plans/2026-06-04-camera-format-and-interruption-bugs.md`.

### ADR-0021 — decisão de produto sobre 4K60
A investigação do Bug 1 virou uma decisão arquitetural. Dois workflows de pesquisa adversarial (feasibility + UX) estabeleceram:
- iPhone 12 base **TEM 4K60 nativo** (spec Apple 111876), mas vive na lente **física** (`builtInWideAngleCamera`), não no device virtual (`builtInDualWideCamera`) que o RARO usa pelo zoom contínuo (ADR-0015). As duas não coexistem no iPhone 12.
- Forçar via upscale/interpolação descartado (enganoso, risco App Review 2.3).
- Apps pro (Kino/Filmic/Blackmagic) escolhem lente física — mas o público deles é o operador deliberado; o RARO é o oposto ("nunca perca o momento", hands-free).
- **Decisão:** virtual permanece DEFAULT (zoom contínuo = assinatura); 4K60 vira opt-in avançado em Settings que aciona a lente física + zoom discreto (0.5× desabilitado com microcopy). Não-negociável: UI nunca oferece combos impossíveis. Refina ADR-0015 item 2.

**Gates:** analyze 0 · Dart 240/240 · iOS `✓ Built 46.9MB`. 3 commits Conventional, 0 `--no-verify` (1 barrado pelo commitlint por maiúscula no subject → corrigido, não bypassado).

## O que NÃO foi feito (e por quê)

- **Implementação do Bug 1 (selectDevice físico/virtual + capabilities reais + UI de zoom condicional + Settings 4K60)** — é uma feature arquitetural inteira, não bugfix pequeno. Escopo aprovado pelo usuário, mas fatiado: esta sessão entrega só a **decisão** (ADR-0021); a implementação vira próxima(s) sessão(ões). Respeita 1-sessão-1-entregável.
- **Bug 2 (guard `isInterrupted` + msg UI)** — não corrigido; causa-raiz mapeada no plano de bugfix. Próxima sessão.
- **Replay buffer (B2/B3)** — fora do escopo da B0 desde o início; só vem depois da B0 + bugs.
- **Reinstalar build limpa no device** — o iPhone está com a versão instrumentada (logs `.fault`/DIAG de debug que adicionei e depois removi do código, mas o `.app` no device ainda é o instrumentado). A instrumentação foi removida do código-fonte (tree limpo); reinstalar a limpa quando reconectar.
- **Limpeza do vault `.mov` antigo** — os vídeos antigos seguem órfãos no device (decisão ADR-0020 "vault novo"). Reinstalar o app limpa.

## Aprendizados / surpresas

- **ERREI e me corrigi — registrado honestamente.** Ao ver no `device.formats` que o virtual só listava até `1920x1440@60`, concluí prematuramente "iPhone 12 não tem 4K60". **Errado.** A pesquisa adversarial (spec oficial Apple) provou que tem — só está na lente física, não no virtual. Lição: o `device.formats` de um device virtual NÃO reflete o que o hardware suporta; reflete o que aquele device específico expõe. Não concluir capability de hardware a partir de um device virtual.
- **"Exit 0 enganoso" reconfirmado:** o build `--simulator` reportou exit 0 mas falhou em "destination not found" — o sinal real era `Xcode build done` (Swift compilou) antes do erro de destination. Conferir o sinal, não o exit code (memória existente).
- **Dump do vault do device (`devicectl copy from ... appDataContainer`) é evidência superior a log.** Quando os `os_log .info` não saíam no syslog clássico, puxar os arquivos reais + ffprobe respondeu tudo (o que gravou, em que resolução, com áudio) sem depender de log. Técnica nova para o toolkit de device-debug.
- **Disciplina de escopo segurou 4 vezes:** confrontei via AskUserQuestion antes de cada expansão (TDD vs device; corrigir bugs vs fechar B0; fix 4K60 vs ADR; fatiar a implementação). Sem isso, teria virado uma sessão gigante e meio-feita.
- **A pesquisa-antes-de-codar evitou um fix errado:** eu ia "corrigir" o override do codec achando ser a causa do 4K60 falhar; a pesquisa mostrou que o override é boas-práticas e a causa era outra (device virtual). Iron Law do debugging (não fixar sem causa confirmada) pagou.

## Próximos passos

- **Próxima sessão:** implementar Bug 1 conforme ADR-0021 (nativo: `selectDevice` condicional físico/virtual + `discoverCapabilities` reais + `applyFormat` falha-alto; Dart/UI: ligar `setFormat` ao `ref.listen` + UI de zoom condicional + Settings 4K60 + filtrar catálogo por capabilities). Validar 4K60 real em device (ffprobe → `3840×2160@60`).
- **Bug 2** (guard de interrupção) — pode ser a mesma sessão ou própria.
- **Depois:** replay buffer (B2/B3) — o objetivo maior da S2.B, agora com o pipeline unificado já no lugar.
- Reinstalar build limpa no iPhone 12; opcionalmente limpar vault `.mov` antigo.

## Referências

- ADR-0021: [../decisions/0021-4k60-physical-lens-vs-virtual-zoom.md](../decisions/0021-4k60-physical-lens-vs-virtual-zoom.md)
- ADR-0020 (pipeline unificado, implementado aqui): [../decisions/0020-unified-capture-pipeline-videodataoutput.md](../decisions/0020-unified-capture-pipeline-videodataoutput.md)
- Plano de bugfix: [../superpowers/plans/2026-06-04-camera-format-and-interruption-bugs.md](../superpowers/plans/2026-06-04-camera-format-and-interruption-bugs.md)
- Sessão anterior: [0018-s2b-preflight-planning-hardening.md](0018-s2b-preflight-planning-hardening.md)
