# 0010 — Modelo de assinatura dual (mensal + anual)

- **Data:** 2026-05-25
- **Status:** Accepted
- **Decisores:** Eduardo Rodrigues, Vitor Lopes
- **Contexto:** Divergência #3 entre briefing e protótipo (Blueprint Seção 1)

## Contexto

O briefing original (Seção 5.3) declarava apenas plano mensal R$ 9,90. O protótipo (paywall P09) mostra **dois cards lado a lado**:
- Mensal: R$ 9,90/mês
- Anual: R$ 89,90/ano (equivalente R$ 7,49/mês) com badge "MELHOR OFERTA"

## Decisão

**Implementar ambos os planos.** Protótipo prevalece (Seção 3.2).

| SKU RevenueCat | Período | Preço | Equivalente mensal |
|---|---|---|---|
| `raro_premium_monthly_BRL_9_90` | 1 mês | R$ 9,90 | R$ 9,90 |
| `raro_premium_yearly_BRL_89_90` | 12 meses | R$ 89,90 | R$ 7,49 |

Entitlement único: `premium`.

Free trial: **30 dias** em ambos (ADR registra valor ≠ protótipo que diz 15d; ver Blueprint Seção 1 Divergência #2).

UI:
- Card mensal selecionado por padrão (`appState.plan = 'monthly'`)
- Card anual com badge "MELHOR OFERTA" rosa pink (#ff2d55)
- Toggle entre os 2 muda o gradient do border (active vs inactive)

## Consequências

- **Positivas:**
  - LTV maior no anual (R$ 89,90 vs R$ 118,80 do mensal completo)
  - Cliente que opta pelo anual reduz churn risk
  - Sem complexidade adicional no RevenueCat (2 SKUs no mesmo entitlement)
- **Negativas:**
  - Receita do mês 1 é menor no anual (até o trial acabar)
  - Cliente precisa configurar 2 produtos em App Store Connect + Play Console
- **Como reverter:** desabilitar SKU anual no RevenueCat (o código do paywall suporta os 2; só remove o card)

## Referências

- [Blueprint Seção 1 — Divergência #3](../Blueprint.md)
- [packages/shared/lib/src/constants/subscription.dart](../../packages/shared/lib/src/constants/subscription.dart)
