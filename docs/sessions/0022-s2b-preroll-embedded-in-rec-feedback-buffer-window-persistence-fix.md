# 0022 — S2.B: pré-roll embutido no REC + feedback visível + fix de persistência/sync da janela do buffer

- **Data:** 2026-06-07
- **Duração:** ~1 sessão de contexto longa (1 compactação)
- **Participantes:** Eduardo Rodrigues + Claude Code (Opus 4.8)
- **Branch:** `feat/camera-native-bridge`
- **Commits:** `8983740`, `4953d5a`, `441df9d`, `483f38b`, `67bae21`, `6d7bf35` (6 commits)

## Objetivo

Entregar o **pré-roll embutido no REC** (Sprint 2 Sessão S2.B, fatia seguinte): apertar REC passa a embutir os últimos N segundos (15/30s) do buffer no início do arquivo gravado — copiando a mecânica do concorrente "Ok Câmera", consertando o feedback silencioso que o tornou confuso. Resultado: um `.mp4` único `[pré-roll + gravação]` com aviso visível na tela. Mid-flight, o usuário validou no device e reportou **2 bugs de persistência/sincronização da janela do buffer** que também foram corrigidos nesta sessão.

## Contexto inicial

A mecânica do replay buffer fechou na 0021 (chunked disk-ring grava contínuo, pill troca 15/30s, `saveReplay` nativo concatena por composition, gate térmico corrigido, validado no iPhone 12). **Gap:** nenhum gatilho de UI chamava um save com pré-roll — o pill "só mudava o texto". Esta fatia ligou o primeiro gatilho real. Desenho técnico pré-validado em memória `raro-preroll-rec-design-s2c`.

## O que foi feito

**1. ADR-0003 Addendum 2026-06-07** (`8983740`, ANTES do codegen — ordem não-negociável): cláusula `includeReplayPreroll` (modo de export combinado `windowChunks`+G1, não-default). adr-guardian deu **GO** (cobre flag + callback nominalmente).

**2. Contrato Pigeon + fix de estado catalogado** (`4953d5a`): `RecordingOptions` ganha `bool includeReplayPreroll=false`; `CameraFlutterApi` ganha `onRecordingStarted(sessionId)`. Regenerados os 4 (Dart gitignored, Swift+Kotlin trackados). **Fix do bug `raro-pattern-flutter-async-native-state-needs-notifier`:** `RecordingController.start` deixou de promover `RecordingActive` no retorno do `await` (estado otimista que dessincroniza); agora passa por `RecordingStarting` até o nativo confirmar via `onRecordingStarted`. UI trata starting+active como gravando (REC responde no tap). TDD: 10 testes verdes no `recording_controller_test`.

**3. Flag no call site** (`441df9d`): `_onRecTap` passa `includeReplayPreroll: true` só quando o buffer está armado (`ReplayBuffering`). TDD: 2 testes (armado→true, não-armado→false).

**4. Coração nativo** (`483f38b`): **CORREÇÃO da estratégia da memória** — o desenho dizia "snapshot no STOP", o que DUPLICARIA footage (o fan-out alimenta ring E G1 durante a gravação). Websearch (modelo de pré-buffer dashcam/GoPro HindSight) confirmou: pré-roll = N s ANTES do trigger, sequencial, sem overlap. Implementado: `ReplayBuffer.snapshotChunks()` (cópia thread-safe), `pauseAppending()`/`resumeAppending()`, `shouldAppend(buffering:paused:)` puro, `exportCombined(prerollChunks:recording:)` reusando `export()` (refatorado p/ completion). `CameraManager` coordena: no START captura snapshot + pausa ring + emite `onRecordingStarted`; no STOP (dentro do completion do G1, logo o arquivo já existe) compõe `[snapshot + G1]` → `.mp4` único; resume sempre. Snapshot vazio/export falho/lente trocada = entrega G1 pura (graciosa). XCTest: `testShouldAppendOnlyWhenBufferingAndNotPaused` + `testWindowChunksReturnsValueCopyNotMutatingRing` rodaram verde (não só exit 0). **Auditoria independente (validator):** GO + 3 achados menores corrigidos (switchLens físico bloqueado durante REC; insert por chunk loga falha; resume no throw de stopRecording).

**5. Feedback visível** (`67bae21`, conserta o silêncio do concorrente): `ReplayArmRing` enche um anel no botão REC em N s ao armar o buffer (timer client-side modelando o tempo REAL de enchimento — decisão do usuário, honesto, sem sinal nativo novo); `PrerollConfirmation` mostra "últimos Ns incluídos" ~1.8s ao terminar gravação com pré-roll. Widget TDD para ambos + teste de fluxo no `camera_screen`.

**6. Fix de persistência/sync da janela do buffer** (`6d7bf35`, bugs device-validated pelo usuário): a duração tinha **fontes duplicadas** — câmera usava `BufferDuration{fifteenSec,thirtySec}` próprio em `camera_shell_state` (provider autoDispose, nunca persistia) e Settings usava `BufferDuration{seconds15,seconds30}` de `raro_shared` (persistido). Eram enums diferentes → não se falavam: 30s no pill voltava a 15s ao sair/voltar, e mudar na câmera não refletia em Settings. **Fix:** duração vive só no `settingsController` (persistido, enum `raro_shared`); pill lê/escreve via `toggleBufferDuration()`; `setWindow` nativo dispara nos 2 sentidos por um `ref.listen(settingsControllerProvider)` consolidado. Removido o `BufferDuration` duplicado de `camera_shell_state` (débito da 0013). Default unificado = 30s. 2 testes de regressão pinando persistência + sync bidirecional.

**Gates automatizados (todos verdes):** analyze 0 · Dart 290/290 · XCTest nativo iPhone 17 Pro Simulator todos passam (build com a stack final). Build profile `✓ Built Runner.app 47.1MB` (timestamp fresh) instalado no iPhone 12 via devicectl. **Usuário validou no device: pré-roll funcionando perfeitamente** (anel + confirmação + arquivo combinado).

## O que NÃO foi feito (e por quê)

- **Gate §10 formal (ffprobe do `.mp4` combinado):** o usuário confirmou que o pré-roll funciona visualmente no iPhone 12, mas a prova objetiva por `ffprobe` (dimensões+fps reais do REC no arquivo combinado, puxado via devicectl) **não foi rodada**. Fica como verificação pendente — o gate §10 exige essa prova antes de declarar 100% fechado. Comandos prontos no Recovery abaixo.
- **Re-validação no device do fix de persistência:** o fix (`6d7bf35`) é **Dart-only** (zero mudança nativa), então o build já instalado no iPhone NÃO o contém. Validar a persistência 15/30s entre telas exige **rebuild** (o usuário pediu para não buildar agora; vai validar depois).
- **Degradar fps/resolução do buffer sob `.serious`:** segue como melhoria futura não-bloqueante (Addendum 2026-06-05).
- **Voz / botão de volume / RevenueCat sandbox / share / analytics:** fora do escopo da fatia (backlog Sprint 2). Android nativo do replay = Sprint 3.
- **Merge `feat/camera-native-bridge` → `develop`:** segurado (gates G1/G7 perf + Android M54 + goldens abertos).

## Aprendizados / surpresas

- **A memória de design tinha um bug de overlap.** "Snapshot no STOP" duplicaria footage porque o ring enche durante a gravação. Cruzar o desenho com o código real + websearch (semântica de pré-buffer da indústria) pegou antes de implementar. Pré-roll = pré-trigger, sequencial. Memória `raro-preroll-rec-design-s2c` corrigida.
- **Duas fontes de verdade pra preferência do usuário = bug de persistência/sync garantido**, e widget test isolado NÃO pega (cada tela testada sozinha). Só pega navegando no device OU com teste cross-tela + store compartilhado. Memória nova `raro-pattern-single-source-of-truth-persisted-settings`.
- **Promover estado por callback nativo (não no await)** fechou o bug catalogado de dessincronização do botão REC — exigiu adicionar `onRecordingStarted` ao contrato (mesmo codegen do `includeReplayPreroll`, Simplicity First).
- **Coordenação do export combinado vive no `CameraManager`** (onde recording+replay coexistem), mantendo o `RecordingPipeline` device-validated intacto. O G1 já está finalizado quando `handleRecordingFinished` roda (é chamado DENTRO do completion do `finishWriting`) — encadeamento confirmado pela auditoria.
- **`raro_shared.BufferDuration` usa `.value`, não `.seconds`** (o enum local removido usava `.seconds`) — fonte de vários erros de compilação durante a migração; bom lembrete de conferir a API do enum canônico.
- **Feedback honesto > feedback bonito:** o anel "enchendo" usa timer client-side modelando o tempo real de enchimento (15/30s), não um número inventado nem progress bar falsa — decisão explícita do usuário pra não repetir o anti-padrão do concorrente (estado escondido) com outro anti-padrão (progresso mentiroso).

## Próximos passos

- **Gate §10 formal (ffprobe):** rebuild profile → gravar 1 clipe com pré-roll armado no iPhone 12 → `xcrun devicectl device copy from --device <udid> --domain-type appDataContainer --domain-identifier com.rarocamera --source Documents/vault/<id>.mp4 --destination .` → `ffprobe -v error -select_streams v:0 -show_entries stream=width,height,r_frame_rate <id>.mp4` provando dims+fps do REC (não do buffer) + inspecionar emenda (1º frame) + áudio sync na junção.
- **Re-validar persistência no device** (após rebuild): trocar 30s no pill → Settings → voltar = continua 30s; mudar em Settings = reflete no pill da câmera.
- **Aproveitar a próxima fatia (voz):** "Raro" aciona o MESMO save (camada por cima do botão).
- **Backlog Sprint 2:** volume button, RevenueCat sandbox, share, analytics. Android nativo do replay = Sprint 3.

## Referências

- **ADRs:** ADR-0003 Addendum 2026-06-07 (pré-roll-no-REC); ADR-0020 (pipeline unificado), ADR-0021 (4K60/gate §10) coerentes.
- **Memórias novas:** `raro-pattern-single-source-of-truth-persisted-settings` (fonte única persistida). Atualizada: `raro-preroll-rec-design-s2c` (correção do overlap snapshot-no-start).
- **Arquivos nativos:** `ReplayBuffer.swift` (snapshotChunks/pauseAppending/exportCombined), `CameraManager.swift` (coordenação START/STOP + onRecordingStarted), `CameraHostApiImpl.swift`, `RecordingPipeline.swift`.
- **Arquivos Dart:** `recording_controller.dart`, `recording_phase.dart`, `camera_flutter_api_provider.dart`, `camera_screen.dart`, `settings_controller.dart`, `camera_shell_state.dart`/`_provider.dart`, widgets `replay_arm_ring.dart` + `preroll_confirmation.dart` + `buffer_pill.dart`.
- **PRs:** nenhum (branch não mergeada).

---

## Atualização 2026-06-07 (mesma sessão) — rebuild, re-validação device e Gate §10 formal FECHADO

Após o fix de persistência ser commitado (`6d7bf35`, Dart-only), rebuild profile + reinstall no iPhone 12 (`✓ Built 47.1MB`, timestamp fresco). **Usuário re-validou no device:**
- **Persistência da janela FUNCIONANDO:** trocar 30s no pill → Settings → voltar = continua 30s; mudar em Settings reflete no pill. Os 2 bugs do `6d7bf35` confirmados corrigidos no device.
- **Pré-roll FUNCIONANDO:** anel enche, "últimos 15/30s incluídos" aparece, botão volta ao normal.

**Gate §10 formal (ffprobe) — PASSOU em 2 amostras puxadas do vault via `devicectl copy from`:**
| Amostra | dims reais | fps real | codec | duração | prova |
|---|---|---|---|---|---|
| 18:41 | 2160×3840 (4K retrato) | 59.94 (60) | HEVC + AAC | 35.79s | gravou ~5.8s → **30s pré-roll embutido** |
| 18:38 | 1080×1920 | 59.94 (60) | HEVC + AAC | 23.58s | janela 15s + ~8.6s gravados |

`isReplay:false` (é gravação, sink correto). **Frames todos presentes** (`nb_read_frames=2113` @ 59.9fps no de 4K, decode `exit 0`, zero frame dropado). Resolução/fps são os **reais do REC, não do buffer** — exatamente o que o gate §10/ADR-0021 exige provar. **A duração maior que a gravação é a prova viva do pré-roll.**

### Falso alarme registrado (anti-pattern de debug)

Eu inicialmente puxei `tmp/raro_<id>.mp4` e vi `moov atom not found` → conclui "bug, clipe corrompido". **ERRADO:** esse é o **clipe G1 cru intermediário** (fonte descartável que o `exportCombined` consome); naturalmente não é um `.mp4` finalizado standalone. O arquivo real é o **combinado no `vault/`**, que está perfeito. Lição: o artefato a validar no gate §10 do pré-roll é o `vault/<id>.mp4` (saída de `onRecordingFinished`), NUNCA o `tmp/raro_*` intermediário. Reforça `feedback_device_debug_use_real_logs_not_assumptions` (puxar o arquivo CERTO antes de concluir). `idevicesyslog` legado NÃO capturou os `os_log` do app (limitação conhecida) — a evidência veio do ffprobe nos arquivos, não do syslog.

### Débitos conhecidos do combinado (decisão do usuário: backlog, não bloqueiam)

Análise técnica do `.mp4` combinado revelou 2 imperfeições MENORES (riscos baixos já previstos no design memory `raro-preroll-rec-design-s2c` + ADR-0003):
1. **Áudio-priming AAC ~350ms no início:** os ~350ms iniciais do pré-roll ficam sem áudio (priming do 1º chunk). Vídeo+áudio ficam sincronizados do ~0.35s até o fim (vídeo e áudio terminam alinhados: 35.28s vs 35.35s → **sem drift progressivo**, é só um gap de start). Mitigação futura: `kCMSampleBufferAttachmentKey_TrimDurationAtStart` no 1º chunk ou descartar priming.
2. **DTS não-monotônico nas emendas dos chunks de 1s:** ffmpeg warning `non monotonically increasing dts` ao re-muxar (timestamps duplicados nas junções). NÃO é erro de decode (todos os frames lidos, playback OK no app). Cosmético; risco só se o arquivo for re-processado/compartilhado/editado por ferramenta estrita. Mitigação futura: forçar IDR por chunk (`AVVideoMaxKeyFrameIntervalKey`) + retiming na composition.

**Decisão do usuário:** fechar a fatia agora (gate §10 passou, funciona no device); atacar (1) e (2) só se virarem problema perceptível (ex: ao adicionar share/edição). Coerente com Simplicity First — evita scope creep sobre feature provada.

### Cosmético (backlog): nome do combinado no vault

O combinado é salvo no vault como `replay_<UUID>.mp4` em vez de `raro_<UUID>.mp4` — artefato do nome `raro_replay_<UUID>` que o `ReplayBuffer.export()` gera (`ReplayBuffer.swift:330`) combinado com o strip de prefixo `raro_` do `_idFromPath` (`camera_flutter_api_provider.dart`). `isReplay:false`, name "Vídeo HH:MM" e thumbnail estão corretos; só o filename diverge. 1 linha pra corrigir (sem efeito funcional). Backlog.

### Estado final da fatia

**Pré-roll embutido no REC = PRONTO e device-validated** (gate §10 formal anexado acima). 3 débitos backlog (áudio-priming, DTS emendas, nome cosmético) — nenhum bloqueia. Próxima fatia de produto = voz ("Raro" aciona o mesmo save).
