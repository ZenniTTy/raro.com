# 09-DOD — Definition of Done (v1.0 release)

> Critérios objetivos para considerar o produto pronto para release. Cópia auditável do [Blueprint Seção 10](Blueprint.md).

## Funcional

- [ ] 100% das 13 telas + 3 modais implementadas e navegáveis
- [ ] Nenhuma feature não prevista no Blueprint adicionada
- [ ] Wake word `"Raro"` detectado com taxa > 90% em ambiente silencioso **[⚠️ FOREGROUND apenas; background STANDBY/inviável-ONNX, sessão 0029, aguarda Sensory — DECISÃO DE PRODUTO ABERTA]**
- [ ] Replay Buffer estável em iOS + Android (sem perda de frames, sem crashes) **[Android não compila ainda]**
- [ ] Lock mode reduz consumo de bateria medido em ≥ 50% vs tela acesa
- [ ] App testado em ≥ 1 device Xiaomi/MIUI real
- [ ] i18n completa em pt-BR / en / es (todas strings em `.arb`) **[0 arquivos .arb, Bloco 4.6]**
- [ ] Free trial 30 dias confirmado funcional via RevenueCat **[RevenueCat=mock, Bloco 2]**
- [ ] Salvar vídeo exige entitlement `premium` ativo

## Técnico

- [ ] `bun run lint` (turbo) zero issues em todos workspaces
- [ ] `bun run typecheck` (turbo) zero issues
- [ ] `bun run test` (turbo) tudo verde
- [ ] Cobertura: use cases ≥ 80%, repositórios ≥ 70%, widgets críticos ≥ 60%
- [ ] Builds release `.ipa` + `.aab` com signing correto

## Processo

- [ ] ADRs 0001–0024 registrados em [docs/decisions/](decisions/)
- [ ] `docs/01-PROJECT.md` até `10-CHANGELOG.md` preenchidos e sem TBD
- [ ] Session logs em `docs/sessions/` para cada sessão de trabalho
- [ ] Roadmap vigente seguido: PLANO-MESTRE-finalizacao-entrega-cliente.md
- [ ] App aprovado e publicado em App Store + Google Play
- [ ] Tag git `v1.0.0` criada
- [ ] Transferência das contas para o cliente formalizada
