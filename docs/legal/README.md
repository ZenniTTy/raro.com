# Legal — Raro Camera

> **Isto não é aconselhamento jurídico.** Textos factuais a partir do código em `develop` @ `6d8d163` (PR #14, 2026-09-04). O dono confirmou controlador, e-mail e URLs.

| Campo | Valor |
|---|---|
| Controlador | Vitor Autorino Lopes (Raro Camera), pessoa física |
| Contato | `rarocan1@gmail.com` |
| Hospedagem | Vercel, projeto `raro-com` (não criar outro) |
| Privacidade | https://rarocamera.com.br/privacidade |
| Termos | https://rarocamera.com.br/termos |
| EN / ES | `/en/privacy`, `/en/terms`, `/es/privacidad`, `/es/terminos` |

Site estático: `apps/legal/build.py` lê estes markdown e gera `apps/legal/dist`. O `vercel.json` da raiz do monorepo aponta o build para esse output (senão o próximo push em `develop` volta a servir o Flutter).

No app: P11/P12 embutem o markdown (`assets/legal/`) + hint com a URL canônica. Sem WebView e sem dep nova.

**Anti-drift:** `apps/mobile/test/contract/legal_documents_parity_test.dart` exige que cada par `docs/legal/*` ↔ `assets/legal/*` seja idêntico byte a byte. Ao editar textos, atualize os dois lados no mesmo commit.

## Fontes

| Arquivo | Uso |
|---|---|
| [politica-de-privacidade-pt-BR.md](politica-de-privacidade-pt-BR.md) | P12 + URL da loja |
| [termos-de-uso-pt-BR.md](termos-de-uso-pt-BR.md) | P11 + URL da loja + base da copy 2.8 |
| [privacy-policy-en.md](privacy-policy-en.md) / [terms-of-use-en.md](terms-of-use-en.md) | EN |
| [politica-de-privacidad-es.md](politica-de-privacidad-es.md) / [terminos-de-uso-es.md](terminos-de-uso-es.md) | ES |

Foro: domicílio do consumidor (CDC), sem inventar cidade. Sem idade mínima de loja inventada.

## T1 — o que o app realmente coleta (conferido 2026-09-04)

Inventário contra manifestos, `Info.plist`, bridges e Dart. Onde o levantamento prévio divergiu do código, a coluna **Nota** diz.

### Permissões

| Plataforma | Permissão | Para quê no código | Nota |
|---|---|---|---|
| Android | `CAMERA` | Preview + gravação CameraX | Confere |
| Android | `RECORD_AUDIO` | Áudio do clipe + Vosk (`AudioRecord`) | Confere |
| Android | `INTERNET` | Firebase + RevenueCat | Confere |
| Android | `POST_NOTIFICATIONS` | Notificação do FGS de microfone (Vosk) | Confere |
| Android | `FOREGROUND_SERVICE` + `_MICROPHONE` | `VoiceBackgroundService` | Confere |
| Android | `WRITE_EXTERNAL_STORAGE` | Só `maxSdkVersion=28` (export antigo) | **Não é storage irrestrito em API 29+.** Em API 29+ o export vai ao MediaStore (`Movies/Raro Camera/`) sem `READ_MEDIA_VIDEO` (ADR-0032) |
| iOS | `NSCameraUsageDescription` | Gravar vídeo | Confere |
| iOS | `NSMicrophoneUsageDescription` | Áudio do clipe + wake word | Confere |
| iOS | `NSSpeechRecognitionUsageDescription` | `SFSpeechRecognizer` on-device | Confere |
| iOS | `NSPhotoLibraryAddUsageDescription` | Salvar no rolo **add-only** | Confere. O app **não lê** o rolo (`PHPhotoLibrary` add-only; sem `NSPhotoLibraryUsageDescription`) |

Não há permissão de localização, contatos, calendário, tracking (`NSUserTrackingUsageDescription` / ATT) nem leitura da galeria.

### O que fica só no aparelho

- **Vídeo e áudio** do clipe: vault em sandbox (`documents/vault` / `app_flutter/vault`). Sem backend nosso (ADR-0004). Sem upload.
- **Sidecar JSON + thumbnail JPEG:** id, nome, duração, data, se é replay, resolução/fps/lente. Sem dados de conta.
- **Preferências** (`SharedPreferences`): onboarding, idioma, resolução/fps/buffer/modo, flag Xiaomi, first launch, cache de assinatura/trial. Sem e-mail, sem nome.
- **Voz:** Android = Vosk on-device (gramática restrita). iOS = `SFSpeechRecognizer` com `requiresOnDeviceRecognition = true`. O log nativo registra só o **comando** (`START`/`STOP` / `wake matched`), **nunca a transcrição bruta**.
- `device_info_plus` lê **apenas** `androidInfo.version.sdkInt` para decidir se pede storage no Android ≤ 28. Não envia marca/modelo para a gente.

O clipe **só sai** do sandbox se o usuário (premium) (1) exportar para Fotos/MediaStore ou (2) abrir a folha nativa de compartilhar (`share_plus`). O delete do Preview apaga o vault; **não** apaga cópia já exportada.

### O que sai do aparelho (operadores)

| Destino | O que vai | O que **não** vai |
|---|---|---|
| **Firebase Analytics** | Eventos de uso. No código de produção, os personalizados **disparados hoje** são só `camera_started` e `camera_error` (lente/resolução/fps ou código/mensagem de erro). O catálogo em `AnalyticsEvents` declara ~30 nomes (`app_open`, `paywall_shown`, `plan_selected`, `lens_switched`…) — **a maioria ainda não tem `logEvent`**. O SDK do Firebase também emite eventos automáticos (`first_open`, sessão, atualização). **Não há** `setUserId` nem disable de Advertising ID no repo | Vídeo, áudio, transcrição, e-mail |
| **Firebase Crashlytics** | Stack, modelo/OS, 3 handlers em `main.dart` (`FlutterError`, `PlatformDispatcher`, `Isolate`) | Sem user id custom |
| **RevenueCat** | `Purchases.configure(key)` **sem** `appUserID` → App User ID **anônimo**. Recibo da loja para o entitlement `premium`. Sem `logIn` | Sem e-mail, sem cadastro nosso |
| **App Store / Play** | Pagamento e identidade da **conta da loja** do usuário. Nós não vemos cartão (copy já existente: `checkoutProcessedBy`) | — |
| Destino do **Share** | Arquivo que o usuário escolheu na folha do sistema | Não é upload nosso |

**Divergência do levantamento prévio:** não são “~20 eventos já disparados”. São ~30 **nomes previstos** e **2** personalizados ligados. A política descreve o catálogo + o automático do Firebase, sem fingir telemetria que ainda não existe.

### O que o app não tem

- Login, cadastro, senha, perfil, e-mail coletado por nós.
- Backend próprio, sync entre aparelhos, nuvem de vídeo.
- Anúncios, marca d'água, IDFA/ATT pedido pelo app. **Porém:** o SDK do Firebase Analytics, por padrão, **pode** coletar identificador de publicidade no Android se não for desligado — **não achei** `google_analytics_adid_collection_enabled=false` nem `AD_ID` explícito no manifesto nosso (o plugin pode mesclar sozinho). A política admite isso; desligar o ADID é decisão à parte, não desta fatia.
- Privacy Manifest iOS (`PrivacyInfo.xcprivacy`): **arquivo ausente** no repo. Gate da App Store, fora do texto; anotar para o Bloco 5.

### Assinatura (copy 2.8 no paywall)

Fonte: `PlanPricing` + `SubscriptionConfig` + briefing.

- Mensal **R$ 9,90** / anual **R$ 89,90** (badge “MELHOR OFERTA”; equivalente R$ 7,49/mês).
- Trial **30 dias**.
- Renovação automática; cancelar nas configurações da **App Store ou da Google Play**; desinstalar o app não cancela.
- Free grava e vê o Preview; **guardar** (vault + rolo) e **compartilhar** exigem `premium` (PR #13).
- Sem login: restore de compras é o jeito de recuperar o entitlement no mesmo ecossistema.

## Fora desta fatia (não corrigir agora)

- Modo Volume (4.5), 16 KB (5.6b), keystore (5.2), voz/Vosk, replay, RevenueCat, dep nova.
- Achados do review da #14 (backlog):
  - `persist_recording.dart:66` — `filePath` nulo retornaria `PersistSucceeded` sem apagar o temp. Hoje inalcançável (`vault.save` sempre passa path).
  - `persist_recording_scope.dart:52` — 4 corpos idênticos que só mudam o tipo do `ref`.
