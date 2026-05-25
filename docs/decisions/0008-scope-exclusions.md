# 0008 — Itens explicitamente fora do escopo v1.0

- **Data:** 2026-05-25
- **Status:** Accepted
- **Decisores:** Eduardo Rodrigues, Vitor Lopes
- **Contexto:** Briefing Seção 5.6 + Blueprint Seção 1

## Contexto

Durante refinamento do briefing, várias features foram cogitadas mas descartadas após análise técnica e comercial. Este ADR consolida os descartes para evitar re-discussão futura.

## Decisão

### 1. Controle Bluetooth customizado (pareamento próprio)

- **Motivo:** ausente no Ok Camera; iOS restringe captura de eventos de hardware externo; comando de voz cobre o mesmo caso de uso.
- **Substituto:** controle por botões físicos de volume (ADR 0011), que aceita fones BT que reportam como volume.

### 2. Tradução automática / legendas em tempo real via API externa

- **Motivo:** custo operacional recorrente alto (USD 10–60/milhão de chars). Incompatível com modelo de assinatura única R$ 9,90/mês.
- **Status no protótipo:** existe código `screenTranslation()` mas não está em `registerScreens()` nem navegável. Tratado como código morto.
- **Reabertura:** se modelo comercial mudar para tier premium ou pay-per-use, novo ADR.

### 3. Modo de economia de bateria com perfis por fabricante

- **Motivo:** exige testes em 15–20 devices físicos distintos. Inviável.
- **Substituto:** Lock mode (ADR 0007).

## Consequências

- **Positivas:**
  - Escopo da v1.0 fica concreto e auditável
  - Decisões registradas evitam scope creep
- **Negativas:**
  - Se cliente pedir qualquer um dos 3 durante o desenvolvimento, exige novo ADR + cláusula 11 do contrato
- **Como reverter:** ADRs específicos por feature

## Referências

- [0007-lock-mode-vs-battery-profile.md](0007-lock-mode-vs-battery-profile.md)
- [0011-volume-control-not-bluetooth.md](0011-volume-control-not-bluetooth.md)
