# Bloco 2 — Guia de setup de contas/produtos/chaves (pré-código)

> Status: guia de pré-requisitos · Data: 2026-07-14
> Este guia NÃO é código. É o passo a passo das contas/dashboards que o Bloco 2 do [PLANO-MESTRE](PLANO-MESTRE-finalizacao-entrega-cliente.md) exige antes de a integração RevenueCat funcionar e poder ser provada no device.
> Valores travados do projeto (fonte: `packages/shared/lib/src/subscription/subscription.dart`): SKU mensal `raro_premium_monthly_BRL_9_90` · SKU anual `raro_premium_yearly_BRL_89_90` · entitlement `premium` · free trial `30` dias · Mensal R$ 9,90 · Anual R$ 89,90.
> SDK confirmado via Context7 (`/websites/pub_dev_purchases_flutter`, 2026-07-14): `Purchases.configure(PurchasesConfiguration(apiKey, ...))` → `getOfferings()` → `CustomerInfo.entitlements.active['premium']`.

---

## Por que este guia existe

O código do RevenueCat compila sem nada disso — mas `getOfferings()` volta **vazio** e nenhuma compra acontece. O gate do projeto exige **prova de compra no device**, e isso é impossível sem: (1) produtos criados nas lojas, (2) app no RevenueCat com as API keys, (3) chaves de servidor ligando RevenueCat ↔ Apple/Google. Tudo isso é feito em dashboards, com **credenciais que são suas** (o dono do produto) — eu não posso criar nem inventar.

Ordem importa: **lojas primeiro** (criar os produtos), **depois RevenueCat** (que lê os produtos das lojas). Fazer ao contrário deixa o RevenueCat sem o que importar.

---

## Visão geral do que precisa existir (as "3 coisas")

| # | O que é | Onde se cria | Serve para |
|---|---|---|---|
| 1 | **Produtos de assinatura** (2 SKUs) | App Store Connect (iOS) + Play Console (Android) | O que o usuário compra; define preço e trial |
| 2 | **App no RevenueCat** + **API keys** | dashboard RevenueCat | O SDK do app conversa com o RevenueCat via a API key |
| 3 | **Chaves de servidor** (App Store Server / In-App Purchase Key + Google service account) | Apple/Google → coladas no RevenueCat | RevenueCat valida os recibos de compra com as lojas |

> **A API key do RevenueCat é diferente por plataforma** (uma "Apple API key", uma "Google API key") e **não é** a mesma coisa que a In-App Purchase Key da Apple. Não confundir: a primeira o app usa; a segunda o RevenueCat usa por baixo dos panos.

---

## Parte A — App Store Connect (iOS)

Pré-requisito: conta Apple Developer paga (US$99/ano) em nome do cliente, e o app `com.rarocamera` já registrado como App ID.

1. **Contrato de apps pagos:** App Store Connect → *Business* / *Agreements* → aceitar o "Paid Apps Agreement" e preencher dados bancários/fiscais. **Sem isso, nenhum produto pago fica ativo.** (É o passo mais esquecido.)
2. **Criar os 2 produtos** (App Store Connect → seu app → *Subscriptions*):
   - Criar um **Subscription Group** (ex.: "Raro Premium"). Os dois planos ficam no mesmo grupo (assim o usuário troca entre mensal/anual sem comprar os dois).
   - Produto 1 — **Product ID exatamente** `raro_premium_monthly_BRL_9_90`, duração 1 mês, preço R$ 9,90.
   - Produto 2 — **Product ID exatamente** `raro_premium_yearly_BRL_89_90`, duração 1 ano, preço R$ 89,90.
   - > Os Product IDs precisam bater **byte a byte** com os SKUs em `subscription.dart`, senão `getOfferings()` não acha.
3. **Free trial 30 dias:** dentro de cada produto → *Subscription Prices* / *Introductory Offers* → adicionar oferta introdutória do tipo **Free Trial**, duração conforme a loja permite. ⚠️ A Apple oferece durações fixas (ex.: 3 dias, 1 semana, **1 mês**). "30 dias" na prática vira **"1 mês"** na Apple — é o mais próximo e é o que a memória `raro-pattern-revenuecat-trial-app-store-connect` já registrou. Confirmar que isso é aceitável (o código usa `freeTrialDays = 30` como referência de UI, mas a loja é a fonte de verdade do trial real).
4. **In-App Purchase Key (para o RevenueCat validar):** App Store Connect → *Users and Access* → *Integrations* / *In-App Purchase* → gerar uma **In-App Purchase Key** → baixar o arquivo `.p8` + anotar o **Key ID** e o **Issuer ID**. Esses três vão colados no RevenueCat (Parte C).
5. **Sandbox tester:** App Store Connect → *Users and Access* → *Sandbox* → criar um usuário de teste (email que você controle). É com ele que você loga no iPhone para testar a compra sem gastar dinheiro real.

---

## Parte B — Google Play Console (Android)

> Pode ser feito depois, já que a paridade Android é Bloco 3. Mas o RevenueCat aceita configurar só iOS primeiro. Registre aqui para não esquecer.

Pré-requisito: conta Google Play Developer (US$25 única) + app `com.rarocamera` criado + um build subido em faixa interna (a Play exige um AAB publicado em teste interno antes de ativar produtos).

1. **Criar as assinaturas** (Play Console → seu app → *Monetize* → *Subscriptions*):
   - Assinatura com **Product ID** `raro_premium_monthly_BRL_9_90` (base plan mensal, R$ 9,90).
   - Assinatura com **Product ID** `raro_premium_yearly_BRL_89_90` (base plan anual, R$ 89,90).
   - Free trial: adicionar uma **offer** do tipo *free trial* de 30 dias em cada base plan (a Play permite 30 dias de fato, diferente da Apple).
2. **Service account para o RevenueCat:** Play Console → *Setup* → *API access* → criar/ligar um **Google Cloud service account** com permissão de ver compras financeiras → baixar o JSON de credencial. Esse JSON vai colado no RevenueCat (Parte C).
3. **License tester:** Play Console → *Setup* → *License testing* → adicionar o email de teste (compra sem cobrança real).

---

## Parte C — RevenueCat (liga tudo)

Pré-requisito: conta grátis em revenuecat.com.

1. **Criar um Project** "RARO" e, dentro dele, **dois apps**: um iOS (bundle `com.rarocamera`) e um Android (package `com.rarocamera`).
2. **Colar as chaves de servidor** (é isso que valida os recibos):
   - No app iOS do RevenueCat → *App Store Connect API* → subir o `.p8` + Key ID + Issuer ID (da Parte A.4).
   - No app Android → subir o JSON do service account (da Parte B.2).
3. **Importar/mapear os produtos:** RevenueCat → *Products* → adicionar os 4 Product IDs (2 iOS + 2 Android — os mesmos strings dos SKUs).
4. **Criar o Entitlement `premium`** (RevenueCat → *Entitlements* → New) → anexar os 4 produtos a ele. **O identificador tem que ser exatamente `premium`** (é o que o código checa: `entitlements.active['premium']`).
5. **Criar um Offering** (RevenueCat → *Offerings* → o "current") com dois **Packages**: um Monthly (aponta pros SKUs mensais) e um Annual (aponta pros anuais). É o que `getOfferings()` devolve pro paywall.
6. **Pegar as API keys do app** (RevenueCat → *API keys*): copiar a **Apple API key** (começa com `appl_...`) e a **Google API key** (`goog_...`). São essas que o app usa no `Purchases.configure`. **Nunca commitar** — entram por `--dart-define` ou config local gitignored, igual ao Firebase.

---

## Checklist de "pronto para eu codar 2.1–2.5"

Quando estes itens existirem, me avise e eu integro + a compra é provável no device (sandbox):

- [ ] Paid Apps Agreement aceito (Apple)
- [ ] 2 produtos criados na App Store Connect com os Product IDs exatos + trial
- [ ] In-App Purchase Key (.p8 + Key ID + Issuer ID) gerada
- [ ] Sandbox tester criado
- [ ] App(s) criados no RevenueCat com as chaves de servidor coladas
- [ ] Entitlement `premium` criado com os produtos anexados
- [ ] Offering "current" com packages Monthly + Annual
- [ ] Apple API key (`appl_...`) em mãos para me passar na hora de configurar (via canal seguro, nunca no repo)

> Android (Parte B) pode ficar para o Bloco 3 sem travar o iOS.

---

## O que eu faço enquanto isso (sem credenciais)

Posso adiantar a **estrutura de código testável** que não depende das contas: trocar o `SubscriptionStore` mock por uma camada RevenueCat mantendo o **port mockável** (para os testes não baterem na rede), o mapeamento de erro via `PurchasesErrorHelper.getErrorCode` (memória `raro-pattern-revenuecat-error-handling`), e o wiring do paywall/checkout — tudo com testes, deixando só a `configure` real + a prova no device pendentes das chaves. Se quiser essa parte agora, é só dizer; senão, seguimos só com o guia até você montar as contas.
```
