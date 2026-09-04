# 0032 — Exportação para a galeria do sistema via Pigeon nativo

- **Data:** 2026-09-04
- **Status:** Accepted
- **Decisores:** Eduardo Rodrigues
- **Tags:** architecture, native, media
- **Spec:** docs/superpowers/specs/2026-09-04-premium-gating-save-share-design.md

## Contexto

O briefing (§5.2) pede salvamento automático na galeria do sistema. O PLANO-MESTRE 2.3a confirma que **não existe** `MediaStore` nem `PHPhotoLibrary` no repo — o vault privado (`documents/vault`) é o que a tela Galeria lista.

O dono definiu (2026-09-04): guardar inclui o vault **e** o rolo do sistema, atrás do entitlement `premium`. Dep nova exige ADR. `gal` / `photo_manager` / `image_gallery_saver` seriam ADR de pacote **e** escondem a permissão errada (`READ_MEDIA_VIDEO`) que a Play Photo and Video Permissions Policy (Oct 2024) restringe.

ADR-0013 fixa Pigeon para Method Channels, com `errorClassName` único por contrato (colisão `PigeonError` no módulo Swift).

Fonte Android (developer.android.com, 2026-09-04): a partir de Q, qualquer app pode **contribuir** mídia no MediaStore **sem permissão**. `READ_MEDIA_VIDEO` é leitura da biblioteca alheia — não é o que esta fatia faz.

## Decisão

**Decision (one sentence):** Exportar vídeo para a galeria do sistema por um 5º contrato Pigeon (`gallery_api.dart`), implementação nativa própria, sem plugin Flutter novo.

**Detail:**

- Schema: `apps/mobile/pigeons/gallery_api.dart` — `GalleryHostApi.saveVideoToSystemGallery(String videoPath)` `@async`.
- Swift: `GalleryPigeonError`. Kotlin package `com.rarocamera.raro_mobile.generated.gallery`.
- Android API 29+: `MediaStore.Video.Media` + `IS_PENDING` + `RELATIVE_PATH=Movies/Raro Camera`. Sem `READ_MEDIA_VIDEO` / `READ_EXTERNAL_STORAGE`.
- Android API 24–28: `WRITE_EXTERNAL_STORAGE` com `maxSdkVersion=28` + escrita em `DIRECTORY_MOVIES` + scan.
- iOS: `PHPhotoLibrary.requestAuthorization(for: .addOnly)` + `creationRequestForAssetFromVideo(atFileURL:)` + `NSPhotoLibraryAddUsageDescription`.
- Dart chama o host **depois** de `vault.save()` ter copiado o arquivo. Falha na galeria não reverte o vault.
- `share_plus` (já no pubspec, ADR-0001) cobre compartilhar, não substitui esta exportação.

| What | Choice | Version |
|---|---|---|
| Bridge | Pigeon HostApi `gallery` | ^26.3.2 (já fixado) |
| Android write | MediaStore contribute | API 29+ zero extra permission |
| iOS write | Photos add-only | iOS 15+ |

## Consequences

### Positive

- Vídeo premium aparece no app Fotos, como o briefing pede.
- Sem dep nova, sem `READ_MEDIA_VIDEO`, sem declaração extra de Photo Picker Policy.
- Mesmo padrão Pigeon dos outros 4 bridges (codegen, error class único).

### Negative

- 5º `.g.swift` / `.g.kt` no tree; pbxproj e `MainActivity`/`AppDelegate` ganham registro.
- API 24–28 ainda precisa de `WRITE_EXTERNAL_STORAGE` runtime (não é o device de prova).

### Neutral / open

- Álbum visível como pasta "Raro Camera" no Movies. Não há UI para escolher álbum.
- Blueprint §2.2 lista 4 channels — esta ADR adiciona o 5º.

## Alternatives considered

### Alternative: plugin `gal` / `photo_manager`

**Why rejected:** dep nova = ADR de pacote; típico pedir leitura da biblioteca; o projeto já recusou plugins de câmera genéricos pelo mesmo motivo (controle nativo).

**What we lose:** menos código Kotlin/Swift nosso.

### Alternative: só vault, sem Fotos do sistema

**Why rejected:** briefing §5.2 e regra do dono (2026-09-04) exigem o rolo. O gate de prova no M54 é "abrir o app de galeria do celular".

**What we lose:** zero permissão iOS add-only.

### Alternative: método extra em `CameraHostApi`

**Why rejected:** misturaria captura com Photos/MediaStore. Thumbnail já estica a câmera; galeria do sistema é outro dono.

## Implementation notes

- Files: `pigeons/gallery_api.dart`, `GalleryHostApiImpl.{kt,swift}`, `PermissionsContract`, `AndroidManifest.xml`, `Info.plist`, `BridgeChannels.gallery`.
- Atualizar Blueprint §2.2 (5º channel) nesta mesma fatia.
- Não editar o corpo histórico do ADR-0013; o 5º contrato vive aqui.

## Validation

- Premium no M54: clipe no app Fotos após Salvar.
- `info_plist_parity` e `android_identity_parity` passam com as chaves novas.
- iOS `flutter build ios --simulator` (ou `iphoneos --no-codesign`) inclui o HostApi.

## References

- Briefing: `docs/briefing/original-briefing.md` §5.2
- Blueprint: `docs/Blueprint.md` §2.2 / §2.4 / §2.7
- ADR-0013 (Pigeon + errorClassName)
- https://developer.android.com/training/data-storage/shared/media
- https://developer.apple.com/documentation/photokit/phphotolibrary/requestauthorization(for:handler:)

## Supersedes / Superseded by

- Supersedes: —
- Extends: ADR-0013 (conjunto de contratos Pigeon, 4 → 5)
