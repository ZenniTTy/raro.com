# 0004 — Arquitetura client-only (sem backend próprio)

- **Data:** 2026-05-25
- **Status:** Accepted
- **Decisores:** Eduardo Rodrigues, Vitor Lopes
- **Contexto:** Briefing Seção 6.5

## Contexto

A v1.0 precisa de assinaturas, analytics, reconhecimento de voz, captura de vídeo e gestão de galeria. Cada um desses pode ser resolvido com SDK gerenciado ou exigir backend próprio.

## Opções consideradas

1. **Client-only com SDKs gerenciados**
   - RevenueCat para assinatura (servidor próprio do RevenueCat valida receipts)
   - Firebase para analytics + crashes
   - Speech on-device para wake word
   - Vídeos ficam no device
   - Prós: zero infra a manter, custo previsível, foco no app.
   - Contras: dependência de SDKs externos.
2. **Backend próprio (Fastify + Postgres)**
   - Prós: controle total, multi-device sync se quiser, dados próprios.
   - Contras: hosting + manutenção + IaC + security a manter, escopo explode.

## Decisão

**Opção 1.** Razões objetivas:
- App é primariamente captura local, não há valor em sync server-side
- Vídeos não devem fazer upload (privacidade, custo de storage)
- RevenueCat resolve receipts/webhooks/state sync corretamente
- Cliente quer custo operacional zero

**Implicação no monorepo:** sem `apps/api`, sem `packages/prisma`, sem Docker Compose Postgres. Estrutura final:

```
raro/
├── apps/mobile/
└── packages/shared/
```

## Consequências

- **Positivas:**
  - Custo operacional: ~$0/mês (Firebase Spark + RevenueCat free tier durante MVP)
  - Sem responsabilidade de uptime de backend próprio
  - Privacidade do usuário preservada (vídeos não saem do device)
- **Negativas:**
  - Sync entre devices é impossível (não é caso de uso da v1.0)
  - Dependência forte de RevenueCat e Firebase
  - Migração futura para backend próprio exige re-arquitetura
- **Como reverter:** se backend próprio for justificado em v2.0, novo ADR + spec

## Referências

- [Blueprint Seção 2.5](../Blueprint.md)
- [02-ARCHITECTURE.md](../02-ARCHITECTURE.md)
