# Premium gating save/share — Implementation Plan

> **For agentic workers:** execute task-by-task. TDD no `PersistRecording`. Sem dep nova. Sem voz. Sem replay nativo.

**Goal:** Entitlement `premium` bloqueia guardar (vault + galeria do sistema) e compartilhar; free grava e vê no Preview.

**Architecture:** `RecordingFinished` monta `PendingClip` (temp). Preview pendente decide. `PersistRecording` lê `BillingGateway`; se premium, `vault.save` depois `GalleryHostApi`; se free, `NeedsPremium`. Replay Dart reusa o mesmo use case. Share via `SharePlus.instance.share(ShareParams)`.

**Tech Stack:** Flutter/Dart, Riverpod 3, Pigeon 26.3.2, MediaStore, PHPhotoLibrary, share_plus 13, FakeBillingGateway nos testes.

## Global Constraints

- Wake word `"Raro"`; trial 30 dias; planos R$ 9,90 / R$ 89,90
- Sem `READ_MEDIA_VIDEO`; sem plugin `gal`
- Strings nos 3 `.arb`; `FakeBillingGateway`; NUNCA `--no-verify`
- Scopes: `subscription` / `preview` / `gallery` / `bridge` / `shared` / `camera` / `replay` / `i18n`

## Tasks

1. Shared: `BridgeChannels.gallery` + `PermissionsContract` (plist add-only + WRITE_EXTERNAL_STORAGE)
2. Pigeon `gallery_api.dart` + script `pigeon` + codegen
3. Native Android MediaStore + iOS Photos + registro MainActivity/AppDelegate + pbxproj
4. `PersistRecording` TDD + `PendingClip` + exporters fake
5. Sinks: recording → pending (não vault); replay → persist (free descarta)
6. Preview dois modos + share_plus atrás do entitlement + paywall contextual
7. Router: câmera → preview `?from=camera`; paywall extra `PaywallArgs`
8. i18n 3 arbs + analyze + suíte
