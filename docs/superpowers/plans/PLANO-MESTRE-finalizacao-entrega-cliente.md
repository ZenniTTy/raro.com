# Plano-Mestre — Finalização e Entrega ao Cliente (RARO v1.0)

> **Criado:** 2026-06-22 (sessão pós-0029) a partir de auditoria de CÓDIGO REAL (3 agentes paralelos), não de docs. Sequencia tudo que falta entre o estado atual e o gate de entrega ([09-DOD.md](../../09-DOD.md)).
>
> **Alvo de entrega (decisão do dono, 2026-06-22):** iOS + Android **paridade total**, depois publicação nas duas lojas.
>
> **Relação com os sprints existentes:** este plano-mestre é o índice sequenciado. [sprint-2-backend-logic-ios.md](sprint-2-backend-logic-ios.md) e [sprint-3-android-parity-testflight-client.md](sprint-3-android-parity-testflight-client.md) têm o detalhe atômico de cada task; este doc reconcilia o drift entre eles e a realidade + adiciona os blocos que escaparam (i18n, telas faltando, build Android quebrado, wake-word revertido).

---

## Estado real auditado (2026-06-22)

### ✅ Pronto e validado no iPhone 12 (não mexer)
- Gravação MP4 H.264/HEVC + áudio → vault (`RecordingPipeline.swift`, `AVAssetWriter`)
- Replay buffer 15/30s + pré-roll no REC (`ReplayBuffer.swift`, `AVMutableComposition`)
- Voz foreground "raro gravar"/"raro parar" (`VoiceManager.swift`, SFSpeech — revertido na 0029)
- Galeria com vídeos REAIS do vault (`vault.listAll()`, não mock)
- 9 telas roteadas (P01-P11) + modal M01 subscription popup
- 320 testes Dart passando

### ❌ Drift descoberto (marcado como feito nos sprints, mas é mock/ausente)
| Item | Sprint dizia | Realidade |
|---|---|---|
| RevenueCat | escopo S2 | **mock total** — `subscribe()` só seta bool local; `purchases_flutter` 0 usos |
| Firebase | escopo S2 | **nunca inicializado** — `main.dart` sem `initializeApp`; crasharia em release |
| Share | — | botão "Em breve" (`_comingSoon`); `share_plus` 0 usos |
| i18n | escopo S3 | **0 arquivos `.arb`**; tudo hardcoded PT-BR |
| Wake-word "Raro" toggle background | meta DoD >90% | **inviável** (4 modelos falharam no device — sessão 0029); revertido p/ foreground |

### 🔴 Bug que trava AGORA
- **Android não compila:** `CameraHostApiImpl.kt` não implementa `startRecording`/`stopRecording` que o `CameraApi.g.kt` (regen 2026-06-07) exige. `flutter build appbundle` falha.

---

## Blocos sequenciados (ordem de execução recomendada)

### BLOCO 0 — Destravar e estabilizar (1 sessão, rápido)
**Objetivo:** o projeto compila e roda nas 2 plataformas, sem dívida silenciosa.
- [ ] **0.1** Destravar build Android: implementar `startRecording`/`stopRecording` no `CameraHostApiImpl.kt` (stub que lança `UnsupportedOperationException` como o iOS faz com replay, OU já a impl real se atacar o Bloco 3 junto). Confirmar `flutter build appbundle` passa.
- [ ] **0.2** Decidir wake-word ONNX órfão: remover `raro.onnx` + 3 arquivos Swift do bundle (peso morto) OU manter dormente com nota. Recomendo remover do bundle de produção (fica preservado no commit `01a1f67`).
- [ ] **0.3** Resolver App ID Android inconsistente: `com.rarocamera.raro_mobile` vs `com.rarocamera` (iOS). **Decisão imutável pós-publicação** — alinhar gradle ↔ Blueprint ↔ Play Console.
- [ ] **0.4** Corrigir `android:label` (`raro_mobile` → "Raro Camera").

### BLOCO 1 — Infra que evita crash + mede (1-2 sessões)
**Objetivo:** app não crasha em release, telemetria liga. **Depende: conta Firebase do cliente.**
- [ ] **1.1** Firebase: `flutterfire configure`, `GoogleService-Info.plist` + `google-services.json`, `Firebase.initializeApp` no `main`, plugin gradle.
- [ ] **1.2** Crashlytics: 3 handlers (FlutterError + PlatformDispatcher + Isolate — memória `raro-pattern-crashlytics-3-handlers`).
- [ ] **1.3** Confirmar analytics events disparando (já há `camera_analytics_listener`).

### BLOCO 2 — Monetização real (2-3 sessões)
**Objetivo:** app pago funciona. **Depende: conta RevenueCat + produtos na loja + In-App Purchase Key.**
- [ ] **2.1** Integrar `purchases_flutter`: `Purchases.configure` com API key, `getOfferings`, `purchasePackage`, sync `CustomerInfo` (memória `raro-pattern-revenuecat-error-handling`).
- [ ] **2.2** Trocar `SubscriptionStore` mock → RevenueCat real, mantendo o port mockável p/ testes.
- [ ] **2.3** Gating: "salvar vídeo exige entitlement `premium`" (DoD).
- [ ] **2.4** Free trial 30 dias (setting da loja — memória `raro-pattern-revenuecat-trial-app-store-connect`).
- [ ] **2.5** Wire paywall (P10) + checkout (P11) ao fluxo real de compra.

### BLOCO 3 — Android paridade (o maior bloco, 5-8 sessões)
**Objetivo:** Android faz tudo que o iOS faz. **Depende: device Android real (preferir Xiaomi/MIUI).**
- [ ] **3.1** Gravação CameraX `VideoCapture` → vault (paridade com `RecordingPipeline.swift`)
- [ ] **3.2** Replay buffer MediaCodec ring (paridade com `ReplayBuffer.swift`; memória `raro-pattern-android-mediacodec-buffer-management`)
- [ ] **3.3** Voz Android: `SpeechRecognizer` foreground "raro gravar"/"raro parar" (paridade com `VoiceManager.swift`)
- [ ] **3.4** Registrar HostApis no `MainActivity` (hoje só câmera)
- [ ] **3.5** Ultra-wide/lens 0.5x: validar discovery + esconder botão quando indisponível (memória `raro-pattern-android-camerax-ultra-wide-unreliable`)
- [ ] **3.6** Xiaomi/MIUI: permissões + autostart (modais M02 guide)
- [ ] **3.7** Contract tests de paridade passando em ambas plataformas

### BLOCO 4 — Acabamentos de produto (2-3 sessões)
**Objetivo:** telas/features que faltam pra passar na review e cumprir o Blueprint.
- [ ] **4.1** Share real: `SharePlus.instance.share` com `filePath` do vault (4 botões do preview hoje em `_comingSoon`)
- [ ] **4.2** Delete real (lógica `vault.delete` existe, só conectar)
- [ ] **4.3** Telas faltando: P05a Lock mode, P11 Terms, P12 Privacy (+ rotas)
- [ ] **4.4** Modais faltando: M02 Xiaomi guide, M03 Bluetooth detected
- [ ] **4.5** Volume button trigger (iOS KVO + Android) — memória `raro-pattern-ios-volume-button-kvo`
- [ ] **4.6** i18n: `l10n.yaml` + `app_pt/en/es.arb`, extrair literais hardcoded, `AppLocalizations` (memória `raro-pattern-flutter-i18n-synthetic-package-false`)

### BLOCO 5 — Infra de loja + publicação (depende 100% de contas do cliente)
**Objetivo:** apps publicados. **Bloqueadores duros que SÓ o cliente resolve.**
- [ ] **5.1** 🔴 Apple Developer Program ($99/ano) — bloqueador raiz iOS (sem ele, sem TestFlight)
- [ ] **5.2** 🔴 Keystore Android release + `key.properties` + `signingConfigs.release` (hoje assina com debug = Play rejeita)
- [ ] **5.3** Certificado de distribuição iOS + provisioning + `ExportOptions.plist`
- [ ] **5.4** Google Play Console ($25 taxa única) + Internal Testing track
- [ ] **5.5** Assets de loja: ícones Android brandizados, splash, screenshots (iPhone 6.7"/6.5" + Android), descrições pt/en/es, política de privacidade (URL obrigatória)
- [ ] **5.6** Builds release `.ipa` + `.aab` assinados → TestFlight + Play Internal
- [ ] **5.7** Submissão + aprovação nas 2 lojas
- [ ] **5.8** Tag `v1.0.0` + transferência das contas pro cliente

---

## Gate de entrega (DoD) — o que falta marcar

Do [09-DOD.md](../../09-DOD.md), aberto hoje:
- Funcional: 13 telas+3 modais (faltam 3 telas+2 modais), wake-word >90% (**REAVALIAR** — toggle background inviável; foreground funciona mas o DoD pede background?), replay Android, lock mode bateria, Xiaomi real, i18n, trial 30d, gating premium
- Técnico: lint/typecheck/test verdes (✅ Dart), cobertura, builds release assinados
- Processo: ADRs, docs sem TBD, publicação, tag, transferência

**⚠️ Item de produto a decidir com o cliente:** o DoD pede *"wake word detectado >90% em ambiente silencioso"* — provado inviável em background com "Raro". Opções: (a) aceitar voz foreground-only (app aberto), (b) mudar a wake-word, (c) re-tentar background com outra abordagem. **Não é técnico, é de produto.**

---

## Estimativa grosseira de esforço

| Bloco | Sessões | Depende de |
|---|---|---|
| 0 — Destravar | 1 | — |
| 1 — Firebase | 1-2 | conta Firebase |
| 2 — Monetização | 2-3 | RevenueCat + lojas |
| 3 — Android paridade | 5-8 | device Android |
| 4 — Acabamentos | 2-3 | — |
| 5 — Loja/publicação | 2-4 | **contas pagas do cliente** |
| **Total** | **~13-21 sessões** | |

> Nota Karpathy: estimativas são referência, não deadline. O caminho crítico real é o Bloco 3 (Android paridade) + os bloqueadores de conta do Bloco 5 (que não dependem de código).

---

## Próxima ação imediata

**Bloco 0.1** — destravar o build Android (1 fix, desbloqueia tudo). É a única coisa que está objetivamente quebrada hoje. Tudo o mais é "falta implementar", não "está quebrado".
