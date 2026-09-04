# 2026-09-04 — premium-gating-save-share

> Spec da fatia 2.3a + 2.3b + 4.1 do PLANO-MESTRE. Entitlement `premium` passa a bloquear guardar (vault + galeria do sistema) e compartilhar. Free grava e vê no Preview.

## Status

`Validated` no M54 (2026-09-04) — regra do free + persist premium (vault + Fotos) + share nativo

## Owner / Implementer

- **Spec owner:** Eduardo Rodrigues
- **Implementer:** Cursor
- **Validator:** testes Dart + analyze; prova em device (M54) a cargo do run local

## Reading order (pre-flight)

1. Blueprint §2.4 (entitlement `premium`) e §2.7 (`share_plus`)
2. ADR-0010, ADR-0013, **ADR-0032** (este slice)
3. PLANO-MESTRE 2.3a / 2.3b / 4.1
4. `BillingGateway` (PR #12) — fonte de verdade única
5. Memória `raro-pattern-android-13-media-permissions` — **só escrever**; não pedir `READ_MEDIA_VIDEO`

## Problem

`isSubscribed` só decide popup/banner. `recordingVaultSink` chama `vault.save()` no `RecordingFinished` sem consultar billing. Não existe exportação para a galeria do sistema. `share_plus` está no pubspec com zero imports; Preview é `_comingSoon`.

## Sizing

- [x] **Large** (novo bridge Pigeon + ADR + Preview em dois modos)

## Q-table

| # | Question | Answer |
|---|----------|--------|
| 1 | O que o free leva? | Grava e vê no Preview. Guardar (vault **e** Fotos do sistema) e compartilhar exigem `premium`. Recusou paywall de **Salvar** ou voltou no pendente → descarta o temp. |
| 2 | Acervo antigo? | Vídeo já no vault continua listável e reproduzível. Share desses clipes ainda exige premium. |
| 3 | Ponto de verdade do premium? | Só `BillingGateway.getCustomer().hasPremium`. Sem segundo caminho. |
| 4 | Exportação sistema? | Pigeon `GalleryHostApi.saveVideoToSystemGallery`. Android MediaStore (API 29+ sem permissão de leitura). iOS `PHPhotoLibrary` add-only. Sem plugin novo. |
| 5 | Replay? | Nativo intocado. `replay_vault_sink` Dart usa o mesmo `PersistRecording`. Free: descarta o temp do replay standalone (não há Preview nesse caminho). Premium: vault + galeria. |
| 6 | Salvar no P08 arquivado? | Não. P08 do protótipo é vídeo já salvo. CTA **Salvar** só no modo **pendente**. |
| 7 | Share API? | `SharePlus.instance.share(ShareParams(files: …))` — não a API deprecated. |
| 8 | Paywall recusar share vs salvar? | Recusar **Salvar** descarta o pendente. Recusar **Share** não descarta (nem acervo nem pendente). |
| 9 | Compra com sucesso no fluxo Salvar? | Persiste sozinho e volta ao Preview arquivado. |
| 10 | Segurança? | Temp só some após persistir com sucesso ou descarte explícito. Falha no vault não apaga o temp. Falha na galeria depois do vault: clipe fica no app; log; não descarta. |

## Observable goals

- [x] Free: stop → Preview toca o temp → Galeria do app não listou o clipe *(M54 2026-09-04: Galeria 13→13 após recusar Salvar)*
- [x] Free: Salvar abre P09 com copy de guardar; recusar apaga o temp
- [x] Premium: Salvar grava no vault **e** no app Fotos *(M54: Galeria 13→14; MediaStore `Movies/Raro Camera/<uuid>.mp4`)*
- [x] Free: Share abre P09; premium: folha nativa *(M54: sheet Android com o mesmo `.mp4`)*
- [x] Acervo antigo reproduz *(13 clipes anteriores seguiram listáveis)*
- [x] `FakeBillingGateway` nos testes; zero rede
- [x] `flutter analyze` limpo; suíte verde *(compile iOS desta fatia não rodou no device nesta sessão)*

## UI / protótipo

- **Pendente** (acabou de gravar): CTA principal **Salvar**; header Share gated; voltar = descartar → câmera
- **Arquivado** (Galeria): P08 fiel (Compartilhar / Delete-em-breve / Info-em-breve). Sem Salvar
- P09: `paywallSubtitleSave` / `paywallSubtitleShare` quando a origem não é o popup da câmera
- Copy trial 30 dias inalterada nos cards

## Out of scope

- Delete (4.2), P11/P12, Volume, 16 KB, keystore, replay nativo, voz/Vosk, marca d'água, dep nova

## Risks

| Risco | Mitigação |
|---|---|
| `READ_MEDIA_VIDEO` (Play Photo Policy) | Não pedir. MediaStore contribute no Q+ não exige leitura |
| Pigeon 5º contrato colide `PigeonError` | `GalleryPigeonError` + sub-package Kotlin `generated.gallery` |
| Replay standalone fura o gate | Mesmo `PersistRecording` no sink Dart |
| Confirmação de pré-roll some se navegar | Em produção (`onPreview` set) a confirmação da câmera é pulada; o Preview é o feedback |

## ADRs

- [x] ADR-0032 — exportação nativa para a galeria do sistema via Pigeon
- [x] ADR-0013 — 5º contrato Pigeon (consequência; não reescrever histórico)

## References

- Briefing §5.2 salvamento automático na galeria + share sheet
- Android: any app can contribute new media to MediaStore with no permissions required, starting in Q
- share_plus 13: `SharePlus.instance.share(ShareParams)`
- Protótipo P08: `docs/briefing/prototype/Prototipo-RARO.html` `screenPreview()`
