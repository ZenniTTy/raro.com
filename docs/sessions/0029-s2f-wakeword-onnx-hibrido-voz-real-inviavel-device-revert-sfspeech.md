# 0029 — S2.F: treino híbrido do wake-word "Raro" com voz real → inviável no device → revert pro SFSpeech foreground

- **Data:** 2026-06-21
- **Duração:** ~9h
- **Participantes:** Eduardo Rodrigues + Claude Code (Opus 4.8)
- **Branch:** `feat/camera-native-bridge`
- **Commits:** `f728f14`, `01a1f67`, `7e9c0c9`

## Objetivo

Fechar o domain gap do wake-word toggle "Raro" (modelo 100% sintético da 0028 pontuava a voz real do dono em ~0.08 = silêncio) **injetando a voz real do dono no treino** (livekit-wakeword híbrido), validar no iPhone 12 e, se funcionar, habilitar o background. Decisão de fallback declarada upfront pelo dono: **se não funcionar, voltar pro SFSpeech foreground "raro gravar"/"raro parar" que já funcionava e finalizar o app (iOS + Android)**; background vira melhoria futura.

## Contexto inicial

- 0028 (`e04eb45`) treinou `raro.onnx` toggle único (ADR-0024, com ACAV): eval sintético 81.5%, FPPH 0.0, **mas nunca testado com voz real** (gate de device pendente).
- Cross-model control experiment (S2.E, memória `raro-pattern-cross-model-control-experiment-isolates-domain-gap`) tinha "provado" que o `raro` fraco era domain gap (modelo `parar` reconhecia a voz do dono forte=0.73), apontando p/ treino híbrido como solução.
- Working tree tinha 175 linhas não-commitadas de instrumentação ONNX/background (VoiceManager/AudioSessionCoordinator/AppDelegate) das sessões 0024-0027.

## O que foi feito

- **Processou a gravação do dono** (`~/Downloads/Testes.m4a`, 126s): whisper-cpp PT-BR token-level + segmentação por energia → 40 "Raro" + 31 iscas (caro/barro/faro...). Scripts versionados em `docs/superpowers/notebooks/real-audio/` + README de proveniência.
- **Validou o mecanismo de áudio real na fonte primária** (livekit-wakeword v0.2.1, 2 agentes researcher lendo o código): drop `clip_NNNNNN.wav` 6-dígitos flat ANTES do augment; peso só via **duplicação** (`trainer.py:291` trava positivo em 1.0); test set é degradado pelo augment (não serve de gate limpo); 3 armadilhas de naming que dropam silenciosamente.
- **Releu o Blueprint M03 (L461) ANTES de treinar** — confirmou alvo = toggle "Raro" único, sem drift (aplicou `feedback_reread_blueprint_before_expensive_train`).
- **Rodada v1** (`f728f14`): 120 pos + 93 neg (peso 3x), augmentation `rounds:2`, n_samples 4000. RunPod RTX A4000 ($0.17/h, custo ~$1.15). Treino OK, voz real confirmada nas features (8240,16,96). **Gate offline: PIOROU** (Raro 0.079→0.036, AUC 0.449).
- **Investigação ($0) achou a causa-raiz real:** meu `segment.py` cortou 35/40 clips <0.7s (mediana 0.56s) vs fixtures bons ~0.90s → **treino com áudio truncado** + `rounds:2` degradou o sintético (81%→64%). Re-cortar com janela 0.9s **dobrou o score offline** (provado antes de re-gastar).
- **Rodada v2** (corrigida): clips 0.9s + sem rounds + reais peso 10x/n_samples 1500 (~21% do pool). RunPod RTX 4000 Ada ($0.20/h, custo ~$0.39). Eval sintético voltou a 81.7%. **Gate offline: melhorou mas insuficiente** — AUC 0.327→0.542 (1º modelo > aleatório), melhor "Raro" 0.497, mas 0/41 cruzaram 0.5.
- **Teste no iPhone 12 (gate real, decisão do dono):** build profile assinado + install confirmado (container `67D7D0B1`). Cadeia funcionou (`micOk=true`, `frames flowing`, mic HOT), **mas único pico de score = 0.128 vs limiar 0.35**. Wake-word ONNX "Raro" NÃO dispara na voz real no device.
- **Checkpoint do trabalho ONNX** (`01a1f67`): preservou tudo (WakeWordDetector/Pipeline, AudioSessionCoordinator background, raro.onnx v2, 6 fixtures, docs) antes de reverter — rede de segurança.
- **Revert pro SFSpeech foreground** (`7e9c0c9`): restaurou VoiceManager/AudioSessionCoordinator/AppDelegate/VoiceHostApiImpl ao estado `a43421a` (SFSpeech validado na 0024); removeu 176 linhas de instrumentação de teste; dart analyze limpo; compila (Runner.app 82MB); instalado no iPhone 12 (container `3B931858`). **Dono validou no device: log mostra `wake matched: start` + `wake matched: stop`** — "raro gravar"/"raro parar" voltou a funcionar.

## O que NÃO foi feito (e por quê)

- **Wake-word ONNX em background:** provado inviável no device com a palavra "Raro". Fica dormente (código + modelos preservados no commit `01a1f67`) para retomada futura — NÃO é débito de finalização do app, é feature adiada por decisão de produto.
- **ADR formal do beco ONNX:** o session log + checkpoint documentam; ADR dedicado pode ser aberto se/quando retomar o background (não bloqueia a finalização).
- **Android voice parity + finalização do app (iOS+Android):** próximo grande bloco, declarado pelo dono como o foco depois do revert.
- **Limpar os modelos ONNX dormentes do bundle** (`raro.onnx` v2 + extractors continuam no Resources, não usados pelo SFSpeech): não é bug (não quebra), mantidos de propósito p/ retomar; reavaliar no build de release final.

## Aprendizados / surpresas

- **"4 fixes empilhados ≠ trocar de stack" tem o reverso: 4 MODELOS que falham na voz real = a abordagem É o limite.** gravar/parar/toggle-sint/toggle-híbrido — nenhum dispara "Raro" na voz real. O cross-model experiment da S2.E estava certo sobre o domain gap, mas resolver o domain gap NÃO bastou: a palavra "Raro" (2 sílabas, muitas rimas PT-BR) é foneticamente difícil demais p/ o pipeline openWakeWord separar com qualidade usável.
- **BUG MEU caro: segmentador cortou os "Raro" pela metade** (0.56s vs 0.90s dos fixtures que funcionam). Envenenou treino E medição. Causa-raiz só apareceu ao comparar a duração dos meus clips com os fixtures conhecidos. Lição: ao cortar áudio p/ um pipeline com janela fixa (76 frames ≈ 0.9s), o clip precisa ter ao menos a duração da janela — validar contra um exemplar que sabidamente funciona ANTES de treinar.
- **`augmentation.rounds:2` degrada os positivos sintéticos** (EQ/RIR/ruído borra o sinal): 81%→64% no eval. Não usar rounds alto sem necessidade comprovada; o default (1) é melhor p/ recall.
- **Medir antes de re-gastar funcionou 2x:** re-cortar offline ($0) provou que dobrava o score ANTES de pagar a 2ª rodada; gate offline ($0) sempre rodado antes do device. Evitou queimar GPU no escuro.
- **O gate de verdade é o device, não o offline nem o eval sintético:** offline v2 deu AUC 0.54 (esperançoso), device deu pico 0.128 (pior). CoreML/fp16 no device diverge do CPU offline. Nunca declarar vitória sem o iPhone.
- **Preservar antes de reverter (commit checkpoint) evitou perda irreversível** de 175 linhas + modelos. `git checkout a43421a -- <arquivos>` restaurou o SFSpeech-puro limpo sem deixar instrumentação de teste (que já causou "raro gravar sumiu" antes).
- **RunPod A4000/4000 Ada community ($0.17-0.20/h) >> 5090** p/ esse treino: mais runway no saldo apertado; o gargalo é o generate VoxCPM (CPU-bound, não acelera com GPU melhor). A4000 pode ficar "out of capacity" → fallback p/ 4000 Ada/3090 via API.
- **Custo total da sessão: ~US$1.54 RunPod** (2 rodadas), saldo final $0.33. Ambas as pods terminadas (não Stop), zero cobrança fantasma confirmada via API.

## Próximos passos

- **Validar "raro gravar"/"raro parar" em mais cenários** (telas diferentes, durante gravação) se necessário — base já confirmada no device.
- **Android voice parity:** portar o reconhecimento de voz foreground p/ Android (SpeechRecognizer/CameraX) — backlog Sprint 3.
- **Finalizar o app iOS + Android** com a voz foreground (foco declarado do dono).
- **(Futuro, opcional) Retomar wake-word background:** se voltar, considerar a Rung 4 do ADR-0023 (gate ONNX baixo + 2ª confirmação SFSpeech) OU mudar a wake-word p/ algo menos ambíguo que "Raro" (exigiria ADR contra Blueprint). Código/modelos preservados em `01a1f67`.

## Referências

- Commits: `f728f14` (voz real no treino), `01a1f67` (checkpoint ONNX preservado), `7e9c0c9` (revert SFSpeech)
- Trabalho preservado: `docs/superpowers/notebooks/real-audio/` (213 clips + scripts + README), `RETREINO-raro-hibrido-runbook.md`, `docs/ESTADO-WAKEWORD-RARO.md`, `docs/CONTRAPONTO-ADVERSARIAL-WAKEWORD.md`
- SFSpeech restaurado de: `a43421a` (sessão 0024, validado no device)
- Memórias aplicadas: `feedback_reread_blueprint_before_expensive_train`, `feedback_long_job_monitoring_measure_dont_assume`, `feedback_verify_device_install_before_test`, `raro-pattern-wakeword-train-runpod-5090-hf-token`, `feedback_many_native_fixes_means_reread_logs_not_abandon_framework`
- ADR relacionado: ADR-0024 (toggle "Raro"), ADR-0023 (background audio)
