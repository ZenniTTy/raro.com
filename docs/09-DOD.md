# 09-DOD — Definition of Done (v1.0 release)

> Critérios objetivos para considerar o produto pronto para release. Cópia auditável do [Blueprint Seção 10](Blueprint.md).
>
> **Reauditado em 2026-09-02 (sessão 0039)** contra o código real. Cada marcação abaixo tem evidência; nenhuma foi mantida por estar escrita antes.

## Funcional

- [ ] 100% das 13 telas + 3 modais implementadas e navegáveis — **10/13 telas** (faltam `p05aLockMode`, `p11Terms`, `p12Privacy` — zero referências no código) e **1/3 modais** (M01 ok; M02 Xiaomi e M03 Bluetooth ausentes)
- [x] Nenhuma feature não prevista no Blueprint adicionada
- [x] Wake word `"Raro"` detectado em ambiente silencioso — **Android funciona em foreground E BACKGROUND** (Vosk motor único + FGS `microphone`), confirmado pelo dono no device em 2026-09-02. **Caminho congelado: não mexer.** iOS segue foreground-only (SFSpeech); background iOS sai do escopo de v1.0 (o ONNX foi reprovado na 0029 e a Sensory deixa de ser bloqueador). Métrica formal de ">90%" nunca foi medida em bancada — critério aceito por validação de uso real
- [x] Replay Buffer estável em iOS + Android — **iOS ok; Android Rota D (ADR-0031) provada no M54 (sessão 0043)**: pré-roll no REC, janela 15s/30s recarrega, selo da galeria com formato/lente da sessão. Branch `feat/fatia-5-replay-buffer-android` ainda não mergeada em `develop`. `saveReplay()` standalone sem UI (fora do DoD de produto).
- [ ] Lock mode reduz bateria ≥ 50% — **tela P05a não implementada**
- [ ] App testado em ≥ 1 device Xiaomi/MIUI real — testado no **Galaxy M54** (não-Xiaomi); modal M02 ausente
- [x] i18n completa em pt-BR / en / es — **117 chaves traduzíveis em cada um dos 3 `.arb`**, com teste-guarda `forbidden_ui_literals_test.dart`
- [ ] Free trial 30 dias funcional via RevenueCat — **RevenueCat não integrado**: `purchases_flutter` no pubspec com zero imports
- [ ] Salvar vídeo na galeria exige entitlement `premium` (**regra confirmada pelo dono, 2026-09-02**) — **falta tudo**: (a) `camera_flutter_api_provider.dart:93` salva incondicionalmente, sem checar assinatura; (b) **não existe exportação para a galeria do sistema** — sem `MediaStore`/`PHPhotoLibrary` no repo, o vídeo só vai para o vault privado (`vault_service.dart:12`), que é o que a tela "Galeria" do app lista
- [ ] Restore purchases funcional — `paywall_screen.dart:123` é `_comingSoon`. **Bloqueador de review da Apple**
- [ ] Share e Delete reais — 4 das 5 ações do Preview são snackbar; `vault_service.delete` existe sem caller

## Técnico

- [x] `flutter analyze` zero issues — verificado 2026-09-02
- [ ] `bun run test` tudo verde — **353 passam, 1 FALHA** (`forbidden_ui_literals_test.dart`: 3 literais em `plan_card.dart`, vindos de alteração não commitada)
- [ ] Cobertura: use cases ≥ 80%, repositórios ≥ 70%, widgets críticos ≥ 60% — não medida
- [ ] Builds release `.ipa` + `.aab` com signing correto — **`app-release.apk` está assinado `CN=Android Debug`** (provado via `apksigner`); sem `key.properties`, sem `signingConfigs.release`, sem `ExportOptions.plist`

## Processo

- [x] ADRs 0001–0030 registrados em [docs/decisions/](decisions/)
- [ ] `docs/01-PROJECT.md` até `10-CHANGELOG.md` preenchidos e sem TBD — **`10-CHANGELOG.md` parou no bootstrap v0.1.0**
- [x] Session logs em `docs/sessions/` para cada sessão de trabalho
- [x] Roadmap vigente seguido: PLANO-MESTRE-finalizacao-entrega-cliente.md
- [ ] App aprovado e publicado em App Store + Google Play
- [ ] Tag git `v1.0.0` criada
- [ ] Transferência das contas para o cliente formalizada

---

## Resumo honesto (2026-09-02)

**Pronto:** captura (gravar, focar, galeria interna, preview visual), **voz em background no Android** (congelado, não mexer), i18n 3 idiomas, telemetria Firebase, e paridade Android em tudo **menos replay**.

**Falta para faturar:** integração RevenueCat inteira + **criar a exportação para a galeria do celular** (não existe) e colocá-la atrás do entitlement.

**Falta para publicar:** contas Apple/Google, keystore de release, e a tela de Privacidade.

**Bugs aprovados para correção (dono, 2026-09-02):** replay buffer no Android e modo Volume — implementar, não esconder.
