# Prova do crux de background da voz — iPhone 12 (sessão 0024, 2026-06-11)

## Pergunta que o experimento respondeu

O iOS deixa o app RARO continuar recebendo áudio do microfone com a **tela bloqueada / app em background**, usando um mic próprio (`AVAudioEngine`/`AudioSessionCoordinator`) desacoplado da câmera?

Essa é a pré-condição de TODO o background de voz (plano `2026-06-09-voice-wakeword-livekit-onnx`). Sem ela, modelo + detector ONNX seriam esforço desperdiçado.

## Contexto: por que o teste anterior (SFSpeech) falhou

No teste com SFSpeech (mesma sessão), ao bloquear a tela o iOS marcou o app `BackgroundTaskSuspended ... being interrupted because the app is backgrounded`, com 143 interrupções de áudio acopladas à `cameracaptured`. **Causa (validada em fonte primária Apple):** a `AVCaptureSession` compartilha a `AVAudioSession` do app (desde iOS 7) e **a câmera não roda em background** (política de privacidade) → quando a câmera é interrompida no background, o áudio acoplado morre junto e o app é suspenso. Além disso, **SFSpeech é foreground-only por restrição fundamental do iOS** (erro 1700 em background). Memória `raro-pattern-ios-wake-word-no-native-api`.

## O experimento (BackgroundAudioProbe)

`AppDelegate.swift` (sessão 0024, experimental, removível): liga o `AudioSessionCoordinator` (mic-only, `.playAndRecord` + `.mixWithOthers`, `UIBackgroundModes:audio` já no Info.plist) e loga um heartbeat a cada 50 frames + transições de estado do app. SFSpeech foreground gated off (`_voiceEngineAvailable=false`) durante o teste para evitar dois engines de áudio brigando. **Sem modelo, sem detector — só conta frames.**

## Resultado: CRUX PASSOU (inequívoco)

Timeline do log (`pymobiledevice3 syslog`), PID 21855:
- 21:04:21.095 `bg-probe started: ok`
- 21:04:33.350 `app -> BACKGROUND` (tela bloqueada)
- 21:05:06.669 `app -> FOREGROUND` (desbloqueada, ~33s depois)

**Durante a janela de tela bloqueada, o heartbeat continuou firme a cada ~5s:**

| frames | timestamp | estado |
|---|---|---|
| 150 | 21:04:35 | BACKGROUND |
| 200 | 21:04:40 | BACKGROUND |
| 250 | 21:04:45 | BACKGROUND |
| 300 | 21:04:50 | BACKGROUND |
| 350 | 21:04:55 | BACKGROUND |
| 400 | 21:05:00 | BACKGROUND |
| 450 | 21:05:05 | BACKGROUND |

Contador 50→600 sem nenhum buraco, cadência regular (~10 frames/s = chunks ~100ms @16kHz mono). **Zero `BackgroundTaskSuspended`, zero interrupção, zero restart.** O mic-only `AudioSessionCoordinator` sobrevive ao background perfeitamente.

## Conclusão e implicação

- **Background de voz É viável no iPhone 12** com a arquitetura mic-próprio (Coordinator) + `UIBackgroundModes:audio`. A fundação do plano `2026-06-09` está provada no device.
- **O que falta para background funcional:** (1) detector ONNX (`WakeWordDetector`, plano Task 3) + (2) **modelo "Raro" treinado** (`raro_gravar.onnx`/`raro_parar.onnx`, plano Task 1) — este é o gate restante. Caminho de treino local: memória `raro-pattern-wakeword-train-cpu-piper-no-colab`.
- **Não testado ainda (próximo spike):** coexistência mic-próprio + câmera ativa em foreground (a câmera também quer o mic; plano Task 6). No experimento o SFSpeech estava off e a câmera não foi exercitada junto com o Coordinator. O background em si (sem câmera) está provado.

## Estado do código pós-experimento

- `AppDelegate.swift`: `BackgroundAudioProbe` experimental + `import os.log` (removível).
- `voice_controller.dart:12`: `_voiceEngineAvailable=false` (SFSpeech foreground gated off para o experimento).
- **AÇÃO pendente:** restaurar `_voiceEngineAvailable=true` + remover/substituir a sonda ao integrar o detector real, OU reverter para o estado da commit `a43421a` (foreground SFSpeech funcionando) se pausar aqui.
