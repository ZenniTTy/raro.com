# 2026-09-03 — revenuecat-test-store

> Spec da fatia 2.1 / 2.2 / 2.5 (+ 2.6 UI) do PLANO-MESTRE. SDK contra Test Store. Sem `purchases_ui_flutter`, sem paywall hospedado, sem exportação para galeria (2.3a).

## Status

`Done` (código + testes; prova em device com Test Store fica a cargo do run local)

## Owner / Implementer

- **Spec owner:** Eduardo Rodrigues
- **Implementer:** Cursor
- **Validator:** testes Dart + analyze

## Reading order (pre-flight)

1. Blueprint §2.4
2. ADR-0010 (SKUs, entitlement `premium`, trial 30d copy)
3. PLANO-MESTRE Bloco 2
4. `packages/shared/lib/src/subscription/subscription.dart`
5. Relatório Cowork 2026-09-03 (projeto `proj9ae24c42`)

## Problem

`purchases_flutter ^10.1.1` está no pubspec com zero imports. `subscribe()` grava bool local. Restore é snackbar "Em breve" (bloqueador Apple). Fase 1 do dashboard está pronta (Test Store + entitlement `premium` + offering `default`). Esta fatia liga o SDK sem esperar Play Active / Apple.

## Sizing

- [x] **Medium**

## Q-table

| # | Question | Answer |
|---|----------|--------|
| 1 | Paywall hospedado RevenueCat / `purchases_ui_flutter`? | Não. P09/P10 próprios. Dep nova = ADR. |
| 2 | Fonte de verdade do premium com SDK ligado? | `CustomerInfo.entitlements.active['premium']`. Prefs = cache. |
| 3 | Sem dart-define (CI / teste)? | Não configura. Compra indisponível. Testes usam `FakeBillingGateway`. Nunca fallback para bool grátis. |
| 4 | Key `test_` em release? | Recusar configurar. |
| 5 | Restore no Test Store? | Chamar `restorePurchases` mesmo assim. Se não houver `premium`, copy de vazio — não "Em breve". |
| 6 | App User ID? | Anônimo. Não passar `appUserID`. |
| 7 | Seletor Apple Pay / Google Play no P10? | Remover (2.6). A loja / Test Store abre a folha. |
| 8 | 2.3a galeria do sistema? | Fora. |
| 9 | Keys no git? | Não. `String.fromEnvironment`. Placeholders em `.env.example`. |

## Observable goals

- [x] `Purchases.configure` com key da plataforma quando `REVENUECAT_API_KEY_IOS` / `_ANDROID` não vazias e não `test_` em release
- [x] Checkout compra o package `$rc_monthly` / `$rc_annual` via `Purchases.purchase(PurchaseParams.package)`
- [x] Entitlement `premium` liga `isSubscribed`
- [x] Restore no paywall chama o SDK; cancelamento de compra é silencioso (`PurchasesErrorHelper.getErrorCode`)
- [x] Suíte de testes verde sem rede (fake gateway)
- [x] Zero `purchases_ui_flutter`

## UI / protótipo

- P09 restore deixa de ser "Em breve"
- P10: resumo do plano + CTA; sem rádio de método
- Copy trial 30 dias inalterada

## Out of scope

- MediaStore / PHPhotoLibrary (2.3a)
- Gating de exportação (2.3b)
- Produtos Play/Apple reais, IAP Key, service account
- Termos / Privacidade reais (links seguem "Em breve")
- Voz
- Webhook Firebase
- Customer Center

## Risks

| Risco | Mitigação |
|-------|-----------|
| Key Test Store em loja | Guard de `kReleaseMode` + prefixo `test_` |
| Restore Test Store inerte | Copy honesta de vazio |
| `goog_` sem produtos Play | Documentar: debug usa `test_` nas duas plataformas |
| Keys no relatório Cowork | Não commitar o relatório; não copiar valores para o repo |

## ADRs

- [x] ADR-0010 existente
- [x] ADR novo: não (dep já no pubspec; sem Pigeon)

## References

- https://www.revenuecat.com/docs/getting-started/configuring-sdk
- https://pub.dev/documentation/purchases_flutter/latest/
- memória `raro-pattern-revenuecat-error-handling`
