# Prompt de abertura — próxima sessão (Bloco 0: destravar e estabilizar)

> Cole o bloco abaixo como primeira mensagem da próxima sessão. Ele assume que o `reinject-roadmap.sh` (SessionStart) já injeta o estado atual; por isso o prompt **aponta** para as fontes em vez de repetir tudo.
>
> **Vigente desde:** 2026-06-22 (pós-reconciliação do harness, commit `92fd715`).
> **Substitui:** `NEXT-SESSION-PROMPT-voice-openwakeword.md` (OBSOLETO — não usar, reabriria o beco ONNX já provado inviável na 0029).

---

## PROMPT (copiar a partir daqui)

```
/prime

Contexto: a sessão passada (0029 + reconciliação de harness, commit 92fd715) fechou a
saga do wake-word. Estado autoritativo: wake-word "Raro" foreground SFSpeech
("raro gravar"/"raro parar") FUNCIONA no iPhone 12; background ONNX está INVIÁVEL e em
STANDBY (dono negociando licença Sensory) — NÃO reabrir treino ONNX/OpenWakeWord sem ADR.
O roadmap vigente é docs/superpowers/plans/PLANO-MESTRE-finalizacao-entrega-cliente.md
(6 blocos, alvo = iOS+Android paridade total → publicação nas 2 lojas).

Entregável desta sessão (1 sessão = 1 entregável fechado): BLOCO 0 do PLANO-MESTRE —
destravar e estabilizar. Em ordem:
  0.1  Destravar build Android: implementar startRecording/stopRecording em
       apps/mobile/android/.../CameraHostApiImpl.kt (o CameraApi.g.kt regen 2026-06-07
       exige; flutter build appbundle falha hoje). Stub que lança
       UnsupportedOperationException (espelhando o que o iOS faz com replay) é aceitável
       AGORA — a impl real de gravação é o Bloco 3.1. Critério: `flutter build appbundle`
       passa.
  0.2  Wake-word ONNX órfão: remover raro.onnx + 3 Swift do bundle de produção (peso
       morto, preservado no commit 01a1f67) OU manter dormente com nota. Recomendação do
       plano: remover do bundle.
  0.3  App ID Android divergente (com.rarocamera.raro_mobile vs com.rarocamera do iOS) —
       decisão IMUTÁVEL pós-publicação. Alinhar gradle ↔ Blueprint ↔ Play Console.
       Esta é decisão de produto: PERGUNTE ao dono qual App ID final antes de mudar.
  0.4  android:label "raro_mobile" → "Raro Camera".

Antes de tocar código: leia o Bloco 0 completo no PLANO-MESTRE e confirme o estado real
do CameraHostApiImpl.kt vs CameraApi.g.kt (não confie no doc — verifique o arquivo).
0.3 mexe em App ID = decisão imutável + toca gradle/Blueprint: trate como gate
(pergunte ao dono, não infira). 0.1 toca Pigeon/native bridge = o hook warn-adr-drift vai
avisar; avalie se precisa de ADR.

Boas práticas que NÃO podem ser repetidas (memórias):
  - feedback_synthetic_eval_is_not_the_gate_device_is — só device decide, não eval.
  - feedback_verify_device_install_before_test — confirmar "App installed" antes de pedir teste.
  - feedback_ios_workflow_terminal_first_no_xcode_build — build sempre via terminal/bun.
  - raro-pattern-bun-filter-arg-order — `bun run --filter '@raro/mobile' <script>`.

Fecho a sessão com /session-end.
```

---

## Por que este prompt é assim (notas para mim mesmo, não colar)

- **Começa com `/prime`** porque a regra do workflow (CLAUDE.md §6) é toda sessão começar com prime + audit do Sprint MD vigente.
- **Não repete o estado inteiro** porque o hook `reinject-roadmap.sh` já injeta (voz standby, mocks, Android quebrado) no SessionStart. Repetir = risco de drift se um dos dois mudar.
- **Declara 1 entregável fechado upfront** (Bloco 0) — regra não-negociável do workflow.
- **Marca 0.3 como gate de decisão do dono** — App ID é imutável pós-publicação; inferir seria o anti-pattern "never silently assume".
- **Lista só as 4 memórias de maior risco de reincidência** neste bloco específico, não todas — as outras o `/prime` e o recall trazem sob demanda.
- **Aponta o prompt obsoleto** para que ninguém o use por engano.
