# Bugfix — Resolução não muda + AVError -11847 ao abrir Settings

> **Status:** Diagnosticado (causa-raiz confirmada em device), **não corrigido**. Levantado durante a validação device da Task B0 (sessão 0019). Ambos são bugs **pré-existentes** (desde a S2.A / sessão 0016), NÃO causados pela migração do pipeline (B0). Documentados aqui com a causa-raiz mapeada para uma sessão de bugfix dedicada.

## Contexto

Durante o B-Gate da Task B0 (migração da gravação para `VideoDataOutput`+`AVAssetWriter`, ADR-0020), a validação no iPhone 12 físico revelou dois bugs ao exercitar o fluxo de Settings/resolução. A gravação em si (B0) foi **provada funcional** (4 `.mp4` HEVC+áudio reais no vault, thumbnail gerado). Os dois bugs abaixo são de áreas separadas e anteriores à B0 — confirmado porque os `.mov` antigos (gravados com o `MovieFileOutput` pré-B0) também eram todos 1080p, nunca 4K.

## Bug 1 — Trocar resolução nas Settings não reconfigura a sessão (4K sai 1080p)

**Sintoma:** selecionar 4K (ou qualquer resolução diferente) nas Settings não muda a resolução real gravada. ffprobe dos `.mp4` confirma: vídeo sai 1920×1080 mesmo com "4K" selecionado. O **fps muda** (60 pega); só a **resolução não**.

**Causa-raiz (confirmada):** em `apps/mobile/lib/features/camera/presentation/camera_screen.dart` (~linha 168), o `ref.listen(settingsControllerProvider, ...)` atualiza apenas a variável local `_format` (usada no `RecordingOptions` do próximo REC), mas **nunca chama `cameraControllerProvider.notifier.setFormat(resolution, fps)`** na sessão de câmera ativa. O método `setFormat` existe e funciona (`camera_controller.dart:111`), mas não há quem o invoque quando o usuário troca a resolução com a câmera rodando. Resultado: `device.activeFormat` nunca é reconfigurado; o `VideoDataOutput` continua entregando a resolução inicial.

**Fix proposto:** no `ref.listen(settingsControllerProvider)`, quando a sessão está `CameraStateReady` e a resolução/fps mudou, chamar `await ref.read(cameraControllerProvider.notifier).setFormat(fmt.resolution, fmt.fps)` (com try/catch + log, espelhando `_onSelectLens`). Atenção ao risco S2B-004 da auditoria: sob `.inputPriority`, trocar `activeFormat` muda as dimensões dos sample buffers entregues ao `VideoDataOutput` — se houver gravação/replay ativo, o `AVAssetWriter` precisa ser recriado/reancorado (não trocar a meio do clipe). Validar 4K real em device com ffprobe (`width=3840` ou rotacionado `2160×3840`).

**Gate de validação:** depende de `setFormat` + device. Cuidado: o iPhone 12 (A14) pode não suportar todos os formats 4K@60 — confirmar via `device.formats` quais combinações resolução×fps existem antes de assumir que 4K60 é selecionável.

## Bug 2 — "Falha ao gravar" / AVError -11847 ao abrir Settings (sessão interrompida)

**Sintoma:** ao clicar em algo nas Settings (sair da câmera para o overlay/tela de Settings) e depois operar a câmera, aparece "Falha ao gravar".

**Causa-raiz (confirmada via syslog do device):** a sequência nos logs é:
```
HangTracer: App com.rarocamera is no longer foreground ... HTFGUpdateAppBackgrounded
AVFCore: <<<< AVError >>>> (AVFoundationErrorDomain / -11847) status (-16121)
AVError-2025 ... result: "Operation Interrupted ... Stop other operations and try again."
session interruption ended — resuming
```
`AVFoundationErrorDomain -11847` = `AVErrorOperationInterrupted`. Quando o app sai de foreground (abrir Settings como overlay/rota que faz a câmera perder visibilidade), a `AVCaptureSession` é **interrompida** (`wasInterruptedNotification`). O `CameraManager` já tem observers de interrupção (`installObservers`) que resumem a sessão ao voltar — mas se uma operação de câmera (gravar / `setFormat`) é disparada **durante** a janela de interrupção, ela falha com -11847, e o `onError(.sessionFailed(...))` vira "Falha ao gravar" na UI.

**Fix proposto:** (a) **guard de estado** — não permitir start de gravação / `setFormat` enquanto a sessão está interrompida (rastrear um flag `isInterrupted` setado no `wasInterruptedNotification` e limpo no `interruptionEndedNotification`; rejeitar/enfileirar operações nesse estado com mensagem clara, não "Falha ao gravar" genérica). (b) Revisar se abrir Settings **deveria** interromper a câmera — talvez a P06 Settings deva manter a sessão viva, ou pausá-la deliberadamente e re-validar ao voltar. (c) Melhorar a mensagem de erro da UI: distinguir "câmera interrompida, tente novamente" de uma falha real de gravação.

**Gate de validação:** device — abrir Settings, voltar, gravar → sem "Falha ao gravar"; e gravar normalmente continua funcionando.

## Notas de escopo

- Nenhum dos dois é regressão da B0. A B0 (ADR-0020) entrega gravação `.mp4` funcional e foi commitada separadamente.
- Bug 1 é primariamente Dart (wiring) + cuidado nativo no `setFormat` sob output ativo.
- Bug 2 é primariamente nativo (lifecycle de interrupção) + UX da mensagem.
- Relacionado: risco S2B-004 (setFormat sob output ativo) já estava no `sprint-2-backend-logic-ios.md`; o pipeline unificado da B0 torna isso mais relevante porque agora o `VideoDataOutput` está sempre na sessão.

## Referências

- ADR-0020 (pipeline unificado): [../../decisions/0020-unified-capture-pipeline-videodataoutput.md](../../decisions/0020-unified-capture-pipeline-videodataoutput.md)
- Sessão 0019 (Task B0 + este diagnóstico): `docs/sessions/0019-*.md`
- Memória `raro-pattern-ios-platformview-camera-preview-black` (gating de sessão), `feedback_device_debug_use_real_logs_not_assumptions`
- Apple: `AVErrorOperationInterrupted` (-11847), `AVCaptureSession.wasInterruptedNotification`
