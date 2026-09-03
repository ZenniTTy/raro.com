# Sessão 0043 — Fatia 5: replay buffer Android provado no M54

- **Data:** 2026-09-02
- **Duração:** ~3h
- **Participantes:** Eduardo Rodrigues + Cursor Grok
- **Branch:** `feat/fatia-5-replay-buffer-android`
- **Commits:** `536195f` `cd19348` `5c03b05` `9c24692` `f71919e` `4090469` + este close.

## Objetivo

Implementar o pré-roll Android (Bloco 3.2 / Fatia 5) com paridade de comportamento com o iOS, **provado no Galaxy M54**, sem tocar voz nem o contrato Pigeon.

## Contexto inicial

ADR-0031 + spec + spike-gate **já aprovados no M54** (2026-07-19) na mesma branch (rebaseada em `develop`). Rota D decidida: segmentos rotativos do CameraX `Recorder` + concat sem re-encode. Spike descartável ainda no código. Dart/Pigeon inalterados. Voz Android congelada.

## O que foi feito

- Removido o spike (`ReplaySpikeGate` / `runReplaySpike`).
- `ReplaySegmentRing` puro (capacidade iOS, chunks 5s) + 10 testes JVM.
- `ReplayConcat` (`MediaExtractor`+`MediaMuxer`, PTS ancorado no vídeo, áudio clampado, pula segmento ruim).
- `ReplayBuffer` ciclando no mesmo `VideoCapture`; freeze no REC; `saveStandalone` no host; `onPause` desarma.
- `CameraManager.includeReplayPreroll` honrado; fallback G1 se concat falha.
- `ReplayBufferHostApi` registrada no `MainActivity`.
- **Prova M54 (ffprobe + dono):** clipe ~21s = ~15s preroll + REC; 3840×2160 h264 ~30 fps; áudio contínuo.
- Device-fix 1: selo da galeria era literal `1080p · 60FPS`; passou a persistir formato da sessão e (depois) a **lente** — `isReplay` não é 0.5×.
- Device-fix 2: `VideoCapture`/`Preview` com `setTargetFrameRate` + `CONTROL_AE_TARGET_FPS_RANGE` no fps pedido.
- Device-fix 3: trocar 15s↔30s zera o anel Dart e reinicia o ring nativo.
- **Dono (2026-09-02 19:21):** “está tudo certo nos vídeos da galeria, buffer está funcionando corretamente.”
- 16 KB anotado no plano como **5.6b** (diálogo no Android 16; Vosk/Flutter; não mexer na voz agora).

## O que NÃO foi feito (e por quê)

- `saveReplay()` standalone sem botão de UI — produto não tem o gatilho; host existe.
- Merge em `develop` — **feito depois do close:** [PR #11](https://github.com/ZenniTTy/raro.com/pull/11) mergeado (`3a2a386`); branch de fatia apagada.
- Auditoria 3-lentes formal e update do Blueprint L55 / ADR-0030 consequências.
- Alinhamento ELF 16 KB (5.6b) — muda ADR-0029 se tocar Vosk.
- Overlay de FPS das opções de desenvolvedor (~60) — mede refresh da tela, não o fps da câmera.

## Aprendizados / surpresas

- O arquivo 4K30 já estava certo; a galeria mentia com mock. Preferir sidecar da **sessão** (HUD) ao tamanho do `video_player` — a ultra-wide no M54 pode cair em 1080 e o selo ficava errado.
- `0.5×` no badge antigo era `isReplay`, não a lente. Replay e ultra-wide não são a mesma coisa.
- `enable(seconds)` só aumentava capacidade; o anel Dart só mudava `duration`. Trocar janela tem que **resetar** os dois.
- `VideoCapture.withOutput` sem `setTargetFrameRate` deixa a sessão em 60 mesmo com Preview em 30–30.
- APK debug no Android 16 dispara diálogo de 16 KB (lista inclui `libvosk.so` + `libflutter.so`). Workaround: “Não mostrar de novo”.

## Próximos passos

- Push + PR #11 + delete da branch da fatia — **feitos**.
- Dono escolhe a próxima sessão: **Bloco 2 (monetização)**, **4.5 (volume)** ou **5.6b (16 KB)**.

## Referências

- ADR-0031, spec `docs/superpowers/specs/2026-07-18-replay-buffer-android-design.md`
- PLANO-MESTRE 3.2 (fechado) e 5.6b (16 KB)
- [0042](0042-apk-release-r8-provado-m54.md)
