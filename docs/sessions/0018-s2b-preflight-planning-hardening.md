# 0018 — Pré-flight S2.B: auditoria de erros + planning hardening (replay buffer)

- **Data:** 2026-06-04
- **Duração:** ~2h30 (auditoria multi-agente ~22min + síntese + escrita de docs)
- **Participantes:** Eduardo Rodrigues + Claude Code (Opus 4.8)
- **Branch:** `feat/camera-native-bridge`
- **Commits:** a criar via `/commit` (diff docs-only no working tree no fechamento)

## Objetivo

Antes de iniciar a S2.B (replay buffer), o usuário pediu: (1) analisar **todos os erros já cometidos** para que nunca mais aconteçam, conferindo se cada um tem guarda viva; (2) validar se o **plano S2.B** segue boas práticas do harness + práticas 2026 da stack (via Context7/WebSearch/MCPs); (3) garantir **não causar breaking change** com o que já funciona. Sessão read-only de análise, depois aplicar só as pré-condições de docs (aprovadas pelo usuário).

## Contexto inicial

Pós-sessão 0017 (thumbnail real, ADR-0019). S2.A fechada e device-validated (recording `.mov` + vault + galeria + thumbnail no iPhone 12). Próximo entregável previsto = S2.B (replay buffer 15s/30s nativo). O Sprint-2 MD (Task B) propunha `AVAssetWriter` circular coexistindo com o `AVCaptureMovieFileOutput` de G1 — risco já flagado no ADR-0018 como "a validar na Task B".

## O que foi feito

### 1. Auditoria multi-agente (read-only)
Workflow de 4 fases (coleta → pesquisa AVFoundation 2026 → verificação adversarial → síntese). 32 agentes, ~2.2M tokens, 22min. O agente final de síntese bateu no limite de sessão; recuperei os 28 outputs estruturados do `journal.jsonl` do workflow e sintetizei manualmente (nada perdido). Resultados:
- **60 erros** catalogados de session logs + ADRs; **52** de memórias.
- **27 guardas vivas** inventariadas; **10 erros órfãos** (fix no código, sem guarda que impeça reversão).
- **28 issues** levantados no plano S2.B; 22 verificados adversarialmente → **18 confirmados, 1 refutado** (S2B-08 build Android — derrubado em 2 fundamentos).

### 2. Descoberta central (alta confiança, fonte primária)
**`AVCaptureMovieFileOutput` + `AVCaptureVideoDataOutput` NÃO coexistem** na mesma `AVCaptureSession` (iOS 15+, ainda em 2026). Arquitetural, não bug de versão. Evidência: múltiplas threads Apple Dev Forums ("mutually exclusive outputs") + prova de existência da React Native Vision Camera (criou pipeline custom `VideoDataOutput`+`AVAssetWriter` *exatamente porque* "you cannot use MovieFileOutput and a VideoDataOutput delegate at the same time"). Agravante achado no código: `CameraManager.swift:204` anexa o `MovieFileOutput` **incondicionalmente** no `startSession` (permanente, não só ao gravar) → adicionar `VideoDataOutput` para o replay degradaria a gravação G1 já validada. `canAddOutput` dá falso positivo (conflito é de entrega de frames em runtime). Caminho 2026: **um único `VideoDataOutput`+`AVAssetWriter`** serve gravação E replay. `MultiCamSession` descartada (overkill single-cam, não resolve).

### 3. Planning hardening aplicado (docs-only, escopo aprovado)
- **ADR-0020** criado (`docs/decisions/0020-unified-capture-pipeline-videodataoutput.md`) — supersedes ADR-0018; decisão = aposentar `MovieFileOutput`, pipeline unificado `VideoDataOutput`+`AVAssetWriter` para gravação + replay; container `.mp4` real; áudio via `AudioDataOutput`; ring buffer **encoded** (não raw); queue dedicada; `startSession(atSourceTime:)`; save assíncrono.
- **ADR-0018** marcado `Superseded by 0020` (append-only; preserva codec adaptativo + callback async + enum `Codec` como válidos; item 3 `.mov` revertido para `.mp4`).
- **ADR-0003** revisado — implementação iOS original (MovieFileOutput segmentado + array circular de CMSampleBuffer = tecnicamente impossível) marcada inviável e preservada; **Addendum 2026-06-04** com a estratégia real (fragmented MP4 via `didOutputSegmentData` em deque circular; tabela de RAM corrigida raw→encoded; gate `ProcessInfo.thermalState`).
- **Plano S2.B** (`sprint-2-backend-logic-ios.md`) — Task B reescrita: nova **B0** (migrar gravação G1 ao pipeline unificado, pré-requisito), B1 marcado done (ADRs), B2 com contrato Pigeon no `replay_buffer_api.dart` dedicado (não `camera_api.dart`) + `saveReplay` **assíncrono** via callback, B3 exigindo `@riverpod` Notifier reativo, **B-Gate** de device (§10 + ADR-0016). Texto stale corrigido: `bun run --filter` (ordem), `recording_state_provider`→`recording_controller`, disclaimer de drift no topo da Task A (artefato `.mov`, stop async, thumbnail nativo), tabela de Riscos atualizada.
- **Proposta de guardas órfãs** criada (`docs/superpowers/plans/2026-06-04-orphan-guards-hardening.md`) — 10 órfãos (4 alta sev: vault race, ref-after-dispose, Notifier reativo, device gate; 6 média/baixa) + gap estrutural (XCTests nativos não rodam em CI). Documentação, não implementação.

### Verificação anti-alucinação (antes do fechamento)
Cada afirmação carregada nos docs conferida contra código real: `BufferDuration.value` existe em `raro_shared` ✅; canal `com.rarocamera/replay_buffer` em `bridge_channels` ✅; `capturedPipeline.attach` incondicional em `CameraManager.swift:204` ✅; vault usa `.mov` em `vault_service.dart:14` ✅. Diff 100% docs, zero termo proibido, cross-refs bidirecionais (0003↔0020, 0018→0020), invariantes intactos.

## O que NÃO foi feito (e por quê)

- **Zero código nativo/Dart** — escopo travado em "só pré-condições de docs" (decisão do usuário). A implementação da S2.B (migração B0 + ReplayBuffer.swift + provider) é a **próxima sessão**, agora com a planta correta.
- **Guardas órfãs NÃO implementadas** — só documentadas como proposta. Implementar exige sessão própria ou virar sub-tarefa dos testes red-before-green da S2.B. As 4 de alta severidade (vault race, ref-after-dispose, Notifier, device gate) são as que mais ameaçam a S2.B.
- **Gap estrutural não resolvido:** os XCTests nativos (RunnerTests) **não rodam em lefthook/CI** — só manual via `test:ios`. Para a S2.B (100% nativa) isto é o maior buraco de guarda. Decisão de processo pendente com o usuário (entrar no pre-push vs virar passo do `/verify-slice` com evidência).
- **`camera_contract.md` ainda inexistente** — CLAUDE.md §5 pede doc de contrato por bridge; gap pré-existente (apontado já na 0017). O schema Pigeon segue como fonte de fato. Não criado nesta sessão.
- **Android replay** — fora de escopo (Sprint 3); a revisão iOS não o altera.
- **Migração retroativa `.mov`→`.mp4`** — quando a B0 migrar o artefato, vídeos `.mov` antigos não serão convertidos (recomendação: vault novo, sem migração — a decidir na implementação).

## Aprendizados / surpresas

- **O risco "a validar" do ADR-0018 era na verdade um fato decidido.** A pesquisa de fonte primária (não memória de treino) transformou "talvez coexista" em "comprovadamente não coexiste". Validar cedo via docs externas economizou uma sessão inteira de tentativa-e-erro em device.
- **Workflow com schema é robusto a falha do agente final.** O agente de síntese morreu no limite de sessão, mas os 28 outputs estruturados ficaram no `journal.jsonl` do workflow — recuperáveis e suficientes para sintetizar sem repetir o trabalho. Lição de harness: o valor está nos resultados estruturados em cache, não no texto final.
- **A verificação adversarial pegou inflação de severidade.** Vários issues vieram como blocker/major dos revisores mas o verificador cético rebaixou alguns para minor ("forward-looking, não defeito presente") e refutou 1 inteiro. Reportar os 18 confirmados com a severidade corrigida, não os 28 crus, evitou alarme falso.
- **Disciplina de escopo honrada.** Confrontei a ambiguidade de "aprovado" com 2 rodadas de AskUserQuestion antes de tocar arquivo — travou "só docs" + "ADR-0020 supersedes" + "1 entregável". Sem isso, teria inferido escopo e provavelmente começado a codar.

## Próximos passos

- **S2.B implementação** (próxima sessão): executar Task B0 (migrar gravação G1 ao pipeline unificado `VideoDataOutput`+`AVAssetWriter`, ADR-0020) → re-validar G1/preview/foco/lens switch no iPhone 12 → B2 ReplayBuffer.swift (ring encoded) → B3 provider Notifier → B-Gate device. Escrever os testes de regressão dos órfãos 1-2 (vault race, ref-after-dispose) red-before-green na mesma sessão.
- **Decisão de processo:** XCTests nativos no CI (sim/não) + device gate no `/verify-slice` (órfão 4).
- Merge `feat/camera-native-bridge` → develop segue segurado (gates G1-latência/G7/Android/goldens).

## Referências

- ADR-0020: [../decisions/0020-unified-capture-pipeline-videodataoutput.md](../decisions/0020-unified-capture-pipeline-videodataoutput.md)
- ADR-0003 (revisado): [../decisions/0003-replay-buffer-native.md](../decisions/0003-replay-buffer-native.md)
- ADR-0018 (superseded): [../decisions/0018-recording-pipeline-mp4.md](../decisions/0018-recording-pipeline-mp4.md)
- Plano S2.B: [../superpowers/plans/sprint-2-backend-logic-ios.md](../superpowers/plans/sprint-2-backend-logic-ios.md)
- Proposta de guardas: [../superpowers/plans/2026-06-04-orphan-guards-hardening.md](../superpowers/plans/2026-06-04-orphan-guards-hardening.md)
- Sessão anterior: [0017-thumbnail-gallery-avassetimagegenerator.md](0017-thumbnail-gallery-avassetimagegenerator.md)
