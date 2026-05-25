# 01-PROJECT — RARO (Raro Camera)

> Visão de produto e contexto. Fonte primária: [original-briefing.md](briefing/original-briefing.md). Este doc resume e contextualiza.

## Identidade

- **Projeto:** RARO
- **Produto nas lojas:** Raro Camera
- **Bundle ID / Application ID:** `com.rarocamera`
- **Categoria:** Foto e vídeo
- **Versão:** 1.0.0 (build 1)

## O que é

App mobile (iOS + Android) para captura profissional de vídeo com operação **hands-free**. O usuário pode gravar sem tocar no aparelho, usando comando de voz (wake word `"Raro"`) ou botões físicos de volume. O **Raro Replay** captura retroativamente os últimos 15 ou 30 segundos antes do comando — útil para situações em que o "momento certo" passa antes de você reagir.

## Para quem

Pesca, esportes, trilhas, aventuras, trabalho de campo, registro pessoal — qualquer cenário em que manter as mãos livres durante a captura é necessário.

## Posicionamento

- **Inspiração:** app Ok Camera (Felipe Augusto de Melo, App Store v1.3). RARO replica o conceito funcional com base técnica moderna e identidade visual própria.
- **Diferenciação técnica:** implementação robusta de Replay Buffer em código nativo (corrigindo instabilidades observadas no Ok Camera), Flutter cross-platform (vs nativo single-platform), i18n nativa (pt-BR · en · es).

## Modelo comercial

- Assinatura recorrente, **30 dias grátis (free trial)**:
  - **Mensal:** R$ 9,90/mês
  - **Anual:** R$ 89,90/ano (equivale a R$ 7,49/mês — badge "MELHOR OFERTA")
- Sem anúncios, sem marca d'água em vídeos.
- Gate: salvar vídeo na galeria do sistema requer assinatura ativa. O resto do app funciona sem assinatura.

> **Sobre o número 30 dias:** o protótipo mostra "15 dias" em alguns lugares. A decisão executiva do cliente foi de 30 dias — ver [Blueprint Seção 1 divergência #2](Blueprint.md) e [ADR 0010](decisions/0010-dual-subscription-plans.md). O número canônico em código está em `SubscriptionConfig.freeTrialDays = 30`.

## Partes envolvidas

- **Contratado (desenvolvedor):** Elovision Digital LTDA · CNPJ 48.505.584/0001-83 · Ribeirão Preto/SP.
- **Contratante (proprietário do produto):** Vitor Autorino Lopes · Imperatriz/MA.

Após quitação integral do contrato, todos os direitos de propriedade intelectual (código-fonte, assets, configurações, credenciais) são transferidos ao cliente. Todas as contas de serviços (Apple App Store Connect, Google Play Console, Firebase, RevenueCat, GitHub) são criadas e mantidas em nome do cliente.

## Status

- Briefing aprovado em maio/2026.
- Blueprint aprovado em 2026-05-25.
- Bootstrap em execução (fases 1–5 do `bootstrap-mobile-flutter`).

## Próximos marcos

1. Fase 4 (Harness) e Fase 5 (Spec-Driven) do bootstrap.
2. Primeira spec: `feat/camera-native-bridge` — valida pipeline native bridge crítico.
3. Specs subsequentes na ordem do roadmap em [04-ROADMAP.md](04-ROADMAP.md).
