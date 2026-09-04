# Bloco 2 — Guia de setup RevenueCat (pré-código)

> Status: guia de pré-requisitos · Atualizado 2026-09-02 (sessão pós-0043)
> Este guia **NÃO é código**. É o passo a passo das contas/dashboards que o Bloco 2 do [PLANO-MESTRE](PLANO-MESTRE-finalizacao-entrega-cliente.md) exige antes de a integração `purchases_flutter` funcionar e poder ser **provada no device**.
>
> Fontes cruzadas nesta revisão: [RevenueCat Projects](https://www.revenuecat.com/docs/projects/overview), [Configuring Products](https://www.revenuecat.com/docs/projects/configuring-products) (inclui Test Store), [Connect a Store](https://www.revenuecat.com/docs/projects/connect-a-store), [In-App Purchase Key](https://www.revenuecat.com/docs/service-credentials/itunesconnect-app-specific-shared-secret/in-app-purchase-key-configuration), [ASC API Key](https://www.revenuecat.com/docs/service-credentials/itunesconnect-app-specific-shared-secret/app-store-connect-api-key-configuration), [Google Play credentials](https://www.revenuecat.com/docs/service-credentials/creating-play-service-credentials), [Restore Behavior](https://www.revenuecat.com/docs/projects/restore-behavior), [Configuring the SDK](https://www.revenuecat.com/docs/getting-started/configuring-sdk), [Test Store](https://www.revenuecat.com/docs/test-and-launch/sandbox/test-store), Context7 `/websites/revenuecat` + `/websites/pub_dev_purchases_flutter`.
>
> Valores travados (fonte: `packages/shared/lib/src/subscription/subscription.dart` + ADR-0010):
>
> | Campo | Valor exato |
> |---|---|
> | SKU mensal | `raro_premium_monthly_BRL_9_90` |
> | SKU anual | `raro_premium_yearly_BRL_89_90` |
> | Preços | R$ 9,90 / R$ 89,90 |
> | Entitlement | `premium` (byte a byte) |
> | Trial (copy) | 30 dias |
> | Bundle / applicationId | `com.rarocamera` |
> | SDK | `purchases_flutter: ^10.1.1` |

---

## O que este guia destrava (e o que não)

| Depois de… | Dá para… | Ainda NÃO dá para… |
|---|---|---|
| **Fase 1** (conta + projeto + Test Store, ~20 min, grátis) | Eu escrever 2.1/2.2 no código e você **simular compra** no device sem Apple/Play | Cobrar dinheiro real; passar no restore que a Apple exige (Test Store **não** restaura recibo de loja) |
| **Fase 2** (App Store Connect + Play Console + chaves de servidor) | Compra sandbox real, restore real, trial real, submissão | Publicar sem 5.1/5.2/5.4 (contas pagas / keystore) e sem 5.6b (16 KB) |

Ordem oficial do RevenueCat (2026): **Test Store primeiro** para desenvolver; **lojas reais depois**, quando for submeter. O guia antigo (2026-07-14) pedia “lojas primeiro” — isso era verdade **antes** do Test Store. Hoje o caminho recomendado é o abaixo.

---

## Fase 1 — HOJE (sem Apple Dev, sem Play Console)

### 1.1 Conta (em nome do cliente)

O contrato do projeto ([docs/01-PROJECT.md](../../01-PROJECT.md)) manda criar Firebase / lojas / **RevenueCat** em nome do **contratante** (Vitor Autorino Lopes), não da Elovision.

1. Abra [https://app.revenuecat.com/signup](https://app.revenuecat.com/signup).
2. Cadastre com o **e-mail do Vitor** (dono do produto). Se você criar com o seu e-mail por praticidade:
   - Convide o Vitor como **Administrator**.
   - Depois transfira ownership em **Project settings → Transfer ownership** (só o owner transfere; o receptor precisa aceitar o e-mail). Não deixe a conta de produção na Elovision “para transferir depois” — o MTR > US$2.500 exige billing no receptor.
3. Aceite os termos. O plano **gratis** cobre o RARO até ~US$2,5k MTR; não precisa pagar agora.
4. **Não** ligue Stripe / Web Billing / Amazon / Roku. O RARO é **só** App Store + Google Play (Blueprint §2.4, ADR-0004 client-only).

### 1.2 Projeto

1. No topo: **Projects → + Create new project**.
2. **Project name:** `RARO` (ou `Raro Camera` — o nome é cosmético; o que o código checa é o entitlement).
3. Em **Project settings → General**:
   - **Restore Behavior:** deixe **Transfer to new App User ID** (default). O RARO **não tem login**; a tabela oficial do RevenueCat manda exatamente esse valor para apps só com App User ID anônimo. Sem isso, reinstalar o app perde a assinatura.
   - **Não** escolha *Keep with original App User ID* (isso exige conta de usuário no app).
   - **Não** escolha *Share between App User IDs (legacy)* (nem aparece em projeto novo).
4. Cada projeto novo já nasce com um **Test Store**. Não apague.

### 1.3 Apps iOS e Android (configs da loja — ainda sem credencial)

Mesmo sem as lojas pagas, crie os dois apps para o bundle ficar certo. As chaves `appl_` / `goog_` só funcionam de verdade depois da Fase 2; o Test Store tem **outra** API key.

1. Sidebar → **Apps** (ou *Apps & providers*) → **+ New**.
2. **Apple App Store**
   - App name: `Raro Camera`
   - Bundle ID: `com.rarocamera` (igualdade exata com o iOS)
   - Deixe Shared Secret / In-App Purchase Key **em branco** até a Fase 2. Salve.
3. **+ New** de novo → **Google Play Store**
   - App name: `Raro Camera`
   - Package name: `com.rarocamera` (igualdade exata com `applicationId`)
   - Service credentials: vazio até a Fase 2. Salve.

### 1.4 Produtos no Test Store

1. **Product catalog → Products → aba Test Store → + New**.
2. Produto 1:
   - Identifier: `raro_premium_monthly_BRL_9_90` (**byte a byte**)
   - Duration: monthly
   - Price: `9.90` BRL
3. Produto 2:
   - Identifier: `raro_premium_yearly_BRL_89_90`
   - Duration: annual
   - Price: `89.90` BRL
4. Use os **mesmos identifiers** que vão nas lojas reais. Assim o Offering não precisa ser remontado depois.

> Trial **não** se configura no Test Store como “30 dias de loja”. No Test Store a compra é simulada. O trial real é setting da **loja** (memória `raro-pattern-revenuecat-trial-app-store-connect`). Sem isso na Fase 2, o paywall escreve “30 dias grátis” e a loja cobra na hora — bug de produção.

### 1.5 Entitlement `premium`

1. **Product catalog → Entitlements → + New**.
2. Identifier: `premium` — **não** `pro`, `Premium`, `raro_premium`. O código (quando existir) vai ler `CustomerInfo.entitlements.active['premium']`.
3. Description: `Raro Camera premium (export to system gallery)`.
4. Abra o entitlement → **Attach** → anexe os 2 produtos do Test Store.
5. Quando a Fase 2 importar os 4 produtos reais (2 iOS + 2 Android), anexe **esses quatro também** no mesmo `premium`. Um entitlement, todas as lojas.

### 1.6 Offering default + 2 packages

`getOfferings()` devolve o offering marcado como **current/default**. Sem isso o paywall fica vazio mesmo com produtos criados.

1. **Product catalog → Offerings → + New**.
2. Identifier: `default` (não dá para mudar depois). Marque como **current**.
3. Dentro do offering → **+ Add package**:
   - Package identifier: **`$rc_monthly`** (tipo Monthly) → produto mensal.
   - Package identifier: **`$rc_annual`** (tipo Annual) → produto anual.
4. Cada package agrupa o equivalente iOS + Android + Test Store. Quando a Fase 2 importar, **adicione** os produtos reais no mesmo package (não crie um segundo offering).

**Não** crie RevenueCat Paywall (UI hospedada). O RARO já tem P09/P10 no protótipo. Offering sim; paywall remoto não.

### 1.7 API keys (guardar fora do git)

1. **Project Settings → API keys**.
2. Anote em um gerenciador de senhas (1Password / Bitwarden), **nunca** no chat público, **nunca** no repo:
   - **Test Store API key** (é a que o SDK usa **agora** para desenvolver).
   - Quando a Fase 2 ligar as lojas: Apple public key (`appl_…`) e Google public key (`goog_…`).
3. Flutter híbrido **obriga uma key por plataforma** nas builds de loja (`PurchasesConfiguration(apiKey)`). Test Store é uma terceira key, só debug.
4. **NUNCA** submeter App Store / Play com a Test Store key. ([docs](https://www.revenuecat.com/docs/getting-started/configuring-sdk): *CRITICAL: Never submit apps with Test Store API key*).
5. Quando for hora de codar: as keys entram por `--dart-define` / ficheiro gitignored, no mesmo padrão do Firebase (`firebase_options.dart` já é gitignored). Placeholders previstos em `docs/04-ROADMAP-SPECS/block-infra.md`: `REVENUECAT_API_KEY_IOS` / `REVENUECAT_API_KEY_ANDROID`.

### 1.8 O que me mandar quando a Fase 1 estiver feita

Pode colar **só** isto (sem as keys):

```
Projeto: RARO
Bundle: com.rarocamera (iOS + Android criados)
Restore: Transfer to new App User ID
Entitlement: premium (anexado aos 2 produtos Test Store)
Offering current: default
Packages: $rc_monthly + $rc_annual
Test Store key: tenho no cofre (prefixo test_ / teststore — confirmar)
Não commitei nada
```

Aí eu começo o código 2.1/2.2 contra o Test Store. Restore de review Apple continua pendente da Fase 2.

---

## Fase 2 — Lojas reais (quando 5.1 e 5.4 existirem)

Pré-requisitos: **5.1 Apple Developer US$99/ano ainda aberto.** **5.4 taxa Play US$25 já paga** (dono, 2026-09-02) — a Console existe; ainda faltam o app `com.rarocamera`, Internal Testing e um AAB **não** assinado com a chave de debug (5.2). Sem o AAB na faixa interna a Play em geral **não deixa ativar** as subscriptions.

### 2.A App Store Connect (iOS)

1. **Paid Apps Agreement** — App Store Connect → *Business / Agreements*. Aceitar + dados bancários/fiscais. Sem isso o produto pago **não ativa**. É o passo mais esquecido.
2. App `com.rarocamera` criado (App ID).
3. **Subscriptions** → um **Subscription Group** (ex. `Raro Premium`). Os dois planos no **mesmo** grupo (upgrade/downgrade mensal↔anual sem duplicar cobrança).
4. Produto mensal — Product ID **exato** `raro_premium_monthly_BRL_9_90`, 1 mês, R$ 9,90.
5. Produto anual — Product ID **exato** `raro_premium_yearly_BRL_89_90`, 1 ano, R$ 89,90.
6. **Introductory offer** em **cada** produto: tipo Free Trial, duração **1 month**. A Apple não tem “30 dias”; as opções são 3d / 1w / 2w / 1m / … (memória `raro-pattern-revenuecat-trial-app-store-connect`). Copy do app continua “30 dias grátis”; a loja cobra no aniversário do mês.
7. **Duas chaves Apple distintas** (são `.p8` diferentes; não misturar):

   | Chave | Onde gera | Onde cola no RevenueCat | Para quê |
   |---|---|---|---|
   | **In-App Purchase Key** (obrigatória no SDK 5+/StoreKit 2) | Users and Access → Integrations → **In-App Purchase** | App iOS → aba *In-app purchase key* (`.p8` + Key ID + Issuer ID) | Validar transação. Sem ela o SDK 10.x **não grava** a compra e o user paga e não vira premium. |
   | **App Store Connect API** (recomendada) | Users and Access → Integrations → **App Store Connect API**, role ≥ App Manager | App iOS → aba *App Store Connect API* (`.p8` + Issuer ID + Vendor number em Payments) | Importar produtos/preços pro dashboard. |

   O **Issuer ID** só aparece depois de existir **alguma** API key. Se a página IAP não mostrar Issuer ID, crie primeiro uma ASC API key (o nível da key não importa só para “aparecer o Issuer”).
   **Não** use App-Specific Shared Secret como caminho principal — é StoreKit 1, legado. O RARO é iOS 15+ e `purchases_flutter ^10.1.1` (StoreKit 2 default).
8. **Sandbox tester:** Users and Access → Sandbox → criar e-mail de teste. No iPhone: Settings → App Store → sair da Apple ID real **só** na hora do teste de compra.

### 2.B Google Play Console (Android)

O caminho antigo “Setup → API access” **morreu**. Fluxo 2026:

1. Conta Play Developer + app `com.rarocamera` + **um AAB em teste interno** (a Play recusa ativar assinatura sem build).
2. **Monetize → Subscriptions**:
   - Product ID `raro_premium_monthly_BRL_9_90` + base plan mensal R$ 9,90 → **Activate**.
   - Product ID `raro_premium_yearly_BRL_89_90` + base plan anual R$ 89,90 → **Activate**.
   - Offer de free trial **30 dias** em cada base plan (aqui sim é 30 dias literais).
   - Draft **não** aparece no RevenueCat.
3. **Service account** (RevenueCat fala com a Play):
   1. Google Cloud do **mesmo** projeto ligado à Play Console.
   2. Ativar **Google Play Android Developer API** e **Google Play Developer Reporting API**.
   3. IAM → Service Accounts → criar (ex. `revenuecat-raro`). Roles no Cloud: Pub/Sub Editor (ou Admin) + Monitoring Viewer.
   4. Keys → Add JSON → baixar **uma vez**. Guardar no cofre.
   5. Play Console → **Users and permissions → Invite user** com o e-mail `…@….iam.gserviceaccount.com`.
   6. Account permissions mínimas (checklist oficial):
      - View app information and download bulk reports (read-only)
      - View financial data, orders, and cancellation survey response
      - **Manage orders and subscriptions** (sem isso o RevenueCat não lê status)
      - Manage store presence
   7. Apply + Save. Status do user tem que ficar **Active**.
4. Colar o JSON no app Android do RevenueCat → Save. A validação Google pode levar **até 36 h** (erros 503/521 nesse intervalo são esperados — não refazer o setup).
5. **License testing:** Play Console → Setup → License testing → e-mail da conta Google do M54.
6. (Depois, recomendado) Real-time developer notifications: tópico Pub/Sub que o RevenueCat gera → colar em Play Console → Monetize → Monetization setup.

### 2.C Ligar no RevenueCat e importar

1. App iOS: upload IAP Key + (recomendado) ASC API Key.
2. App Android: upload JSON do service account.
3. **Product catalog → Products** → importar (ou adicionar na mão) os 4 Product IDs.
4. Entitlement `premium` → Attach os 4 produtos de loja (além dos 2 Test Store).
5. Offering `default` → cada package `$rc_monthly` / `$rc_annual` contém Test Store **e** iOS **e** Android.
6. Copiar `appl_…` e `goog_…`. Builds **release** usam essas; debug pode continuar na Test Store key até a primeira prova sandbox.

### 2.D Prova sandbox (gate real, não Test Store)

- iPhone: sandbox tester → comprar mensal → `entitlements.active['premium']` true → Restore purchases recupera depois de reinstalar.
- M54: license tester → idem.
- Confirmar no dashboard RevenueCat que o evento aparece (sandbox).
- Trial: a folha nativa da loja tem que mostrar o período grátis. Se não mostrar, o introductory offer não está ativo — **não** “consertar no Flutter”.

---

## O que NÃO fazer

- Não commitar `appl_`, `goog_`, `test_`, `.p8`, JSON de service account, Shared Secret.
- Não passar `appUserID` custom no `Purchases.configure` — o RARO é anônimo (PLANO-MESTRE Bloco 2, “sem login”).
- Não criar segundo entitlement (`pro`, `gold`).
- Não mudar os Product IDs depois de publicados (imutáveis nas lojas).
- Não configurar trial no código (`freeTrialDays = 30` é **copy**).
- Não usar a Test Store key em release / TestFlight / Play Internal “de produção”.
- Não esperar que `restorePurchases` funcione no Test Store (não há recibo de loja).
- Não ligar webhook Firebase nesta fatia (Blueprint: opcional).
- Não criar produtos de vida única / consumível — só os 2 subscriptions.
- Não mexer em voz (3.3 congelado).

---

## Checklist “Fase 1 pronta para eu codar 2.1”

- [ ] Conta RevenueCat no e-mail do dono (ou transferência agendada)
- [ ] Projeto `RARO` com Restore = Transfer to new App User ID
- [ ] Apps iOS + Android `com.rarocamera`
- [ ] 2 produtos Test Store com os SKUs exatos
- [ ] Entitlement `premium` anexado
- [ ] Offering `default` current com `$rc_monthly` + `$rc_annual`
- [ ] Test Store API key no cofre (fora do git)
- [ ] Mensagem 1.8 enviada (sem colar a key)

## Checklist “Fase 2 pronta para prova no device / review”

- [ ] Paid Apps Agreement aceito
- [ ] 2 IAP iOS + trial 1 month em cada
- [ ] IAP Key (.p8) no RevenueCat (StoreKit 2)
- [ ] Sandbox tester Apple
- [ ] 2 subscriptions Play **Active** + trial 30d + license tester
- [ ] Service account JSON no RevenueCat + user Active na Play (aguardar 36 h se 503)
- [ ] 4 produtos no entitlement `premium` + packages cruzados
- [ ] Keys `appl_` / `goog_` no cofre
- [ ] Compra sandbox + restore sandbox nas 2 plataformas
