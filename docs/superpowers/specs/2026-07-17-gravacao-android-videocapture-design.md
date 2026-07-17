# Spec — Gravação Android (CameraX VideoCapture) — Fatia 1/4 pré-APK

> Data: 2026-07-17 · Status: design aprovado pelo dono · Bloco 3.1 do PLANO-MESTRE
> Contexto: pacote pré-APK de 4 fatias (Gravação → Foco → Voz → i18n) decidido em 2026-07-17. A gravação vem primeiro porque é pré-requisito da voz ("raro gravar" sem gravação real não tem o que executar) e resolve o "Falha ao gravar" visto pelo dono no Galaxy M54.

## 1. Problema

`startRecording` no Android é stub proposital: [CameraHostApiImpl.kt:91](../../../apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraHostApiImpl.kt) lança "not implemented until Bloco 3.1". No device, REC → "Falha ao gravar".

## 2. Solução

> **Validado via Context7 (developer.android.com/media/camera/camerax/video-capture, 2026-07-17):** padrão oficial = `videoCapture.output.prepareRecording(context, outputOptions).withAudioEnabled().start(mainExecutor, Consumer<VideoRecordEvent>)`; `PendingRecording` → `Recording` (permite `stop()`/`pause()`/`resume()`); eventos `VideoRecordEvent.Start` / `.Status` (file size, duração) / `.Finalize` com `hasError()` + `outputResults.outputUri`. `asPersistentRecording()` mantém gravação através de rebind da câmera.

Implementar gravação real com **CameraX `VideoCapture<Recorder>`** (API oficial moderna, mesma família do `Preview` já em uso):

- `Recorder.Builder()` com `QualitySelector` derivado do `RecordingOptions`/formato corrente (fallback ordenado — CameraX negocia o suportado; sem fallback silencioso não-reportado: qualidade efetiva logada).
- `videoCapture.output.prepareRecording(context, FileOutputOptions)` + `.withAudioEnabled()` (exige `RECORD_AUDIO`, já no manifest) → MP4 com áudio. Sem áudio habilitado o clipe sai mudo — mesmo bug já visto no iOS.
  - **Decisão FileOutputOptions vs MediaStoreOutputOptions:** usar `FileOutputOptions` (vault sandbox do app), NÃO `MediaStoreOutputOptions` (galeria pública). Paridade com o iOS (vault privado, galeria in-app própria) e consistência do sidecar. A doc oficial suporta ambos; a escolha é de produto (privacidade/controle), não técnica.
- Eventos `VideoRecordEvent.Start/Finalize` → callbacks Pigeon `onRecordingStarted(sessionId)` / `onRecordingFinished(path, durationMs)` / `onRecordingFailed(code, message)`.
- **Descoberta ao ler o código (2026-07-17) — reduz o escopo nativo:** o vault, o sidecar JSON atômico e o thumbnail NÃO são trabalho do Kotlin. Vivem em Dart (`VaultService` + `recordingVaultSink` em `camera_flutter_api_provider.dart`), cross-platform: o nativo (iOS inclusive) só produz um `.mp4` cru num arquivo temporário e devolve o path via `onRecordingFinished(path, durationMs)`; o Dart copia pro vault, escreve o sidecar atômico e dispara o thumbnail. Portanto o Kotlin desta fatia:
  - Grava o MP4 num arquivo temp em `context.filesDir`/cacheDir com nome **`raro_<sessionId>.mp4`** — a convenção que `_idFromPath` espera (remove o prefixo `raro_`; ver `camera_flutter_api_provider.dart:117-122`). Nome errado = id errado no vault.
  - Devolve `onRecordingStarted(sessionId)` quando `VideoRecordEvent.Start` chega, `onRecordingFinished(tempPath, durationMs)` no `.Finalize` sem erro, `onRecordingFailed(code, msg)` no `.Finalize` com erro. As memórias de sidecar atômico e path-por-id já estão satisfeitas pelo Dart — não reimplementar no Kotlin.

**Bind:** `bindIfReady()` passa a bindar `Preview + VideoCapture` juntos no mesmo `bindToLifecycle`. Preservar o comportamento provado da sessão 0036 (surface antes do bind).

## 3. Escopo consciente (fora)

- **Pré-roll/replay buffer Android**: `RecordingOptions.includeReplayPreroll` é IGNORADO com `Log.w` explícito (não silencioso). Paridade de pré-roll é fatia futura (a mais complexa do app — MediaCodec/buffer circular, memória `raro-pattern-android-mediacodec-buffer-management`).
- **Thumbnail Android (`generateThumbnail`)**: HOJE também é stub (`formatUnsupported`, `CameraHostApiImpl.kt:107`). Sem ele o clipe grava mas fica sem thumbnail na galeria (o Dart faz `try/catch` e só loga — não quebra). Para paridade real, **incluir nesta fatia** o thumbnail Android via `MediaMetadataRetriever.getFrameAtTime(0)` → JPEG no path que o Dart espera. Escopo pequeno e no mesmo arquivo; sem ele a galeria Android fica com placeholder de cor (`thumbnailHue`).
- Foto (se houver stub separado) não muda nesta fatia.
- Nenhuma mudança de contrato Pigeon, zero `.swift`, zero Dart além do necessário (o Dart já consome os callbacks).

## 3b. ADR obrigatório antes do merge

`VideoCapture<Recorder>`/`Recorder`/`QualitySelector` vivem no artefato Maven **`androidx.camera:camera-video`**, que **NÃO está** no `apps/mobile/android/app/build.gradle.kts` (hoje só `camera-core/camera2/lifecycle/view:1.6.1`). Adicionar essa linha é dependência nova → **ADR-0030 obrigatório antes do merge**.

**Divergência de stack a reconciliar (decisão do dono 2026-07-17):** o Blueprint (linha 55) fixa encoding Android = `MediaCodec` + `MediaMuxer`. Esta fatia usa `CameraX VideoCapture<Recorder>` (o Recorder faz o mux internamente). Decisão: **CameraX Recorder para gravação linear + ADR-0030 que ATUALIZA o Blueprint**. O Blueprint passa a dizer: gravação linear = CameraX Recorder; pré-roll/replay buffer = `MediaCodec` + `MediaMuxer` (fatia futura, onde o controle de buffer circular é obrigatório — memória `raro-pattern-android-mediacodec-buffer-management`). Recorder é o caminho oficial 2026 para gravação simples, com áudio e negociação de formato prontos; MediaCodec continua sendo o caminho do replay. O ADR-0030 estende a estratégia MP4 do ADR-0018 (iOS/AVAssetWriter) ao Android e registra essa atualização do Blueprint. Números finais atribuídos na ordem real de merge; o par obrigatório é voz/Vosk (0029) e camera-video (0030).

## 4. Erros

- Sem permissão de mic → gravar sem áudio NÃO: falhar com `onRecordingFailed` claro (o app já pede mic no onboarding).
- `VideoRecordEvent.Finalize` com erro (`hasError()`) → mapear pra `CameraErrorCode` existente + mensagem; nunca swallow.
- Storage cheio / Recorder em estado inválido → `onRecordingFailed`.

## 5. Validação (DoD)

1. **Prova objetiva no M54** (gate §10 do CLAUDE.md adaptado): gravar 1 clipe, `adb pull` do vault, `ffprobe -show_entries stream=width,height,r_frame_rate,codec_name` para vídeo E áudio — anexar saída no PR.
2. Clipe aparece na galeria do app com thumbnail e reproduz.
3. Voltar de Configurações durante idle NÃO regride (bindIfReady com 2 use cases).
4. `analyze` + suíte Dart verdes; contract test do bridge inalterado.
5. Kit adb (screencap) confirmando UI de REC ativa durante a gravação.
