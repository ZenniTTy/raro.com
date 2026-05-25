# 0007 — Lock mode substitui perfil de economia de bateria por fabricante

- **Data:** 2026-05-25
- **Status:** Accepted
- **Decisores:** Eduardo Rodrigues, Vitor Lopes
- **Contexto:** Briefing Seção 5.6

## Contexto

Gravações longas (pesca, trilha, esportes) drenam bateria rapidamente. Briefing originalmente cogitou "modo de economia de bateria com perfis por fabricante" (Xiaomi, Samsung, Oppo, etc.), mas isso exigiria testes em 15–20 dispositivos físicos distintos. Inviável no orçamento.

## Opções consideradas

1. **Perfis por fabricante** (descartado)
2. **Lock mode** (escurece tela durante gravação, mantém foreground)
3. **Background recording**
   - Não permitido pela Apple para apps de terceiros
   - Android exige permissões adicionais e ainda é killado por MIUI/OneUI

## Decisão

**Opção 2 — Lock mode.** Cobre a principal fonte de drenagem (display ligado em brilho máximo) sem precisar lidar com restrições de cada fabricante.

Implementação:
- Tela P05a totalmente preta, brilho mínimo via API nativa
- REC dot pulsante + timer mirror
- Double-tap pra sair
- App permanece em foreground como processo ativo (não é background)

## Consequências

- **Positivas:**
  - Reduz consumo de bateria em ≥ 50% vs tela acesa (alvo do DoD)
  - Não exige device-specific testing
  - Funciona em iOS + Android igual
- **Negativas:**
  - Usuário precisa lembrar de ativar
  - Em devices muito agressivos (MIUI), ainda exige onboarding Xiaomi (ADR 0012)
- **Como reverter:** v2.0 pode investigar perfis se tivermos orçamento de QA

## Referências

- [Blueprint Seção 6 M07](../Blueprint.md)
- [0012-xiaomi-onboarding-hybrid.md](0012-xiaomi-onboarding-hybrid.md)
