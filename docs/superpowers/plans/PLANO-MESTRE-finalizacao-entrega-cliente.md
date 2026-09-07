# Plano-Mestre — Finalização e Entrega ao Cliente (RARO v1.0)

> **Criado:** 2026-06-22 a partir de auditoria de CÓDIGO REAL. **Reauditado em 2026-09-02** (sessão 0039) com 2 agentes paralelos + verificação manual — cada item abaixo foi provado contra o código, o binário ou o git, nunca contra a documentação.
>
> **Alvo de entrega (decisão do dono, 2026-06-22):** iOS + Android **paridade total**, depois publicação nas duas lojas.
>
> **Método desta reauditoria (anti-falso-positivo):** nenhum `[x]` foi mantido por estar escrito; foi reconfirmado por evidência citável (`arquivo:linha`, saída de `apksigner`, `flutter test`, `git log`). Onde a evidência contradisse o doc, **a evidência venceu** e o item voltou para `[ ]`.

---

## Estado real auditado (2026-09-02)

### ✅ Pronto e verificado nesta auditoria
- **Gravação MP4 + áudio**: iOS (`RecordingPipeline.swift`) e Android (CameraX `Recorder`, `RecordingController.kt:36-60`). Provado no M54 via ffprobe (sessão 0037).
- **Tap-to-focus**: paridade real (`CameraManager.kt:193-218` + `FocusRingView.kt`).
- **Voz "raro gravar"/"raro parar"**: **Android funciona em FOREGROUND E BACKGROUND** (Vosk motor único + FGS `microphone`; `VoskWakeEngine.kt:139`, modelo `vosk-model-small-pt-0.3` confirmado dentro do APK) — **confirmado pelo dono em 2026-09-02 como funcionando no device. NÃO MEXER.** iOS segue foreground-only (SFSpeech), com background em standby Sensory.
- **i18n pt/en/es**: `app_pt/en/es.arb` com **117 chaves traduzíveis em cada** (contagem verificada), locale persistido, e teste-guarda `forbidden_ui_literals_test.dart` que reprova literal fora do `.arb`.
- **Firebase + Crashlytics + Analytics**: provado no device na 0035 (crash no painel + dSYM).
- **R8/JNA**: `proguard-rules.pro` mantém JNA + Vosk; APK release contém `libvosk.so` + modelo pt (verificado com `unzip -l`).
- **`flutter analyze`**: limpo, zero issues.

### 🔴 Drift descoberto NESTA auditoria (doc dizia feito / silêncio, código diz outra coisa)

| Item | O que o doc sugeria | Realidade provada |
|---|---|---|
| **Suíte de testes** | "331/353 verdes" | **353 passam, 1 FALHA.** `forbidden_ui_literals_test.dart` reprova 3 literais (`👑`, `RARO CAM`, `🔥`) em `plan_card.dart`. Provado que o **commit está verde** e a falha vem da árvore de trabalho não commitada (Poppins). |
| **Bloco 3 Android** | tudo `[ ]` em aberto | 3.1/3.3/3.4-parcial/3.5 **estão feitos** (fatias 1-4). O doc estava atrasado, subestimando o progresso. |
| **Replay buffer Android** | "fatia futura" | Pior que ausente: **a UI oferece o card de Replay Buffer no Settings e o pré-roll no camera**, mas `ReplayBufferHostApi` **não é registrado** no `MainActivity.kt` (zero referências) e `CameraManager.kt:176-177` **descarta `includeReplayPreroll` com um `Log.w`**. O guard `3f33a77` só evita o crash — o usuário Android liga um recurso que não existe. |
| **RevenueCat** | "mock" | `purchases_flutter` está no `pubspec.yaml:24` com **zero imports**. `subscription_controller.dart:19` grava `isSubscribed: true` no SharedPreferences. **Ninguém paga e nada é bloqueado.** |
| **Gating premium** | item de DoD | **Inexistente.** `isSubscribed` só decide se aparece popup/banner. Gravar e salvar são livres. |
| **Restore purchases** | — | `paywall_screen.dart:123` → `_comingSoon`. **A Apple reprova assinatura sem restore.** |
| **Volume como gatilho** | Bloco 4.5 | Não é só ausente: `settings_screen.dart:367-370` deixa o usuário **selecionar e persistir** "Volume", sem handler nativo em **nenhuma** das plataformas. Não existe `VolumeHostApiImpl` nem no Android nem no iOS. |
| **Preview (P08)** | "share em breve" | **4 das 5 ações são snackbar** (`preview_screen.dart:114,242,272,278`), incluindo Delete. |
| **Delete** | "lógica existe, só conectar" | Confirmado: `vault_service.dart:68-75` existe e **não tem nenhum caller**. |
| **Telas** | "faltam 3" | Confirmado: enum declara 13, router registra **10**. `p05aLockMode`, `p11Terms`, `p12Privacy` têm **zero referências** no código. Privacy é **obrigatória** para submissão. |
| **Assinatura Android** | Bloco 5.2 | Provado com `apksigner`: o `app-release.apk` está assinado **`CN=Android Debug`**. A Play rejeita. |
| **Branch** | — | `develop` está **441 commits à frente da `main`** e o fix do R8 (`5a35be4`) **não foi pushado**. |

---

## Blocos sequenciados

### BLOCO 0 — Destravar e estabilizar (✅ FECHADO 2026-06-22)
- [x] **0.1** Build Android destravado (`flutter build appbundle` ✓).
- [x] **0.2** Wake-word ONNX mantido dormente (README em `ios/Runner/Native/Voice/`, histórico em `01a1f67`).
- [x] **0.3** `applicationId = "com.rarocamera"` alinhado ao iOS.
- [x] **0.4** `android:label` → "Raro Camera".

### BLOCO 1 — Firebase/Crashlytics/Analytics (✅ FECHADO 2026-07-14, provado no device 0035)
- [x] **1.1** `Firebase.initializeApp` + plugins gradle. Secrets gitignored (reconfirmado).
- [x] **1.2** 3 handlers Crashlytics — crash real chegou no painel + dSYM (UUID bateu).
- [x] **1.3** Analytics listener ligado.
- [ ] **1.4** *(pendência herdada)* upload automático de dSYM no pipeline de release.

### BLOCO 2 — Monetização real (PARCIAL — SDK ligado e provado contra Test Store; falta loja real + gating)
> **Depende de:** conta RevenueCat + produtos criados nas lojas + In-App Purchase Key. **Sem isso o app não fatura.**

> **📌 Não há login/cadastro no RARO — e isso é intencional (registrado 2026-09-02).**
> Auditado: **zero** autenticação no repo (`firebase_auth`, `google_sign_in`, `sign_in_with_apple` ausentes do `pubspec.yaml`; nenhum `signIn`/`currentUser` no código). Isso **não é uma pendência esquecida**, é a consequência de duas decisões já tomadas:
> - **A cobrança é 100% das lojas.** `PaymentMethod` só tem `apple` (Apple Pay) e `google` (Google Play) — não há cartão, PIX, boleto ou gateway próprio. Quem cobra, guarda o cartão e autentica o comprador é a App Store / Play Store, usando a conta que o usuário **já tem no aparelho**. Pedir um login nosso seria uma segunda identidade sem função.
> - **Arquitetura client-only** (ADR-0004): não existe backend nosso para hospedar contas.
> **Como o app sabe que a pessoa é premium sem login:** o RevenueCat identifica o aparelho por um **App User ID anônimo** e valida o recibo com a loja. "Restore purchases" (Bloco 2.5) é o mecanismo oficial para recuperar a assinatura em outro aparelho — é **por isso** que a Apple exige esse botão, e é o que substitui o login.
> **Quando login passaria a ser necessário (não é o caso da v1.0):** assinatura compartilhada entre iOS e Android pela mesma pessoa, backup dos vídeos na nuvem, ou área web. Qualquer um desses **exige ADR novo** (muda ADR-0004) e provavelmente backend.
> ⚠️ **Consequência a assumir:** sem login, quem troca de celular **de plataforma** (iPhone → Android) não leva a assinatura junto. Comportamento normal de app client-only, mas o dono deve saber.
- [x] **2.1** *(PR #12, provado no M54 contra Test Store)* Integrar `purchases_flutter` de fato: `Purchases.configure`, `getOfferings`, `purchasePackage` (memória `raro-pattern-revenuecat-error-handling`).
- [x] **2.2** *(PR #12)* `BillingGateway` port + `RevenueCatBillingGateway` + `FakeBillingGateway`; fonte de verdade = `CustomerInfo.entitlements.active['premium']`, prefs viram cache; sem fallback "grátis" se a key faltar (→ `unavailable`). `SubscriptionStore` → RevenueCat real, mantendo o port mockável (o port já existe e é bom — preservar).
- [x] **2.3a** *(PR #13, provado no M54 2026-09-04)* **Exportar para a galeria do celular**: Pigeon `GalleryHostApi` + MediaStore (`Movies/Raro Camera/`) no Android / `PHPhotoLibrary` add-only no iOS (ADR-0032). Sem `READ_MEDIA_VIDEO`.
- [x] **2.3b** *(PR #13, provado no M54 2026-09-04)* **Gating premium sobre GUARDAR o clipe** — ⚠️ **REGRA DO FREE DEFINIDA PELO DONO EM 2026-09-04 (pergunta que bloqueava está RESPONDIDA):**
  - **O free GRAVA e VÊ o resultado no Preview**, mas **para GUARDAR precisa assinar** — e "guardar" inclui o **vault do próprio app**, não só o rolo do sistema. Recusou o paywall → **o arquivo temporário é descartado**.
  - **Compartilhar também é travado** (premium). Isso alinha o 4.1 (Share): o botão passa a existir de verdade, mas atrás do entitlement.
  - Padrão de mercado adotado (CapCut/Lightroom): experimenta o valor, não leva o arquivo de graça.
  - **Não regride acervo:** vídeos que já estão no vault continuam acessíveis.
  - **Implementado (PR #13):** `RecordingFinished` monta `PendingClip`; Preview decide; `PersistRecording` consulta `BillingGateway`. Free recusou Salvar → temp descartado. Premium → vault + galeria do sistema.
- [ ] **2.4** Free trial 30 dias (setting de loja — `raro-pattern-revenuecat-trial-app-store-connect`).
- [x] **2.5** *(PR #12 — código pronto; restore de recibo Play REAL ainda não provado, Test Store não conta)* **Restore purchases funcional** (`paywall_screen.dart:123`) — bloqueador de review da Apple.
- [x] **2.6** *(PR #12 — `payment_method.dart` APAGADO, checkout chama `subscribe(plan:)`)* **Checkout (P10): remover o seletor de "método de pagamento".** Hoje `PaymentMethod` (`apple`/`google`) é um radio decorativo — o usuário escolhe algo que não tem efeito. Na compra in-app real **quem escolhe a forma de pagamento é a folha nativa da loja**, com os meios que a conta do usuário já tem cadastrados (cartão, PIX/carteira via Google Play, saldo, etc.). Manter o radio é duplicar — e confundir — uma escolha que não é nossa. P10 deve virar confirmação do plano + `purchasePackage`.
- [ ] **2.7** **Assinaturas nas lojas (pré-requisito do dono, não é código):** criar os 2 produtos de assinatura (Mensal R$ 9,90 · Anual R$ 89,90) no App Store Connect e no Play Console, ligar ao entitlement `premium` no RevenueCat e configurar o trial de 30 dias em **cada** loja. Sem isso `getOfferings` volta vazio e o app não tem o que vender.
- [ ] **2.8** **Textos obrigatórios de assinatura na tela de compra** — **implementado na PR #15** (pende merge): preço, periodicidade, renovação automática, cancelamento nas lojas, links Termos/Privacidade funcionando.

### BLOCO 3 — Android paridade (QUASE FECHADO)
- [x] **3.1** Gravação CameraX → vault (fatia 1, PR #5, provado no M54 via ffprobe).
- [x] **3.2** **Replay buffer / pré-roll Android — FECHADO no device (sessão 0043) e MERGEADO em `develop` (PR #11, `3a2a386`, 2026-09-02).** Rota D (ADR-0031): segmentos ~5s do CameraX `Recorder` + concat sem re-encode. Spike removido. `ReplayBufferHostApi` registrada; `includeReplayPreroll` honrado; anel recarrega ao trocar 15s↔30s. **Dono confirmou no M54:** buffer funciona e o selo da galeria mostra formato/lente da sessão (incl. 0.5×). Fora desta fatia: `saveReplay()` standalone sem UI; 16 KB (5.6b).
- [x] **3.3** Voz Android "raro gravar"/"raro parar" (fatia 3, PR #8, Vosk motor único, ADR-0029).
- [~] **3.4** HostApis no `MainActivity`: câmera ✓, voz ✓, **replay ✓** (0043); volume não existe em lugar nenhum.
- [x] **3.5** Ultra-wide discovery (`CameraLensDiscovery.kt:28-31`) — funciona, porém por **heurística de distância focal**; pode errar em aparelhos com macro/depth. Aceitável para v1.0, risco anotado.
- [ ] **3.6** Xiaomi/MIUI: modal M02 + autostart (nada implementado além do nome do evento de analytics).
- [ ] **3.7** Contract tests de paridade nas 2 plataformas.

### BLOCO 4 — Acabamentos de produto
- [x] **4.0** Fechar a árvore suja de Poppins (sessão 0041): emojis como glifo; `'RARO CAM'` no allowlist; Medium 500 removido; suíte 355/355; `5a35be4` pushado.
- [x] **4.1** *(PR #13, provado no M54 2026-09-04)* Share real com `share_plus` (`SharePlus.instance.share(ShareParams)`); free abre P09, premium abre a folha nativa.
- [x] **4.2** *(provado no M54 2026-09-04)* Delete real no Preview: diálogo de confirmação (copy deixa claro que é só do vault, não do rolo do sistema) → `vault.delete(id)` (`.mp4`+`.json`+`.jpg`) → invalida `videoListProvider` → volta à Galeria. Info abre painel com sidecar (nome, duração, data, resolução, fps, lente, tamanho via `File.lengthSync()`, replay). Delete na Galeria (P07) ficou de fora de propósito.
- [ ] **4.3** Telas faltando: P05a Lock mode. **P11 Terms + P12 Privacy implementadas (PR #15, pendente merge).**
- [ ] **4.4** Modais faltando: M02 Xiaomi, M03 Bluetooth.
- [ ] **4.5** **Volume como gatilho — código na branch `feat/volume-trigger` (ADR-0033).** Android: `dispatchKeyEvent` + consume. iOS 17.2+: `AVCaptureEventInteraction` (API oficial; KVO/`setOutputVolume` rejeitado). iOS 15–17.1: card some da UI. `+` inicia / `−` para no mesmo `_onRecTap` da voz. Analyze limpo; **433/433**; iOS `Runner.app` debug. **Prova M54 pendente** (gate de pronto). M03 Bluetooth continua fora (4.4).
- [x] **4.6** i18n pt/en/es completa (117 chaves × 3) com teste-guarda.

### BLOCO 4.5 — Faxina de repositório (anotado a pedido do dono, 2026-09-02)
> **Objetivo:** remover o que não é mais usado, para o cliente não receber (nem o agente tropeçar em) lixo. **Read-only primeiro: listar e propor, deletar só com aval.**
- [ ] **F.1** **Docs desatualizados/órfãos**: rodar `/docs-lint`. Alvos já conhecidos: `docs/sessions/NEXT-SESSION-PROMPT-voice-openwakeword.md` (marcado 🛑 OBSOLETO no próprio corpo), `NEXT-SESSION-PROMPT-bloco-0-destravar.md` e `NEXT-SESSION-PROMPT-bloco-1-firebase.md` (blocos 0 e 1 fechados). Decidir: apagar ou mover para `docs/archive/`.
- [ ] **F.2** **Sprints superados**: `sprint-2-backend-logic-ios.md` e `sprint-3-android-parity-testflight-client.md` foram reindexados pelo PLANO-MESTRE — marcar como históricos no topo ou arquivar, para não competirem como "roadmap".
- [ ] **F.3** **Código morto**: `vault_service.delete` **ganhou caller no 4.2**. Resta: scaffold ONNX dormente (`WakeWordDetector`/`WakeWordPipeline`/`OnnxModelSession` + 3 `.onnx` ≈2,4MB) — **manter dormente ou remover de vez?** Com a decisão 1 (background já resolvido no Android via Vosk) o argumento "guardar caso a Sensory entre" enfraquece. Remover exige cirurgia no `project.pbxproj`; decidir antes do build de release, onde os MB contam.
- [ ] **F.4** **Testes**: procurar testes redundantes/desligados (`skip:`) e goldens órfãos sem widget correspondente.
- [x] **F.5** **Dependências declaradas e não usadas**: `purchases_flutter` (PR #12) e `share_plus` (PR #13) passaram a ser usadas.
- [~] **F.6** **Assets**: recorte Poppins feito na 0041 (Medium 500 removido; 400/600/700 usados). Resto (fonte/imagem órfã fora do paywall) ainda aberto.

### BLOCO 5 — Loja + publicação (bloqueadores de conta, só o cliente resolve)
- [ ] **5.1** 🔴 Apple Developer Program (US$99/ano).
- [ ] **5.2** 🔴 **Keystore Android + `signingConfigs.release`** — provado hoje que o release sai com chave de debug (`build.gradle.kts:40`).
- [ ] **5.3** Certificado iOS + provisioning + `ExportOptions.plist` (não existe no repo).
- [~] **5.4** Google Play Console: **taxa US$25 paga** (dono, 2026-09-02). Ainda falta: app `com.rarocamera` na Console, Internal Testing, AAB assinado (bloqueado por 5.2 — hoje o release sai `CN=Android Debug`), license testers.
- [ ] **5.5** Assets de loja + **política de privacidade hospedada (URL obrigatória)**.
- [ ] **5.6** Builds assinados `.ipa` + `.aab` → TestFlight + Play Internal.
- [x] **5.6b** **Android 16 KB page size — FECHADO no M54 (2026-09-07, ADR-0034).** Pin `vosk-android:0.3.75` (ELF 64-bit `2**14`; JNA 5.18.1). Motor Vosk **intacto**. APK release 122.5 MB: diálogo 16 KB ausente; dono confirmou “raro gravar”/“raro parar”; logcat `vosk wake matched` START/STOP. A “voz morta” da 1ª tentativa era `ControlMode.volume`, não o AAR. `useLegacyPackaging` **não** relinka prebuilt (doc oficial). 32-bit `armeabi-v7a/libvosk.so` continua `2**12` (isento na Play).
- [ ] **5.7** Submissão e aprovação.
- [ ] **5.8** Tag `v1.0.0` + transferência das contas.

---

## Caminho crítico até "app pronto"

```
4.0 (destravar testes)  →  2.x (monetização)  →  3.2 (replay Android) ─┐
                                                 4.1-4.5 (acabamentos) ┼→ 5.x (lojas)
                        (5.1/5.2/5.4 podem correr em paralelo desde já)┘
```

**O que impede faturar:** Bloco 2 inteiro — e note que a regra de premium do dono ("só salva na galeria se for premium") depende do **2.3a**, que é feature nova, não só um `if`.
**O que impede publicar:** 5.1, 5.2, 5.4 (contas/keystore) + 4.3 (privacidade). **5.6b (16 KB) fechado.**
**Bugs a corrigir (classificação do dono):** modo Volume (4.5) — aprovado para implementação, não para ser escondido. Os 4 botões do Preview (Salvar/Share 4.1, Delete/Info 4.2) estão reais.

---

## Decisões de produto — RESPONDIDAS pelo dono (2026-09-02)

1. **Wake word em background — ✅ RESOLVIDO NA PRÁTICA, MANTER COMO ESTÁ.** O dono confirmou que **"raro gravar"/"raro parar" já funcionam em background no Android** (Vosk motor único + FGS `microphone`). **Não mexer nesse caminho.** O DoD deve ser reescrito para refletir a realidade em vez de continuar pedindo o ONNX reprovado. Sensory deixa de ser bloqueador de v1.0.
2. **O que é premium — ✅ DEFINIDO: "o app só salva vídeos na galeria se for premium."**
   ⚠️ **Atenção (auditado 2026-09-02): hoje isso não acontece de duas formas.**
   (a) **Não há gating nenhum** — `camera_flutter_api_provider.dart:93` chama `vault.save()` incondicionalmente, sem consultar assinatura.
   (b) **Não existe "galeria" no sentido do sistema** — não há `MediaStore` (Android) nem `PHPhotoLibrary` (iOS) em lugar nenhum do repo. O vídeo só vai para o **vault privado do app** (`vault_service.dart:12`, `documentsDir/vault`), que é o que a tela "Galeria" lista.
   → Ver Bloco 2.3, que virou **duas** tarefas: criar a exportação real para a galeria do celular **e** colocá-la atrás do entitlement.
3. **Replay no Android — ✅ IMPLEMENTAR.** O dono classificou o comportamento atual como bug a corrigir, não como recurso futuro. Ver Bloco 3.2.
4. **Modo Volume — ✅ IMPLEMENTAR** nas 2 plataformas. Ver Bloco 4.5.

---

## Estimativa (referência, não prazo)

| Bloco | Sessões | Depende de |
|---|---|---|
| 4.0 destravar | <1 | — |
| 2 — Monetização | 2-3 | contas RevenueCat + lojas |
| 3.2 — Replay Android | 2-4 | device Android |
| 3.6 + 4.1-4.5 | 2-3 | decisões de produto |
| 5 — Publicação | 2-4 | **contas pagas do cliente** |
| **Total** | **~8-15** | |

---

## Próxima ação imediata

**4.0 e 3.2 fechados no device e em `develop` (PR #11).** Origin só tem `main` + `develop`. Próxima fase: dono escolhe **Bloco 2 (monetização)**, **4.5 (volume)** ou **5.6b (16 KB / Play)**.
