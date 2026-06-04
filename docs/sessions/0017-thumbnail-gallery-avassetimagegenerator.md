# 0017 — Thumbnail real na galeria (AVAssetImageGenerator, ADR-0019)

- **Data:** 2026-06-04
- **Duração:** ~3h
- **Participantes:** Eduardo Rodrigues + Claude Code (Opus 4.8)
- **Branch:** `feat/camera-native-bridge`
- **Commits:** `f2f2712` (ADR-0019), `40f4fd3` (feat gallery thumbnail)

## Objetivo

Substituir o gradiente colorido das capas da galeria (P07) por um **frame real** (1ª imagem) de cada vídeo do vault. Pedido do usuário: "os vídeos na galeria ainda estão sem a capa do preview... dá para colocar preview do vídeo real?".

## Contexto inicial

Pós-sessão 0016 (S2.A recording + vault), a galeria renderizava cada célula como gradiente HSL derivado de `thumbnailHue` — decisão deliberada da Sprint 1 (Blueprint §5; sessão 0013). Mesmo vídeos reais gravados na S2.A apareciam como retângulo colorido, porque ninguém extraía frame. Câmera/REC/foco/lens/onboarding já validados no iPhone 12 (rodada anterior desta mesma branch).

## O que foi feito

Decisões de produto confirmadas com o usuário antes de codar (Think-Before-Coding):
- **Frame estático** (1ª imagem), não vídeo tocando no grid (evita N players → OOM, memória `raro-pattern-flutter-video-player-disposal`).
- **Remover os 6 mocks** → galeria vault-only.
- **Gerar no save** (não sob demanda), via **nativo próprio** (não dep nova).

Pesquisa (researcher, Context7 indisponível → pub.dev + source): `video_thumbnail` abandonada (Dart 2); `fc_native_video_thumbnail` viável mas adicionaria dep → ADR de dependência. Usuário escolheu **nativo próprio via Pigeon** (mesmo `AVAssetImageGenerator` por baixo, sem dep, código que já dominamos).

Gate ADR (adr-guardian): tocar contrato Pigeon do bridge de câmera exige ADR (mesmo gatilho do ADR-0018). **ADR-0019 criado e commitado antes do código** (`f2f2712`).

Implementação (`40f4fd3`, 22 arquivos):
- **Pigeon:** `@async String generateThumbnail(String videoPath)` na `CameraHostApi` + codegen (Dart/Swift/Kotlin).
- **iOS:** `ThumbnailGenerator.swift` (`AVAssetImageGenerator`, `appliesPreferredTrackTransform=true`, tolerância `.zero`, frame em `CMTime.zero` → JPEG q0.8 → `<id>.jpg` ao lado do `.mov`). Ligado no `CameraHostApiImpl`. Erro via `PigeonError(code: "\(code)")` (nome simbólico, não rawValue).
- **Android:** stub no-op (`formatUnsupported`, até Sprint 3).
- **Dart:** `thumbnailPath` (nullable) em `RecordingMetadata`/`VideoEntity`/sidecar JSON; `VaultService.attachThumbnail` + `delete` remove `.jpg`; `recordingVaultSink` gera thumbnail após `save`; `videoListProvider` vault-only (mocks removidos); `VideoThumbnail` mostra `Image.file` com fallback `_GradientFallback` (gradiente preservado byte-a-byte).
- **pbxproj:** `ThumbnailGenerator.swift` (Runner) + `ThumbnailGeneratorTests.swift` (RunnerTests) registrados (pego pelo `ios_pbxproj_parity_test`).
- **TDD:** 3 XCTests nativos (incl. gerar JPEG de `.mov` real via AVAssetWriter de fixture) + testes Dart de vault/repository/metadata/vault_sink.

**Gates:** analyze 0 · Flutter 240/240 · shared 42/42 · XCTest nativo 15/15 (3 do ThumbnailGenerator verdes em iPhone 17 Pro simulator) · iOS `✓ Built Runner.app 46.9MB` (timestamp fresco). **Validado no iPhone 12 físico** pelo usuário: gravou vídeo novo → galeria mostra frame real. 2 commits Conventional, 0 `--no-verify`.

## O que NÃO foi feito (e por quê)

- **Android thumbnail real** — stub no-op até Sprint 3 (paridade Android é Sprint 3 por roadmap). Android cai no gradiente.
- **Migração retroativa** — vídeos gravados antes desta build não têm `.jpg` → caem no gradiente. Sem migração (vault novo, baixo impacto).
- **Refino do polling no `recording_vault_sink_test`** — o teteardown deleta o tempdir enquanto o `attachThumbnail` async tardio reescreve (warning `PathNotFoundException` benigno no log do teste, não afeta asserts nem produção). Funciona, mas o helper deixa trabalho async pendente. Backlog menor.
- **`camera_contract.md`** — CLAUDE.md §5 pede doc de contrato por bridge, que nunca existiu no repo (gap pré-existente apontado pelo adr-guardian). Não criado nesta sessão; o schema Pigeon segue como fonte canônica de fato. Vale alinhar com o usuário se ainda é exigido.

## Aprendizados / surpresas

- **2 bugs REAIS de produção pegos pelo teste de integração de provider** (não pelos 240 testes de widget com repo mockado):
  1. **`ref` após dispose em listener async** — `ref.read`/`invalidate` depois de `await` num listener de stream lança "Cannot use Ref after disposed" se o provider foi disposto no gap (usuário fecha câmera enquanto thumbnail gera). Fix: ler deps síncronas no `build`, `ref.mounted` antes de tocar ref pós-await. Memória `raro-pattern-riverpod-ref-after-dispose-async-listener`. **Passava isolado, falhava em sequência — NÃO é flaky.**
  2. **Race read-during-write no sidecar do vault** — `writeAsString` trunca antes de reescrever; galeria lendo via `listAll` nesse instante → `FormatException: Unexpected end of input`. Fix: escrita atômica tmp+rename. Memória `raro-pattern-vault-sidecar-atomic-write-race`.
- O `ios_pbxproj_parity_test` (contract test) protegeu de esquecer de registrar o `.swift` novo no Xcode project — gate funcionou.
- `Override` não é resolvível como tipo em `flutter_riverpod` neste setup; tentar tipar `List<Override>` num helper de teste foi beco sem saída → resolvido com variável de instância `seededVideos` no teste do router (sem precisar do tipo).
- Disciplina de device validation honrada: declarei pronto só APÓS confirmação do usuário no iPhone 12 (contraste com sessões anteriores onde declarei prematuramente).

## Próximos passos

- **S2.B — Replay buffer** (próximo entregável do Sprint 2): `AVCaptureVideoDataOutput` + `AVAssetWriter` coexistindo com `MovieFileOutput` na sessão `.inputPriority` (flag de risco do ADR-0018).
- Eventual: thumbnail Android (Sprint 3), validação G1 (<300ms tap→started) no device, refino do polling do vault_sink test.

## Referências

- ADR-0019: [../decisions/0019-thumbnail-avassetimagegenerator.md](../decisions/0019-thumbnail-avassetimagegenerator.md)
- Estende ADR-0015 (bridge câmera) + ADR-0018 (artefato `.mov`)
- Memórias criadas: `raro-pattern-riverpod-ref-after-dispose-async-listener`, `raro-pattern-vault-sidecar-atomic-write-race`
- Sessão anterior: [0016-sprint2-task-a-recording-vault.md](0016-sprint2-task-a-recording-vault.md)
