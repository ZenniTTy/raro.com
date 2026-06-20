# 0024 — Comando de voz: toggle de palavra única "Raro" (NÃO dois comandos "gravar"/"parar")

- **Data:** 2026-06-19
- **Status:** Accepted
- **Relaciona:** **Supersede a cláusula "dois comandos" do [ADR-0022](0022-voice-on-device-sfspeechrecognizer.md) e do [ADR-0023](0023-voice-engine-dedicated-not-sfspeechrecognizer.md)** (ambos diziam "dois comandos 'Raro gravar'/'Raro parar'"). **Restaura e confirma o [ADR-0009](0009-wake-word-raro.md) e o Blueprint M03** (toggle de palavra única). Engine (ONNX/livekit-wakeword) do ADR-0023 permanece válida.
- **Decisores:** Eduardo Rodrigues
- **Contexto:** Sessão de re-treino do wake-word, validação no iPhone 12 físico + confirmação device-validated do app concorrente.

## Contexto — contradição documentada descoberta

Ao validar o re-treino do wake-word, descobriu-se uma **contradição entre fontes autoritativas** do projeto sobre o número de comandos de voz:

| Fonte | O que diz |
|---|---|
| **Blueprint M03** (linha 461) | *"Comando único: dizer 'Raro' inicia OU encerra gravação (toggle)"* |
| **Blueprint P05** (hint da câmera) | *"DIGA 'RARO' PARA GRAVAR"* |
| **ADR-0009** (linha 11) | *"Diga 'Raro' para iniciar ou encerrar sua gravação"* |
| **ADR-0022 / ADR-0023** (linha 57) | *"dois comandos ('Raro gravar'/'Raro parar')"* |

O design **original e autoritativo (Blueprint + ADR-0009) sempre foi um toggle de palavra única "Raro"**. Os ADRs 0022/0023 introduziram "dois comandos" sem sinalizar que contradiziam o Blueprint M03 — um drift não-rastreado. O trabalho de treino (sessão de re-treino) seguiu a versão drifted (dois modelos: `raro_gravar.onnx` / `raro_parar.onnx`).

## Prova de device — por que "dois comandos" é tecnicamente frágil

O re-treino com diversidade de vozes (14→76 `voice_design_prompts`) **resolveu o recall** (o `raro_gravar` saiu de 0/4 para **4/4** na voz real do dono no iPhone 12 — a hipótese diversidade>volume confirmada). Mas o gate de recall offline revelou **cross-fire estrutural** entre os dois comandos:

- `raro_gravar` dispara em clips de **"raro parar"** com scores altos (g=0.81–0.90).
- Os dois classificadores binários **independentes** compartilham o onset "raro" e nenhum foi treinado para ser mutuamente exclusivo com o outro — ambos viram detectores de "raro qualquer-coisa".
- **Prova de que software não salva:** mesmo com decisão por `argmax(g,p)`, o acerto é **5/8** (em vários clips o score da frase errada supera o da certa). Não é problema de limiar nem de ordem — os modelos genuinamente não distinguem o sufixo.

`custom_negative_phrases ["raro parar"]` no config do gravar **não bastou** (frases com prefixo compartilhado são inerentemente difíceis para classificadores binários independentes).

## Prova de mercado (decisiva)

O dono **testou o app concorrente "Ok Câmera" ao vivo no iPhone** (2026-06-19): ele **NÃO tem comandos "gravar"/"parar"** — usa **uma única frase de ativação** ("OK Camera") que **alterna** (liga a gravação quando dito, encerra quando dito de novo). Isto confirma device-validated que o design de **toggle de frase única** é o padrão comprovado em produção para este caso de uso, e que o concorrente evita o cross-fire por construção (não há duas frases competindo). Reforça o teardown anterior (memória `raro-competitor-okcamera-replay-model`: "é toggle").

## Opções consideradas

1. **Toggle de palavra única "Raro" (escolhida).** Alinha com Blueprint M03 + ADR-0009 + concorrente. Elimina o cross-fire por construção (uma frase, sem irmã). Reaproveita o método de treino já validado (ONNX + diversidade reconhece a voz do dono).
2. **Manter dois comandos + re-treino com ACAV + hard-negatives fortes.** Descartada: briga com a arquitetura (prefixo compartilhado), risco residual de cross-fire, custo de 2 modelos, e **contradiz o Blueprint M03**. O ganho (separar gravar/parar) não é requisito do Blueprint — o Blueprint pede toggle.
3. **Multi-classe (1 modelo, saídas gravar/parar/nenhum).** Descartada para v1: melhor solução ML para discriminar comandos, mas exige engenharia fora do fluxo padrão da livekit-wakeword e **resolve um problema que o Blueprint não tem** (o Blueprint não quer dois comandos).

## Decisão

**O comando de voz do RARO é um toggle de palavra única: dizer "Raro" inicia OU encerra a gravação.** NÃO há comandos "gravar"/"parar" separados. Isto restaura o design original do Blueprint M03 e do ADR-0009.

- **Engine:** mantém-se a do ADR-0023 (livekit-wakeword/ONNX on-device, background-capable). Treina-se **um** detector com `target_phrases: ["raro"]`.
- **Modelos `raro_gravar.onnx` / `raro_parar.onnx`** (dois comandos) são **abandonados** como design de produto. O `raro_gravar` treinado nesta rodada fica como **evidência** de que o pipeline ONNX + diversidade reconhece a voz real (transfere para o treino do "Raro").
- **Contrato Pigeon `voice_api`** permanece engine/comando-agnóstico (`onWakeDetected` já é um evento único — encaixa no toggle sem mudança de contrato).
- **UX:** o app mantém estado de gravação visível (REC indicator do P05); um único `onWakeDetected` alterna `recording`↔`idle`.

### Risco aceito — palavra curta em PT-BR

"Raro" é curta (2 sílabas) e o português tem muitas palavras foneticamente próximas (caro, faro, barro, raio…) → **risco de falso-positivo (FP) maior** que uma frase longa. Mitigações obrigatórias (espelhando os parâmetros device-validated do concorrente, memória `raro-competitor-okcamera-android-apk-teardown`):

- Treino **COM ACAV** (negativos genéricos, NÃO `--skip-acav`) — a fronteira "não-é-Raro" precisa ser robusta para escuta contínua em background.
- **Debounce ~2500ms** entre disparos (parâmetro real do concorrente).
- **RMS gate** (~0.026/0.012) para descartar ruído de baixa energia.
- Limiar de score calibrado no gate de device (não no eval sintético — o sintético já enganou: 91% sintético → 0% real numa rodada anterior).
- Beep/feedback no disparo (confirmação ao usuário, reduz repetição).

## Consequências

- **Positivas:** elimina o cross-fire por construção; alinha com o Blueprint original; mais simples (1 modelo, 1 frase); resolve a contradição entre docs; reaproveita o método de treino validado.
- **Negativas:** "Raro" curto exige mitigação de FP cuidadosa (ACAV + debounce + RMS gate); a rodada de re-treino de dois comandos (~US$5) foi gasto que o re-leitura do Blueprint M03 teria evitado — registrado como aprendizado de processo (reler o Blueprint M03 ANTES de treinar).
- **Como reverter:** se o toggle "Raro" único tiver FP inaceitável em background mesmo com mitigações, reavaliar uma frase de ativação mais longa/distintiva (ex: "Raro Câmera") — mas isso seria nova decisão de produto + ADR.

## Implementação (próxima etapa)

- Config de treino: `target_phrases: ["raro"]`, manter os 76 `voice_design_prompts` (diversidade, a correção validada), **sem `--skip-acav`** (ACAV presente para FP robusto), `custom_negative_phrases` com palavras-rima de PT-BR (caro/faro/barro/raio) como negativos.
- Treinar 1 modelo `raro.onnx`, exportar, baixar.
- Re-bundle no app substituindo o par gravar/parar por `raro.onnx` único.
- Gate de device no iPhone 12: recall de "Raro" >80% em silêncio + FP baixo em fala genérica + parâmetros do concorrente (debounce/RMS).
- Atualizar o harness `WakeWordRecallTests` para o modelo único.

## Referências

- [Blueprint M03](../Blueprint.md) (linha 461, toggle "Raro"), [ADR-0009](0009-wake-word-raro.md) (wake word "Raro"), [ADR-0022](0022-voice-on-device-sfspeechrecognizer.md) + [ADR-0023](0023-voice-engine-dedicated-not-sfspeechrecognizer.md) (cláusula "dois comandos" superseded por este ADR)
- Evidência de cross-fire: `WakeWordRecallTests` no iPhone 12 (gravar 4/4 + dispara em parar; argmax 5/8)
- Evidência de mercado: concorrente "Ok Câmera" testado ao vivo no iPhone (toggle de frase única, sem gravar/parar)
- Memórias: `raro-competitor-okcamera-replay-model`, `raro-competitor-okcamera-android-apk-teardown`, `raro-pattern-wakeword-onnx-3stage-pipeline-shapes`, `raro-pattern-wakeword-offline-recall-gate-before-wiring`
