# 0030 — Reconciliação completa do harness + PLANO-MESTRE de finalização até entrega

- **Data:** 2026-06-22
- **Duração:** ~4h
- **Participantes:** Eduardo Rodrigues + Claude Code (Opus 4.8)
- **Branch:** `feat/camera-native-bridge`
- **Commits:** `6762312`, `92fd715` (+ `NEXT-SESSION-PROMPT-bloco-0-destravar.md` a commitar)

## Objetivo

Pedido do dono, verbatim: *"Coloque como prioridade atualizar todo harness desatualizado, tudo o que estiver fora desse roadmap atual deve ser atualizado para nao conflitar conhecimento nas proximas sessoes. Foque em documentar, atualizar e mapear tudo que for necessario para que as proximas sessoes tenham contexto completo do que foi definido e o que deve ser feito!"*

Em uma frase: **alinhar TODA a documentação/harness ao estado real do código**, para que nenhuma sessão futura (humana ou IA) leia algo falso e tome decisão errada. Modo escolhido pelo dono: *"Auditoria completa + relatorio antes de corrigir"* → depois *"Sim, corrigir tudo (criticos + altos + medios + 8 licoes)"*.

## Contexto inicial

A 0029 fechou a saga do wake-word: 4 modelos ONNX falharam o gate de device com a voz real → background ONNX declarado **inviável** e revertido pro **SFSpeech foreground** ("raro gravar"/"raro parar", que funciona no iPhone 12). Mas os docs do projeto estavam **otimistas demais e contraditórios**: sprints marcavam RevenueCat/Firebase/i18n como "feitos" quando eram mock/ausentes; o prompt de next-session apontava pro beco do OpenWakeWord; o hook de SessionStart listava 6 hooks (eram 11) e não injetava o estado real; o Android nem compila e nenhum doc-índice sinalizava isso. Esse drift envenenaria toda sessão futura.

Tratamento do wake-word definido pelo dono nesta sessão: *"Marcar como inviavel, e mapear todos os erros cometidos que nao foram mapeados. Deixar em standby o background pois eu estou conversando com a Sensory para obter a licenca deles."* — background é **STANDBY** (não morto), porque o dono negocia licença Sensory.

## O que foi feito

**Auditoria (3 agentes paralelos sobre CÓDIGO REAL, não docs):** revelou ~14 drifts crítico/alto/médio + 8 erros/lições ainda não mapeados. Achados-chave: RevenueCat = mock total (`subscribe()` só seta bool; `purchases_flutter` 0 usos), Firebase nunca inicializado (`main.dart` sem `initializeApp` → crasharia em release), Share = botão "Em breve", i18n = 0 `.arb`, Android não compila (`CameraHostApiImpl.kt` não implementa `startRecording`/`stopRecording` que o `CameraApi.g.kt` regen exige).

**PLANO-MESTRE criado (`6762312`):** [docs/superpowers/plans/PLANO-MESTRE-finalizacao-entrega-cliente.md](../superpowers/plans/PLANO-MESTRE-finalizacao-entrega-cliente.md) — 6 blocos sequenciados (0 destravar/Android build; 1 Firebase/Crashlytics; 2 RevenueCat real; 3 Android paridade total; 4 acabamentos i18n/share/telas; 5 infra de loja + publicação). Alvo de entrega (decisão do dono): **iOS + Android paridade total → publicação nas 2 lojas**. É o índice sequenciado que reconcilia o drift entre os sprints existentes e a realidade.

**Reconciliação do harness — 29 arquivos (`92fd715`):**
- **CLAUDE.md / AGENTS.md / Blueprint §2.3/§3.3/§10 / 09-DOD / 05-FEATURES / 06 / 07 / 01-04 / 08 / index:** notas de estado real, wake-word→standby Sensory, mocks marcados, contagem de ADRs/hooks corrigida, ordem de comando `bun run --filter`.
- **sprints 1-3 + PROMPTS:** banners de estado por agente (done-com-drift, reindexado pelo PLANO-MESTRE).
- **Docs perigosos marcados:** `NEXT-SESSION-PROMPT-voice-openwakeword.md` → OBSOLETO; `ESTADO-WAKEWORD-RARO.md` → SUPERSEDED; `CONTRAPONTO-ADVERSARIAL-WAKEWORD.md` → REFUTADO (todos reabririam o beco ONNX).
- **Hooks:** `reinject-roadmap.sh` inventário 6→11 + bloco ESTADO ATUAL (voz standby, mocks, Android quebrado) + PLANO-MESTRE na ordem de leitura; `warn-adr-drift.sh` ganhou paths sensíveis de voz (`*.onnx`, `Native/Voice/*.swift`, `configs/*.yaml`).
- **CHANGELOG:** 0.7.0 (saga wake-word) + 0.7.1 (reconciliação).

**Lições salvas em memória (8 mapeadas; 3 viraram arquivo/addendum):**
- `feedback_audio_clip_must_meet_fixed_window_before_train` (corte 0.56s vs janela 0.9s envenenou treino pago).
- `feedback_synthetic_eval_is_not_the_gate_device_is` (eval sintético mentiu 3×; só device decide).
- addendum em `feedback_many_native_fixes_means_reread_logs_not_abandon_framework` (REVERSO: N modelos INDEPENDENTES reprovando o mesmo gate = aceitar o teto).
- MEMORY.md atualizado e encurtado.

**Prompt de abertura da próxima sessão criado:** [NEXT-SESSION-PROMPT-bloco-0-destravar.md](NEXT-SESSION-PROMPT-bloco-0-destravar.md) — aponta pro Bloco 0 (destravar Android), declara 1 entregável fechado, marca App ID como gate de decisão do dono, lista as 4 memórias de maior risco de reincidência. Substitui o prompt obsoleto de voz.

## O que NÃO foi feito (e por quê)

- **Nenhuma linha de código de produção tocada** — por design. O pedido era harness/docs; o código fica para os blocos do PLANO-MESTRE.
- **Bloco 0.1 (destravar build Android) NÃO iniciado** — é a próxima sessão, não esta. O dono autorizou só a reconciliação do harness.
- **Nenhuma pendência de segurança de credenciais documentada** — instrução explícita do dono, verbatim: *"Deixe como esta. Nao documente nada de pendencia de segurança das tokens."* Memória de credenciais foi deliberadamente excluída e tokens deixados como estão.
- **MEMORY.md ainda ~812b acima do limite soft** (problema pré-existente desta sessão, era 25.8KB; encurtado para ~25.2KB). Aviso soft, não bloqueante; revisitar quando houver folga.

## Aprendizados / surpresas

- **Auditar código real > confiar em docs:** os 3 agentes acharam que sprints "verdes" escondiam mock/ausência. A fonte de verdade é sempre o arquivo, nunca o doc que diz que o arquivo está pronto.
- **Drift de doc é dívida ativa, não passiva:** um prompt de next-session apontando pro beco do OpenWakeWord teria custado outra rodada cara. Marcar docs perigosos como OBSOLETO/SUPERSEDED é parte da entrega.
- **O hook de SessionStart é o ponto de maior alavancagem:** corrigir o `reinject-roadmap.sh` propaga o estado certo para TODA sessão futura de graça. Vale mais que corrigir 10 docs lidos sob demanda.
- **N modelos independentes ≠ N fixes do mesmo bug:** a regra "muitos fixes = re-ler log, não abandonar stack" tem um reverso legítimo — N artefatos independentes reprovando o mesmo gate de aceite É o teto. Critério de desempate agora documentado.

## Próximos passos

- **[PRÓXIMA SESSÃO] Bloco 0 do PLANO-MESTRE:** destravar e estabilizar.
  - 0.1 Implementar `startRecording`/`stopRecording` no `CameraHostApiImpl.kt` (stub `UnsupportedOperationException` aceitável agora; impl real é o Bloco 3.1). Critério: `flutter build appbundle` passa.
  - 0.2 Decidir wake-word ONNX órfão (remover `raro.onnx` + 3 Swift do bundle, preservado em `01a1f67`).
  - 0.3 **[GATE — perguntar ao dono]** App ID Android divergente (`com.rarocamera.raro_mobile` vs `com.rarocamera`) — decisão imutável pós-publicação.
  - 0.4 `android:label` → "Raro Camera".
- Usar [NEXT-SESSION-PROMPT-bloco-0-destravar.md](NEXT-SESSION-PROMPT-bloco-0-destravar.md), **não** o de voz (obsoleto).
- **Decisão de produto aberta (dono):** wake-word background = foreground-only vs aguardar Sensory vs trocar a palavra.

## Referências

- Plan: [PLANO-MESTRE-finalizacao-entrega-cliente.md](../superpowers/plans/PLANO-MESTRE-finalizacao-entrega-cliente.md) (criado)
- ADRs: nenhum criado; ADR-0022/0023/0024 ganharam notas append-only de standby/vigência na 0029
- Memórias: `feedback_audio_clip_must_meet_fixed_window_before_train`, `feedback_synthetic_eval_is_not_the_gate_device_is` (novas); addendum em `feedback_many_native_fixes_means_reread_logs_not_abandon_framework`
- Commits: `6762312` (PLANO-MESTRE), `92fd715` (reconciliação 29 arquivos)
- Sessão anterior: [0029](0029-s2f-wakeword-onnx-hibrido-voz-real-inviavel-device-revert-sfspeech.md)
