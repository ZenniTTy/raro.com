# Roadmap — Enviar APK Android para o cliente testar (preview)

> Status: roadmap de distribuição · Data: 2026-07-15
> Objetivo: gerar **1 arquivo `.apk` release (sideload)** do estado atual do app e entregar um **link** para o cliente baixar e instalar no Android dele, só para **visualizar como está**.
> Escopo: NÃO é publicação na Play Store. NÃO exige conta Play Developer nem keystore de produção. É um preview.

---

## Decisões travadas desta entrega (confirmadas com o dono 2026-07-15)

| Item | Escolha | Consequência |
|---|---|---|
| Canal de entrega | **APK direta via link** (Drive ou Firebase App Distribution) | Cliente baixa 1 arquivo e instala por sideload. Zero conta de loja. |
| Tipo de build | **Release não-assinada de produção (sideload)** | `flutter build apk --release`. Performance real, standalone, sem banner de debug. |
| Assinatura | **Debug key** (já é o default do `build.gradle.kts` release) | APK instala por sideload sem keystore. Keystore de produção fica para a fase Play Store (fora deste roadmap). |

---

## Pré-condição já verificada (2026-07-15)

- `apps/mobile/android/app/build.gradle.kts` → `buildTypes.release` usa `signingConfig = signingConfigs.getByName("debug")`. **Não precisa criar `key.properties` para o preview.**
- `apps/mobile/android/app/google-services.json` presente no device do dono (gitignored, chaves reais). Firebase Android compila.
- `applicationId = "com.rarocamera"`; version `1.0.0+1`.
- Bloco 0 já provou appbundle Android compilando (CLAUDE.md §2).
- **Permissão `INTERNET` adicionada ao `main/AndroidManifest.xml` (2026-07-15).** Antes só existia nos manifests de `debug/` e `profile/` (injetada pelo Flutter para hot-reload), o que deixaria o build **release** sem rede — Firebase Analytics/Crashlytics falhariam em silêncio no APK do cliente. Fix de 1 linha, permissão normal (sem prompt ao usuário), não abre ADR.

---

## O que o cliente vai e NÃO vai ver (alinhar expectativa antes de enviar)

Honestidade sobre o estado atual, para o cliente não achar que é bug:

**Funciona (iOS-first, mas partes rodam no Android):**
- Navegação, telas, tema, splash, onboarding.
- Câmera/preview e gravação dependem da paridade Android (Bloco 3) — **podem estar incompletas no Android**. Confirmar no smoke test (Fase 3) o que de fato roda.

**NÃO funciona ainda (e é esperado):**
- **Monetização/paywall**: RevenueCat ainda é mock (Bloco 2 pendente). Nenhuma compra real. O paywall aparece mas não cobra.
- **Wake word "Raro" em background**: STANDBY (aguarda Sensory). Foreground SFSpeech é iOS.
- **Paridade Android de câmera/replay/voz**: Bloco 3 pendente — o app foi desenvolvido iOS-first.

> ⚠️ Recomendação forte: enviar junto ao APK um bilhete de 3 linhas dizendo "é um preview visual iOS-first; câmera/voz/pagamento no Android ainda em desenvolvimento". Sem isso o cliente reporta como bug o que é backlog conhecido.

---

## Fase 1 — Sanidade da build (antes de gerar o APK)

Critério de sucesso: `flutter build apk --release` termina sem erro e produz o `.apk`.

1. Garantir deps atualizadas e sem drift:
   ```bash
   bun run --filter '@raro/mobile' pub:get
   ```
2. Análise limpa (o mesmo gate que barrou o push do Firebase antes):
   ```bash
   bun run --filter '@raro/mobile' analyze
   ```
   Se acusar `firebase_options.dart` ausente → o arquivo tem que existir no device (gitignored). Já está presente hoje; se sumir, regenerar via `flutterfire configure` (não commitar).
3. Testes não regridem:
   ```bash
   bun run --filter '@raro/mobile' test
   ```

Gate: as 3 verdes antes de seguir. Se `analyze`/`test` falharem, **parar** e corrigir — não gerar APK de código quebrado.

---

## Fase 2 — Gerar o APK release

Critério de sucesso: existe um `app-release.apk` instalável.

1. Build:
   ```bash
   cd apps/mobile && flutter build apk --release
   ```
   Saída esperada: `build/app/outputs/flutter-apk/app-release.apk`.
   > Observação: é um APK "gordo" (universal, todas as ABIs). Para preview tudo bem. Se o arquivo ficar grande demais para o canal, usar `--split-per-abi` e enviar a variante `arm64-v8a` (cobre a maioria dos aparelhos modernos).
2. Renomear com versão + data para o cliente saber o que está testando:
   ```bash
   cp build/app/outputs/flutter-apk/app-release.apk \
      ~/Desktop/raro-preview-v1.0.0-2026-07-15.apk
   ```
3. Anotar o SHA para conferência de integridade (opcional, mas profissional):
   ```bash
   shasum -a 256 ~/Desktop/raro-preview-v1.0.0-2026-07-15.apk
   ```

---

## Fase 3 — Smoke test no SEU Android antes de enviar (obrigatório)

> Nunca envie um APK que você não instalou. Instalar você mesmo pega o "não abre" antes do cliente.

Critério de sucesso: app instala num Android físico, abre, e você navega pelas telas sem crash imediato.

1. Com um Android conectado por USB (depuração USB ligada):
   ```bash
   adb install -r ~/Desktop/raro-preview-v1.0.0-2026-07-15.apk
   ```
2. Abrir o app, percorrer: splash → onboarding → câmera → galeria → paywall.
3. Anotar honestamente o que roda e o que não roda no Android (vira o bilhete da expectativa). Especialmente: **a câmera abre no Android?** (paridade Bloco 3 pode não estar pronta).

Se crashar no boot: parar. Pegar o log com `adb logcat | grep -i "rarocamera\|flutter\|AndroidRuntime"` e tratar antes de enviar.

---

## Fase 4 — Publicar o link e entregar

Duas opções de canal (você escolheu "APK direta via link"). Ambas servem; a A é a mais simples.

### Opção A — Google Drive (mais simples, 5 min)
1. Subir o `.apk` renomeado no Drive.
2. Compartilhar com link "qualquer pessoa com o link pode ver".
3. Mandar o link + o bilhete de instalação (abaixo).

### Opção B — Firebase App Distribution (mais profissional, rastreável)
> Já temos Firebase no projeto. Exige o CLI do Firebase e o app registrado no App Distribution.
1. Instalar CLI: `curl -sL https://firebase.tools | bash` (ou via npm).
2. `firebase login`.
3. Distribuir:
   ```bash
   firebase appdistribution:distribute \
     ~/Desktop/raro-preview-v1.0.0-2026-07-15.apk \
     --app <FIREBASE_ANDROID_APP_ID> \
     --testers "email-do-cliente@exemplo.com" \
     --release-notes "Preview v1.0.0 — iOS-first; camera/voz/pagamento Android em desenvolvimento"
   ```
   `<FIREBASE_ANDROID_APP_ID>` está no `google-services.json` (`mobilesdk_app_id`) ou no console Firebase → Configurações do projeto → app Android.
4. O cliente recebe email, instala o app "App Tester" e baixa por lá.

> Trade-off: A é instantânea e sem convite; B dá controle de quem baixou e histórico de versões, mas exige o setup do App Distribution + o cliente instalar o app tester.

### Bilhete de instalação para mandar ao cliente (copiar/colar)
```
Olá! Segue um preview do app RARO para você ver como está.

Como instalar no Android:
1. Baixe o arquivo .apk pelo link.
2. Ao abrir, o Android vai pedir para permitir "instalar apps de fontes desconhecidas" — permita para o app de onde você baixou (navegador/Drive).
3. Instale e abra.

⚠️ É uma versão de PREVIEW (ainda em desenvolvimento):
- Foi construída primeiro para iPhone; no Android a câmera, a voz e o pagamento ainda estão em desenvolvimento.
- O pagamento NÃO cobra nada (é simulado nesta versão).
Qualquer coisa estranha, me avise — a maioria já é conhecida e está no cronograma.
```

---

## Fora de escopo deste roadmap (deixar explícito)

- **Keystore de produção + assinatura release real** → só necessário para publicar na Play Store. Vira roadmap próprio (relaciona [08-RELEASE.md](../../08-RELEASE.md)).
- **Google Play (teste interno ou produção)** → exige conta Play Developer US$25, AAB assinado e revisão. Não é preview.
- **Paridade Android de câmera/replay/voz** → Bloco 3 do [PLANO-MESTRE](PLANO-MESTRE-finalizacao-entrega-cliente.md).
- **Monetização real** → Bloco 2 (RevenueCat), ver [bloco-2-revenuecat-setup-guia.md](bloco-2-revenuecat-setup-guia.md).

---

## Checklist de "pronto para enviar ao cliente"

- [ ] `analyze` + `test` verdes (Fase 1)
- [ ] `app-release.apk` gerado (Fase 2)
- [ ] APK renomeado com versão + data
- [ ] Instalado e aberto no SEU Android sem crash (Fase 3)
- [ ] Anotado o que roda / não roda no Android
- [ ] Link publicado (Drive ou App Distribution)
- [ ] Bilhete de expectativa + instalação enviado junto
