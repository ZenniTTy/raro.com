# Sessão 0028 — Wake-word "Raro" toggle treinado + correção do drift Blueprint (2 comandos → 1 toggle)

- **Data:** 2026-06-19 → 2026-06-20
- **Duração:** ~longa (multi-dia, com gaps reais)
- **Participantes:** Eduardo Rodrigues + Claude Code (Opus 4.8)
- **Branch:** `feat/camera-native-bridge`
- **Commits:** `e04eb45` (1 commit) + push `369970c` (re-treino prep da sessão anterior)

## Objetivo

Continuar do gate de recall da 0027 (gravar 0/4 fraco). Re-treinar o wake-word com a correção identificada (diversidade de vozes), validar no iPhone 12, fazer funcionar em background.

## Contexto

A 0027 deixou: `raro_gravar` reprovado (0/4, máx 0.213) por gap síntese→real; correção mapeada = `voice_design_prompts` 14→80 + `n_samples` 15000 + `custom_negative_phrases`. Configs já editados/commitados ($0). Faltava rodar o treino pago (RunPod) — bloqueado no dono.

## O que foi feito

### Re-treino (RunPod) — método validado
- **Pesquisa de fonte primária (workflow):** provou diversidade>volume (grade VoxCPM dá wrap em `index % n`; 76 prompts = 912 vozes únicas; n_samples acima disso é repetição) → `n_samples=4000` basta. `--skip-acav` seguro p/ iteração (ACAV é classe negativa, não toca recall) mas FP não-confiável → ACAV obrigatório no build final. Cortes seguros: `cfg_values` 4→2, `inference_timesteps` 3→2, `steps` 40k.
- **Rodada gravar/parar (skip-acav):** treinou. **Gate iPhone 12:** `raro_gravar` **4/4** (era 0/4! — diversidade PROVADA, scores 0.68-0.84) mas **cross-fire** (dispara em "parar", g=0.81-0.90). `raro_parar` 0/4 (perde a disputa). **Provado que software não salva:** argmax(g,p) = 5/8 (os 2 modelos detectam "raro qualquer-coisa").
- **Rodada "raro" toggle (COM ACAV):** `raro.onnx` treinado — recall sint 81.5%, **FPPH 0.0** (ACAV deixou a fronteira robusta). Salvo em `modelos-treinados/rodada-0029-raro-toggle-acav/`.

### Descoberta crítica: drift do Blueprint
- O Blueprint M03 (linha 461) + ADR-0009 **sempre** especificaram **toggle de palavra única "Raro"**. Os ADR-0022/0023 introduziram "dois comandos" **contradizendo o Blueprint sem sinalizar** — drift. Treinamos 2 comandos por não reler a fonte.
- Dono **testou o Ok Câmera ao vivo no iPhone**: confirma toggle de frase única (sem gravar/parar).
- **ADR-0024 escrito:** toggle "Raro" único, supersede a cláusula 2-comandos dos ADR-0022/0023, restaura o Blueprint. Config `raro.yaml` (target ["raro"], negativos-rima PT, COM ACAV).

### Documentação do erro (pedido do dono)
- Memória `feedback_reread_blueprint_before_expensive_train` (reler Blueprint + checar drift Blueprint vs ADR antes de gastar GPU; + sub-lições de custo de pod).

## O que NÃO foi feito (débito rastreado)

- **Refatorar `WakeWordDetector`/`WakeWordPipeline` de 2 classifiers → 1 (`raro`) + evento toggle único** — refactor real, adiado p/ próxima sessão (TDD + contexto fresco; evita entropia de refatorar exausto).
- **Gravações reais do dono dizendo só "Raro"** — fixtures atuais são "raro gravar"/"raro parar"; testar o toggle com elas seria bug silencioso. Dono grava 4-6× "Raro" isolado.
- **Re-bundle `raro.onnx` no app** (remover gravar/parar + pbxproj) — junto com o refactor.
- **Gate `WakeWordRecallTests` adaptado no iPhone 12** — depende do refactor + gravações.
- **Wiring background** (single mic owner + RMS gate + debounce 2500ms) — sessão dedicada.
- **[SEGURANÇA] Revogar credenciais expostas no chat** (RunPod API key + HF token) — dono deve revogar; são grátis de recriar.
- Modelos `raro_gravar`/`raro_parar` (2 comandos) **abandonados** como produto (ficam como evidência).

## Aprendizados

- **Reler o Blueprint M03 ANTES de treinar teria evitado ~US$5 + horas** treinando o alvo errado (2 comandos). Contradição Blueprint vs ADR posterior é drift silencioso. Memória nova.
- **Eval sintético mente** (de novo): 91% sint → 0% real na 0027; aqui 81.5% sint = só sinal precoce. Gate = device.
- **Cross-fire de 2 frases com prefixo compartilhado** é estrutural (classificadores binários independentes), não corrigível por threshold/argmax. Toggle de 1 frase elimina por construção (igual concorrente).
- **ACAV importa pro FP:** FPPH 2.08 (skip-acav, parar) vs 0.0 (com acav, raro). Necessário pra background.
- **Custo de pod:** 2 rodadas estouraram saldo no SETUP (download ACAV 16GB + pod ociosa ~8h entre setup e treino). Fixes: kill-switch `persistent` (sem gap de timeout), START treino logo após setup, gatilho `.onnx`-pronto → terminate na hora, pod sem SSH em 5min = zumbi RunPod (validado em fonte) → matar e re-deployar.
- **Erro de segurança:** facilitei o dono colar API key + HF token no chat (deveria ter insistido no caminho seguro). Ambas a revogar.

## Próximos passos (próxima sessão)

1. Dono grava 4-6× "Raro" isolado (fixtures).
2. Refatorar `WakeWordDetector`/`WakeWordPipeline` → 1 modelo `raro` + evento toggle único (app alterna estado). TDD red-before-green.
3. Re-bundle `raro.onnx` (remover gravar/parar do Resources + pbxproj).
4. Gate `WakeWordRecallTests` adaptado no iPhone 12 (recall "Raro" + FP + params concorrente debounce 2500ms/RMS).
5. Se passar: wiring background (sessão dedicada). Se FP alto: reavaliar frase mais longa (novo ADR).
6. **Revogar** RunPod API key + HF token.

## Estado do saldo RunPod

US$ 2,20 (terminada a pod a tempo via gatilho `.onnx`-pronto). Suficiente para 1 iteração curta, não para nova rodada com ACAV (carregar antes).
