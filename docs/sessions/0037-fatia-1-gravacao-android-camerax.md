# 0037 — Fatia 1/4 pré-APK: gravação Android CameraX (provada no M54) + planejamento das 4 fatias

- **Data:** 2026-07-17
- **Duração:** ~1 dia (sessão longa: planejamento das 4 fatias + implementação/prova da Fatia 1 + auditoria)
- **Participantes:** Eduardo Rodrigues + Claude Code (Opus 4.8)
- **Branch:** `feat/pre-apk-4-fatias` → mergeada em `develop` (PR #5), branch deletada
- **Commits:** `b25c3e9`..`79ad76e` (18 commits), merge `8f94c74`

## Objetivo

Pré-APK do cliente: antes de gerar o APK, o dono pediu 3 frentes — i18n multi-idiomas, tap-to-focus Android, e voz "raro gravar/parar" em background no Android (com pesquisa das opções modernas). O planejamento decompôs em **4 fatias** (a gravação Android entrou como pré-requisito): Gravação → Foco → Voz → i18n. Esta sessão fechou o **planejamento das 4** + a **implementação e prova da Fatia 1 (gravação)**.

## Contexto inicial

PR #4 (full-bleed) já mergeado na abertura. Android tinha `startRecording`/`stopRecording` stub (throw "not implemented until Bloco 3.1") — REC dava "Falha ao gravar" no M54. Voz Android inexistente (só stub Pigeon); foco Android com backend pronto mas sem gesto.

## O que foi feito

**Planejamento das 4 fatias (brainstorming → specs):**
- Pesquisa de voz Android (subagent researcher, docs oficiais): foreground = `SpeechRecognizer` on-device; background = foreground service `microphone` + engine embutido (Vosk grátis pt-BR 31MB como ponte até Sensory; sherpa-onnx/openWakeWord descartados por falta de pt-BR). App fechado = sem caminho honesto no Android moderno.
- 4 specs escritas (`docs/superpowers/specs/2026-07-17-*.md`): gravação, foco, voz, i18n.
- **Validação em fonte primária (Context7)** após o dono cobrar: CameraX VideoCapture, tap-to-focus (`GestureDetector.onSingleTapUp` + `meteringPointFactory`), l10n.yaml. Corrigiu imprecisões da 1ª versão (eu havia escrito de memória — falha de processo admitida).
- **Auditoria de conflitos pré-plano** (validator + adr-guardian): pegou (a) colisão de número de ADR — voz reservou 0028, que já era da Sensory → corrigido p/ 0029; (b) divergência de stack: Blueprint fixa MediaCodec, spec propõe CameraX Recorder → decisão do dono: Recorder + ADR-0030 atualiza o Blueprint. Contratos Pigeon verificados campo-a-campo (fiéis).

**Fatia 1 — gravação Android (implementada, provada, mergeada):**
- ADR-0030 + Blueprint atualizado (gravação linear = CameraX Recorder; replay = MediaCodec, fatia futura).
- Dep nova `androidx.camera:camera-video:1.6.1`. `RecordingController` (MP4 temp `raro_<id>.mp4` + `withAudioEnabled`), `CameraManager` binda Preview+VideoCapture juntos (preserva `bindIfReady` da 0036), `CameraHostApiImpl` liga aos callbacks Pigeon (contrato inalterado). Thumbnail via `MediaMetadataRetriever` (era outro stub).
- **Descoberta ao ler o código:** vault/sidecar/thumbnail já vivem em Dart (`VaultService`), cross-platform — reduziu o escopo nativo (a spec original inflava o Kotlin).
- **Prova no M54 (gate §10):** ffprobe do clipe = vídeo h264 3840×2160 + áudio aac 48kHz estéreo (não é mudo); thumbnail JPEG real no vault; regressão de ciclo de vida (Config→volta) OK com 2 use cases no bind.

**Bugs de device corrigidos (encontrados durante a validação, kit adb):**
- Thumbnail preto: JPEG era gravado no `cacheDir` volátil (SO apaga) → agora no vault ao lado do vídeo, igual iOS (memória nova).
- Botões da preview sob a navbar: `_BottomActions` respeita `viewPadding.bottom` (edge-to-edge, mesmo padrão da 0036).
- 0.5×/1× "morto": NÃO era bug — o 0.5× é desabilitado por design em 4K60 ("indisponível em 4K60"); confirmado com o dono no device.

**Auditoria adversarial 3-lentes pós-implementação** (silent-failure-hunter + validator + code-reviewer):
- Boas práticas: **limpo** (zero achados ≥80). Drift: contrato/tipos/ADRs OK; 1 achado leve (arquivos bloco-2 revenuecat entraram de carona — mantidos por já commitados/linkados, documentado).
- Bugs silenciosos: **3 reais corrigidos** (validados em Context7 antes): (1) áudio degradado silencioso — `Finalize` não checava `audioStats.audioState` (mic tomado por ligação → clipe mudo como sucesso); (2) VideoCapture derrubava o Preview — `QualitySelector` sem `FallbackStrategy` (device de entrada API24+); (3) thumbnail parcial — `compress` boolean não checado + bitmap não reciclado. + MEDIUM: `SecurityException` (mic negado) → `PermissionDenied` em vez de genérico.
- Achado latente documentado (não corrigido): preroll UX lie — **não pode ocorrer no Android hoje** (ReplayBufferHostApi não registrado no MainActivity → `replayArmed` sempre false). Gatear por plataforma quando o replay Android existir.

**Fechamento:** PR #5 mergeado em develop; branches `feat/pre-apk-4-fatias`, `feat/camera-fullbleed`, `feat/camera-native-bridge` deletadas (local+remota; as 2 antigas com 0 commits à frente = já mescladas). Develop sincronizada, zero PR aberto.

## O que NÃO foi feito (e por quê)

- **Fatias 2, 3, 4** (foco, voz, i18n): só specs escritas; plans e código pendentes. Ordem confirmada pelo dono: Foco → Voz → i18n. Voz mantém plano Vosk como ponte.
- **Plans das Fatias 2-4:** só a Fatia 1 tem plan. Escrever sob demanda na abertura de cada uma.
- **ADR-0029 (voz/Vosk):** reservado, ainda não escrito (é da Fatia 3). Buraco 0028→0030 intencional e documentado nas specs.
- **Envio do APK ao cliente** (objetivo raiz): segue pendente — a gravação agora funciona, mas o dono priorizou foco+voz antes do APK.
- **Prova de áudio-degradado e fallback-de-qualidade no device:** os fixes compilam e a gravação normal foi reprovada verde no M54, mas os caminhos de erro (mic tomado no meio, device sem qualidade suportada) não foram forçados fisicamente. Baixo risco; validar em Android de entrada se surgir.
- **Validação perceptual da navbar-fix da preview no iPhone:** o fix é cross-platform (viewPadding), compila, mas olho humano no iOS ficou pra sessão iOS.

## Aprendizados / surpresas

- **Ler o código > confiar na spec/memória:** a spec inflava o Kotlin (vault/sidecar/thumbnail) que já eram Dart cross-platform; e o "0.5× morto" era design, não bug. Inspecionar o device (kit adb) e o código real evitou trabalho errado.
- **Thumbnail no cacheDir = bug silencioso de tempo** (memória nova `raro-pattern-android-thumbnail-vault-not-cachedir`): compila, funciona no teste imediato, quebra depois que o SO limpa o cache. Artefato persistido vai no vault, nunca em cache.
- **Auditoria adversarial pagou de novo:** 3 bugs silenciosos reais (áudio mudo fantasma o mais sério) que os testes verdes não pegavam — validados em fonte primária antes de corrigir, não de cabeça.
- **JDK do ambiente quebra o build:** Homebrew JDK 26 é novo demais p/ o Kotlin/AGP ("IllegalArgumentException: 26.0.1"); usar o JBR 21 do Android Studio via `JAVA_HOME`. Registrar p/ o build do APK.
- **Disciplina de processo cobrada e corrigida:** escrevi 3 das 4 specs de memória antes de validar em Context7 — o dono cobrou, validei e corrigi. A regra §4 do CLAUDE.md (memória de treino proibida) é para ser seguida antes, não depois.
- **Número de ADR sob corrida:** reservar número (0029) sem escrever o ADR é frágil; depende de disciplina no merge da fatia que o consome.

## Próximos passos

- **Fatia 2 (tap-to-focus Android):** escrever o plan + implementar. Backend nativo já existe (`focusAt`/`meteringPointFactory`); falta gesto nativo (`GestureDetector.onSingleTapUp`) + ring nativo + `onFocusChanged` honesto (ver spec). Branch nova a partir de develop.
- **Fatia 3 (voz):** SpeechRecognizer foreground + FGS microphone + Vosk (ADR-0029 a escrever). Spike-gate: `checkRecognitionSupport` pt-BR no M54 antes de codar.
- **Fatia 4 (i18n):** infra .arb + 3 idiomas + seletor ligado ao locale. Última (toca ~30 telas).
- **Build do APK:** usar JBR 21 do Android Studio como `JAVA_HOME`.
- Sessão iOS: validar full-bleed (ADR-0027) + navbar-fix da preview no iPhone 12.

## Referências

- Specs: `docs/superpowers/specs/2026-07-17-{gravacao-android-videocapture,tap-to-focus-android,voz-android-speechrecognizer-vosk,i18n-pt-en-es}-design.md`
- Plan: `docs/superpowers/plans/2026-07-17-gravacao-android-videocapture.md`
- ADRs: **ADR-0030** (gravação Android CameraX). ADR-0028 (Sensory) referenciado; ADR-0029 (voz/Vosk) reservado p/ Fatia 3.
- PR: **#5 (MERGEADO)** — gravação Android + fixes + auditoria
- Memória nova: `raro-pattern-android-thumbnail-vault-not-cachedir`
