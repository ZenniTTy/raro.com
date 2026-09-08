# Sessão 0046 — Modo Volume como 3º gatilho (4.5, ADR-0033)

- **Data:** 2026-09-05/06
- **Participantes:** Eduardo Rodrigues + Cursor
- **Branch:** `feat/volume-trigger`
- **PR:** [#16](https://github.com/ZenniTTy/raro.com/pull/16) **MERGEADA** em `develop` (`6a929a8`, 2026-09-06)
- **Commits:** `d92642d` (+ close desta sessão)

## Objetivo

Ligar o botão físico de volume como terceiro gatilho de captura (junto de REC e voz), com contrato Pigeon real — o card Volume deixava de ser “em breve”.

## Contexto inicial

`develop` @ `acabae3` (PR #15 legal mergeada). Settings já persistia `ControlMode.volume`, mas o Pigeon só tinha `volumePing`/`volumeReady`. Sem `VolumeHostApiImpl` em nenhuma plataforma. ADR-0011 já tinha escolhido `+`/`−` (não Bluetooth).

## O que foi feito

- **ADR-0033** Accepted: ciclo `isAvailable` / `startListening` / `stopListening` / `onVolumePressed`.
- Android: `dispatchKeyEvent` + consome `KEYCODE_VOLUME_*` só enquanto escuta (volume do sistema não muda).
- iOS 17.2+: `AVCaptureEventInteraction` (API oficial de captura). iOS 15–17.1: card some da UI. KVO + `setOutputVolume` rejeitado (API inexistente + guideline 2.5.9).
- 3º gatilho no mesmo `_onRecTap` da voz/REC: `+` inicia, `−` para. Escuta só com `ControlMode.volume` e câmera em foreground.
- Gates de máquina na fatia de código: `flutter analyze` limpo; suíte **433/433**; `flutter build ios --debug --no-codesign` → `Runner.app`.

## O que NÃO foi feito (e por quê)

- Handshake `queuedStop` / clipe que some da Galeria — descoberto no M54 **depois** do merge; fechado na [0047](0047-queued-stop-handshake.md).
- Copy HUD “DIGA RARO” no modo Volume — a câmera ainda mostra o hint de voz; backlog (armadilha que atrasou o gate 16 KB).
- M03 Bluetooth (4.4) — fora desta fatia.
- 16 KB (5.6b) — [0048](0048-android-16kb-vosk.md).

## Aprendizados / surpresas

- Prova de produto no M54 veio no uso real durante a 5.6b: o dono viajou em modo Volume; os botões **disparam** gravação. O que falhou na Galeria não era o VolumeHost — era STOP durante o freeze do Replay (0047).
- HUD de voz em modo Volume convida a diagnosticar o motor errado.

## Próximos passos

- Fechados nesta sequência: 0047 (handshake) e 0048 (16 KB).
- Loja: 5.1 / 5.2 / 5.4 / 5.6. Copy Volume no HUD = backlog.

## Referências

- ADR-0033 · PLANO-MESTRE 4.5 · ADR-0011
- [PR #16](https://github.com/ZenniTTy/raro.com/pull/16)
