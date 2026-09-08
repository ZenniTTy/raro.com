# Sessão 0047 — Handshake STOP só com gravação nativa ativa (PR #17)

- **Data:** 2026-09-06/07
- **Participantes:** Eduardo Rodrigues + Cursor Grok
- **Branch:** `fix/android-queued-stop-handshake`
- **PR:** [#17](https://github.com/ZenniTTy/raro.com/pull/17) **MERGEADA** em `develop` (`11bb9b0`, 2026-09-07)
- **Commits:** `6abc75f` `d4b45e0` (+ close desta sessão)

## Objetivo

Corrigir o caminho Volume/`−` (e qualquer STOP) que iniciava e abortava a gravação no freeze do Replay: clipe sem dados válidos e nada na Galeria.

## Contexto inicial

Volume (0046) mergeado. No Galaxy M54 o dono via `+` iniciar e o vídeo **não** aparecer na P07. Log: CameraX `ERROR_NO_VALID_DATA` (error 8). A Galeria lista só `vault.listAll()`; STOP cria `PendingClip` (temp) e só o Salvar premium persiste — dois bugs empilhados: (1) start-then-stop no freeze; (2) expectativa de ver o clipe no vault sem persistir.

## O que foi feito

- Dart: STOP só em `RecordingActive` (`recording_phase.acceptsStart` / `acceptsStop`); `recording_controller` + `camera_screen` ignoram stop até o nativo estar ativo.
- Kotlin: `CameraManager.decideRecordingAfterFreeze` — se `queuedStop` chegou **antes** do Recorder, **ABORT** (não start-then-stop).
- Novo `RecordingFreezeDecision.kt` + teste Gradle.
- Testes: `recording_to_gallery_pipeline_test.dart` (PendingClip fora do vault até persist) + extras em persist / recording_controller / phase.

## O que NÃO foi feito (e por quê)

- Guardar no vault sem premium — regra do dono (2.3b); o teste só documenta o comportamento.
- Copy “DIGA RARO” no modo Volume — backlog explícito (0046/0048).
- Motor Vosk / 16 KB — fatia paralela (0048), branches separadas de propósito.

## Aprendizados / surpresas

- Volume `−` durante o freeze do Replay virava start+stop imediato: o `queuedStop` era honrado **depois** de abrir o Recorder. Abortar é o handshake honesto.
- P07 nunca mostrou PendingClip; “gravou e sumiu” misturava CameraX error 8 com vault-only listing.
- Snack de assinatura no Preview em debug: falta `--dart-define-from-file` RevenueCat. Release recusa Test Store key. Rebuild debug com `.env` (não commitar) destravou Salvar no device.

## Próximos passos

- 16 KB (0048) já mergeado nesta mesma noite.
- Não misturar esta correção com bump de Vosk.

## Referências

- PLANO-MESTRE 4.5 (Volume) · regra premium 2.3b
- [PR #17](https://github.com/ZenniTTy/raro.com/pull/17)
