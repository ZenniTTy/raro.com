# Sessão 0025 — S2.D (parte 1): treino do wake-word "Raro" → modelos ONNX ~92% (RunPod)

**Data:** 2026-06-13
**Branch:** `feat/camera-native-bridge`
**Commits:** `50eec00`…`<este>` (kit Kaggle, guia RunPod, modelos versionados, docs de aprendizado)

---

## Objetivo

Treinar os 2 classificadores de wake-word on-device (`raro_gravar.onnx` + `raro_parar.onnx`) com `livekit-wakeword` 0.2.1 + VoxCPM, validar contra o gate (recall >80% + FP baixo). Pré-requisito da integração iOS (S2.D parte 2).

## Resultado

**Gate PASSOU** com modelos de PROVA (n_samples=2000), validado por `eval` na própria ferramenta:

| Modelo | Recall (limiar ótimo) | FP/hora | Limiar ótimo |
|---|---|---|---|
| `raro_gravar.onnx` | **91,4%** | 0,18 | 0,34 |
| `raro_parar.onnx` | **92,2%** | 0,18 | 0,23 |

Modelos + métricas + README de proveniência versionados em `docs/superpowers/notebooks/modelos-treinados/`. **Lote cheio (15000) NÃO concluído** (cancelado — ver erros). Custo total ~US$6,40.

## Caminho (e onde cada plataforma quebrou)

1. **Kaggle T4 (grátis) — abandonado.** Sequência de travas: célula sem instalação (`command not found`); disco `/kaggle/working` estoura (cota 20GB vs ~17GB de download) → mover tudo p/ `/tmp`; **GPU P100 sorteada é incompatível** com o PyTorch do VoxCPM (sm_60 < sm_70) → `CUDA: no kernel image`; forçar T4 via `--accelerator NvidiaTeslaT4`; e por fim **o run ficou 10h+ "RUNNING" zumbi** (travado, status fantasma da API). Decisão: migrar pra GPU paga.
2. **RunPod (pago) — funcionou.** RTX 5090 (prova) / L40S (tentativa de lote cheio). Controle 100% via API GraphQL + SSH (sem navegador). Prova rápida completou e passou o gate.

## Erros cometidos (registro honesto — pedido do dono)

1. **Estimativas de tempo erradas, repetidas.** Disse "~5h" quando o run real estava em ~10h30 — eu somava "+30min" de cabeça a cada checagem em vez de ler o relógio. **O dono pegou o erro** ("está muito mais de 5h"). Lição: sempre computar `agora - início` a partir de timestamps reais, nunca acumular de memória.
2. **Pedi "deixar rodando" sem detectar que o run estava travado.** O run zumbi do Kaggle ficou horas como "RUNNING" e eu reagendava sem medir progresso. Só ao investigar (lastRunTime parado 8h + GPU 0%) ficou claro que estava morto. Lição: "RUNNING" não é prova de vida — medir delta de log/dados/GPU em 2 pontos no tempo.
3. **Sugeri caminho não-testado para o RunPod (config errada).** O primeiro comando gerado pela pesquisa usava `wake_phrase`/`run --config` — nomes que NÃO batem com o que já provamos (`target_phrases`, `run <config>` posicional). Corrigi reaproveitando o script validado do Kaggle. Lição: reusar o que já provou rodar, não a "versão limpa" inventada.
4. **`set -e` mascarou falha do pip (bug silencioso).** No RunPod o `pip install` falhou com `externally-managed-environment` (PEP 668); o `set -e` matou o script mas o processo "vivo" era só o apt. Lição: `PIP_BREAK_SYSTEM_PACKAGES=1` + `command -v <cli> || exit 1` após o pip pra falhar alto.
5. **Variável `$SSHOPT` quebrou o SSH.** Passar flags via variável fazia o ssh ler tudo como nome do arquivo de identidade → caía pro porto 22 → timeout. Lição: flags ssh sempre DIRETOS no comando.
6. **gitignore dos modelos era bug silencioso latente.** Criei `.gitignore` bloqueando os `.onnx` (raciocínio "prova é descartável, definitivo entra depois"). Mas o lote cheio foi cancelado → os de prova viraram os únicos modelos, e a próxima sessão não os acharia. Corrigido: versionados com README de proveniência.

## Causas-raiz técnicas descobertas (validadas por log/fonte)

- **GPU P100 incompatível com VoxCPM** (sm_60 < sm_70). T4/4090/5090/L40S funcionam. Memória `raro-pattern-kaggle-p100-incompatible-force-t4`.
- **Download HuggingFace pendura por 2 causas independentes:** (a) rate-limit anônimo (sem token → 497s/arquivo, 76h estimadas) → resolve com `HF_TOKEN`; (b) **backend Xet (`hf_xet`) trava a CDN CloudFront** baixando muitos arquivos pequenos (CLOSE-WAIT, trava sempre no mesmo %, MESMO com token; `HF_HUB_DOWNLOAD_TIMEOUT` não corta) → resolve **desinstalando `hf-xet`** (1h30 travado → <1s). Validado em fonte (xet-core #789, hf_hub #4085/#3266). Memória `raro-pattern-wakeword-train-runpod-5090-hf-token`.
- **VoxCPM gera serial e desacelera** (~1→3-4s/clip); 15000×2 comandos = ~6-10h numa T4/L40S. A prova (2000) é o caminho pragmático.

## Por que o lote cheio foi cancelado (decisão do dono)

Aos 60% da geração do 1º comando (9074/15000), velocidade caiu p/ 3-4s/clip → estimativa explodiu p/ +8h, e o saldo RunPod (US$3,69 @ $0,79/h) acabaria antes do fim → seria cortado no meio. Como a prova já passou o gate (~92%), o dono optou por usar os modelos de prova e validar no iPhone primeiro. Pod terminado (custo estancado, saldo US$3,61).

## Estado de saída / próximo passo

- ✅ 2 modelos ONNX (~92%) versionados, válidos, com README de proveniência.
- ✅ Aprendizados em 2 memórias + guia `COMO-TREINAR-runpod-4090.md` (com os 3 fixes) + kit Kaggle.
- ⏭️ **Próxima sessão (S2.D parte 2): integração iOS** — `WakeWordDetector.swift` (carregar o .onnx → `AudioSessionCoordinator` → inferência → disparar gravar/parar). NÃO existe ainda. onnxruntime já integrado (SPM). Fazer com brainstorm → plano → TDD. Gate: detecção "Raro" >80% no iPhone 12 + coexistência voz↔gravação. Se device reprovar → Plano B (lote cheio / +voice_design_prompts 50-100).

**Débito herdado:** gate §10 ffprobe da Frente A (pré-roll combinado). 0 `--no-verify`.
