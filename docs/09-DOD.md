# 09-DOD — Definition of Done (v1.0 release)

> Critérios objetivos para considerar o produto pronto para release. Cópia auditável do [Blueprint Seção 10](Blueprint.md).

## Funcional

- [ ] 100% das 13 telas + 3 modais implementadas e navegáveis
- [ ] Nenhuma feature não prevista no Blueprint adicionada
- [ ] Wake word `"Raro"` detectado com taxa > 90% em ambiente silencioso
- [ ] Replay Buffer estável em iOS + Android (sem perda de frames, sem crashes)
- [ ] Lock mode reduz consumo de bateria medido em ≥ 50% vs tela acesa
- [ ] App testado em ≥ 1 device Xiaomi/MIUI real
- [ ] i18n completa em pt-BR / en / es (todas strings em `.arb`)
- [ ] Free trial 30 dias confirmado funcional via RevenueCat
- [ ] Salvar vídeo exige entitlement `premium` ativo

## Técnico

- [ ] `bun run lint` (turbo) zero issues em todos workspaces
- [ ] `bun run typecheck` (turbo) zero issues
- [ ] `bun run test` (turbo) tudo verde
- [ ] Cobertura: use cases ≥ 80%, repositórios ≥ 70%, widgets críticos ≥ 60%
- [ ] Builds release `.ipa` + `.aab` com signing correto

## Processo

- [ ] ADRs 0001–0012 registrados em [docs/decisions/](decisions/)
- [ ] `docs/01-PROJECT.md` até `10-CHANGELOG.md` preenchidos e sem TBD
- [ ] Session logs em `docs/sessions/` para cada sessão de trabalho
- [ ] App aprovado e publicado em App Store + Google Play
- [ ] Tag git `v1.0.0` criada
- [ ] Transferência das contas para o cliente formalizada
