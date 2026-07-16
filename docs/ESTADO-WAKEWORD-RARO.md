# Estado Completo do Wake-Word "Raro" — Diagnóstico, Tentativas e Caminho

> # 🛑 SUPERSEDED — desfecho na sessão 0029 (2026-06-21)
> Este doc (de 2026-06-20) recomendava o **treino híbrido com voz real** como "o caminho nunca tentado". A sessão 0029 **executou exatamente isso e provou inviável**: treinou o modelo híbrido com a voz real do dono e, no iPhone 12, "Raro" não dispara (pico 0.128 vs limiar usável; AUC máx 0.54). **Conclusão revisada:** a palavra "Raro" é o limite do pipeline openWakeWord, não a falta de voz real. O app **reverteu para SFSpeech foreground** (commit `7e9c0c9`); background = **STANDBY aguardando licença Sensory**. Verdade atual: session log `docs/sessions/0029-*.md` + ADR-0023 (Atualização 2026-06-21) + `PLANO-MESTRE-finalizacao-entrega-cliente.md`. **Este doc fica como histórico do diagnóstico até a 0029.**
>
> **Documento-mestre** do problema de wake-word de voz do RARO. Criado em 2026-06-20 (sessão S2.E) a pedido do dono, reescrito após auditoria EXAUSTIVA de todas as sessões (0023–0028), ADRs (0009/0022/0023/0024) e 13 memórias.
>
> **Regra deste documento:** tudo aqui é factual e rastreável a log/doc/sessão. Nada de suposição apresentada como fato. Onde algo é hipótese ou não-testado, está marcado como tal. Sem drift: o objetivo abaixo é o do Blueprint, não uma reinterpretação.

---

## 1. O OBJETIVO FINAL (o que queremos — fonte: Blueprint M03 + ADR-0009/0024)

**O usuário fala "Raro" UMA vez e o app começa a gravar. Fala "Raro" de novo e para.** Um único comando que alterna (toggle), funcionando inclusive com **o app fechado / tela bloqueada** (background), igual o concorrente "Ok Câmera".

- **Wake word:** `"Raro"` — toggle único (NÃO dois comandos "gravar"/"parar"; isso foi um drift, ver §6).
- **Caso de uso real:** pescaria/esporte com o telefone guardado no bolso, tela travada, mãos ocupadas.
- **Engine:** própria, **grátis** (ONNX Runtime + modelo livekit-wakeword). As pagas inviabilizam o preço de R$ 9,90/mês.
- **Plataforma desta fase:** iOS (iPhone 12). Android = Sprint 3.

---

## 2. ✅ O QUE JÁ FUNCIONA (provado no device — não regredir)

Esta é a parte difícil do projeto, e está **feita e provada**:

| Componente | Estado | Prova / Fonte |
|---|---|---|
| **Pipeline ONNX 3 estágios** (mel → embedding → classifier) | ✅ Funciona | Sessão 0027: 9 testes verdes no iPhone 12; shapes validados ponta a ponta |
| **Feature-extractors versionados** (mel + embedding) | ✅ Corrigido | 0026: extraídos do `pip download livekit-wakeword==0.2.1` (a 0025 esquecera) |
| **Captura de áudio dedicada** (`AudioSessionCoordinator`, separada da câmera) | ✅ Funciona | S2.E: refatorado e ligado; mic 16kHz mono |
| **Mic em BACKGROUND + tela travada** | ✅ **PROVADO** | S2.E: RMS pós-lock `HAS-CONTENT` (energia real do áudio em background, peak 0.13–0.91 com fala) |
| **Detector ONNX rodando em background** | ✅ **PROVADO** | S2.E: `AppleNeuralEngine ANEProgramProcessRequestDirect status=0x0` em background com tela travada |
| **Mic-only sobrevive ao background** (probe 0024) | ✅ Provado 2× | 0024: probe heartbeat 50→600 frames, 7 batimentos em background, zero suspensão |
| **Cadeia wake → ação** (onWake → toggle → onCommand → Flutter) | ✅ Ligada | S2.E: código verificado; dispararia a gravação se o score passasse o threshold |
| **`UIBackgroundModes: audio` + permissão de mic** | ✅ Configurado | Idêntico ao concorrente (extraído do iPhone: `fmdev.okcamera` usa só `audio`, zero entitlement especial) |
| **SFSpeech foreground** (reconhecedor da Apple, para tela ligada) | ✅ Funciona | 0024: 8 wake matched no iPhone 12 (após corrigir o reciclo — ver §7) |

**Tradução simples:** o iPhone escuta o microfone com a tela travada e roda o "cérebro" de reconhecimento em background. Isso é o que a documentação antiga dizia ser "inviável no iOS" — provamos que é viável, copiando a arquitetura do concorrente (`UIBackgroundModes: audio` + sessão de áudio separada da câmera).

---

## 3. ❌ O ÚNICO PROBLEMA REAL RESTANTE — **DOMAIN GAP** (corrigido com scores reais)

**O modelo "Raro" reconhece a palavra FRACAMENTE — não é silêncio, mas fica muito abaixo do threshold.** A causa-raiz mais precisa é **domain gap** (o modelo foi treinado 100% com voz sintética e nunca viu a voz real do dono nem a distorção do microfone do iPhone), **não** "a palavra ser curta demais" como uma versão anterior deste doc concluía precipitadamente.

### SCORES REAIS medidos (offline, pipeline ONNX × fixtures "Raro" isolado, 2026-06-20)

| Clip | Score máx |
|---|---|
| raro_1 | 0.066 |
| **raro_2** | **0.251** ← melhor |
| raro_3 | 0.059 |
| raro_4 | 0.129 |
| raro_5 | 0.069 |
| raro_6 | 0.147 |
| **gravar_1..4 / parar_1..4** (comparação) | **0.013–0.071** (nível de ruído) |

**Leitura dos números (o que decide tudo):**
- **"Raro" NÃO pontua silêncio.** O melhor é 0.251 e a média ~0.12 — claramente **acima** do ruído de fundo (rimas/comandos ficam 0.01–0.07). **O modelo "vê" a palavra.**
- **MAS está muito abaixo do threshold de produção (0.5)** — o melhor "Raro" é metade do necessário. E é **instável** (0.059 a 0.251 — alguns "Raro" o modelo quase pega, outros ignora).
- Bate com o device: no teste em foreground deram "0 picos ≥0.08", e de fato 3 dos 6 clips offline ficam abaixo de 0.08 — voz ao vivo (acústica do ambiente) tende a ficar ainda mais fraca que as gravações limpas.

### Por que é DOMAIN GAP, não "palavra impossível"
Se "Raro" fosse foneticamente impossível de detectar, daria **zero** (como as outras fixtures). Deu 0.25 — o modelo aprendeu a palavra, mas **decorou a inflexão artificial do TTS** e não generalizou para: a voz real do dono + o EQ/low-pass do microfone do iPhone + ruído ambiente. Isso é a definição de manual de **overfitting / domain gap** num treino 100% sintético. (Diagnóstico do `CONTRAPONTO-ADVERSARIAL-WAKEWORD.md`, confirmado pelos scores acima.)

### 🔬 EXPERIMENTO DE CONTROLE (matriz cruzada, 2026-06-20) — DESEMPATE DEFINITIVO
A voz do dono passada pelos **3 modelos** (raro toggle / parar antigo / gravar antigo), cada palavra no modelo que deveria reconhecê-la:

| Sua voz dizendo | No modelo correto | Score | Veredito |
|---|---|---|---|
| **"parar"** | `raro_parar` | **0.50 / 0.73 / 0.60** | ✅ **FORTE** |
| "Raro" | `raro` (toggle) | 0.06–0.25 | ❌ fraco |
| "gravar" | `raro_gravar` | 0.11–0.21 | ❌ fraco |

**O que isto PROVA (elimina hipóteses por experimento, não argumento):**
- ✅ **A voz do dono + a infra + a engine FUNCIONAM** — "parar" pontua 0.50–0.73 na voz dele (bate com a 0027). Logo NÃO é a voz, NÃO é o mic/pipeline, NÃO é o português/"R forte" (que existe em "parar" e funciona).
- ✅ **Sem cross-firing:** "parar" pontua 0.03–0.04 no modelo `raro` e vice-versa — o modelo `raro` é seletivo, só está surdo pro próprio "Raro".
- ✅ **Única explicação restante:** o modelo `raro` foi mal treinado (domain gap). O `raro_parar`, treinado IGUAL (mesma engine/recipe) mas que pega a voz real forte, prova que o pipeline+recipe CONSEGUEM reconhecer voz real — o `raro` específico não generalizou.

**Conclusão blindada:** o problema é **100% domain gap do modelo `raro`** (treino só sintético). NÃO é a palavra "Raro", NÃO é a voz, NÃO é a engine. → **Treino híbrido (voz real no treino) + manter "Raro".** Trocar pra "Raro Câmera" resolveria o problema errado.

### O que isso muda
- A pesquisa sobre "<6 fonemas" (Picovoice/Home Assistant) **continua válida como fator de risco** (palavra curta É mais difícil), mas **não é prova de impossibilidade** — foi erro metodológico tratar um teste zero-shot (sintético→real) como veredito sobre a palavra.
- **A solução de engenharia de dados NUNCA foi tentada:** nenhum dos 3 modelos treinados (~US$11) teve **voz real do dono no treino** nem **augmentation de bolso (RIR/low-pass)**. Ver §13.

---

## 4. TIMELINE COMPLETA DAS TENTATIVAS (sessão a sessão)

| Sessão | O que se tentou | Resultado | Custo |
|---|---|---|---|
| **0023** | Declarar SFSpeech "beco-sem-saída"; decidir migrar p/ OpenWakeWord/ONNX (ADR-0023) | Decisão registrada — **diagnóstico depois refutado** | — |
| **0024** | Refutar o "beco-sem-saída"; provar mic-only em background (probe) | SFSpeech foreground **funciona** (era bug nosso). Background mic-only **provado** | — |
| **0025** | Treinar `raro_gravar`/`raro_parar` no RunPod (2 comandos) | ~92% recall **sintético**. Kaggle abandonado (P100 incompatível + travas) | ~US$6,40 |
| **0026** | Descobrir que faltavam 2 dos 3 estágios ONNX; versionar | Corrigido, 4 .onnx no bundle | — |
| **0027** | Construir `WakeWordDetector` + gate de recall offline | Pipeline funciona. **`raro_gravar` 0/4 no device** (máx 0.213 vs 0.34) | — |
| **0028** | Descobrir DRIFT (Blueprint sempre pediu toggle único). Re-treinar gravar/parar com diversidade + re-treinar "Raro" toggle | gravar **4/4** mas **cross-fire**; "Raro" toggle 81% sintético | ~US$5 |
| **S2.E (hoje)** | Construir background dedicado; provar mic/detector em background; medir RMS pós-lock; **medir scores reais de "Raro" offline** | **Background PROVADO**; "Raro" pontua 0.06–0.25 (reconhece fraco, **domain gap** — não silêncio nem palavra impossível) | ~US$0 |

**Total já gasto em treino: ~US$11.** **Modelos treinados: 3 (gravar 92%, parar 92%, raro-toggle 81% — todos sintético; todos fracos/problemáticos na voz real).**

---

## 5. ENGINES / ABORDAGENS AVALIADAS E DEFINITIVAMENTE DESCARTADAS

> **Não re-tentar à toa.** Cada uma já bateu na parede com motivo documentado.

| Engine/Abordagem | Por que descartada | Status |
|---|---|---|
| **Picovoice Porcupine** | Free tier = 3 usuários/mês (inútil); produção ~US$6.000+/ano. Inviável p/ R$9,90/mês | DEFINITIVO (dono recusou) |
| **Sensory TrulyNatural** (engine do concorrente) | Modelo `.snsr` grátis MAS expira sozinho (dev key ~120 dias→recusa init em TODOS os devices) + cobre só 5 instâncias; runtime iOS só por contrato comercial + royalty | DEFINITIVO (gated) |
| **DaVoice** | Engine melhor (0.99) MAS proprietária/licenciada; background iOS exige "advanced SDK" separado; mesma barreira de gating | DESCARTADA |
| **WhisperKit** | ~150MB, latência alta, feito p/ transcrição não wake-word. Overkill | DESCARTADA v1.0 |
| **EfficientWord-Net** (few-shot) | Fraco em frases de 2 palavras; inferior a Porcupine | DESCARTADA |
| **nanowakeword** | Quer 10k+ positivos → volta ao problema de gerar dados | DESCARTADA |
| **Vosk / Silero / Snowboy / sherpa-onnx** | Nunca foram candidatas sérias; aparecem só como checklist negativo no teardown do concorrente | N/A |
| **SFSpeech/SpeechAnalyzer (API Apple) para wake-word custom em background** | iOS emite **erro 1700** em background; limite ~1min/sessão, ~1000 req/h. Nenhuma API Apple suporta wake-word custom | DEFINITIVO p/ background |
| **OpenWakeWord puro** (vs livekit fork) | Notebook oficial quebrado desde nov/2025 (issue #296); English-only. Head do livekit é superior (100× menos FP/h) | Preterido (usa-se livekit fork) |

---

## 6. O BECO SEM SAÍDA DOS "2 COMANDOS" (gravar/parar) — abandonado de vez

Foi a maior perda de tempo/dinheiro do histórico, e merece registro completo:

- **O que era:** treinar 2 classificadores binários independentes — `raro_gravar.onnx` (start) + `raro_parar.onnx` (stop).
- **Problema 1 — DRIFT do Blueprint:** o Blueprint M03 + ADR-0009 **sempre** pediram **toggle de palavra única "Raro"**. Os ADR-0022/0023 introduziram "dois comandos" **contradizendo o Blueprint sem sinalizar**. Treinou-se o alvo errado por não reler a fonte. **Custo: ~US$5 + horas.**
- **Problema 2 — Cross-fire ESTRUTURAL (provado no device, 0028):** como "Raro gravar" e "Raro parar" começam igual ("Raro"), os modelos viram detectores de "raro qualquer-coisa". `raro_gravar` dispara em clips de "parar" (g=0.81–0.90). Mesmo com `argmax(gravar, parar)` = só **5/8** de acerto. **Software não salva** — é limite estrutural de classificadores binários com prefixo compartilhado.
- **Tentativa de conserto que FALHOU:** `custom_negative_phrases: ["raro parar"]` no config do gravar (usar a frase-irmã como negativo) **não bastou** — prefixo compartilhado é inerentemente difícil.
- **Alternativa descartada:** modelo multi-classe (1 modelo, saídas gravar/parar/nenhum) — melhor solução ML, mas fora do fluxo livekit padrão e "resolve um problema que o Blueprint não tem".
- **Status:** **ABANDONADO de vez** (ADR-0024). Caminho certo = 1 toggle "Raro".

---

## 7. HIPÓTESES DE DIAGNÓSTICO QUE ESTAVAM ERRADAS (refutadas com prova)

| Hipótese | Por que estava errada | Como foi refutada |
|---|---|---|
| **"SFSpeech é beco-sem-saída p/ wake-word"** (0023) | Era bug NOSSO: reciclar a `recognitionTask` a cada erro `1110` (no-speech benigno) → 521 reciclos vs 1 wake matched, janela morta engolia o comando | Log limpo no device (0024); fix sem trocar engine = 8 wake matched. **Quase custou migração de semanas** |
| **"endpointer exige stream limpo desde o onset"** (0023) | O 1110 é só silêncio benigno; o reuso de tap não era o problema | "N análises adversariais convergiram" ≠ prova; log refutou |
| **"a sessão de áudio morre no lock"** (hipótese S2.E, minha e de outra sessão) | Mic sobrevive ao lock; detector roda na ANE em background | Teste de RMS pós-lock (S2.E): energia `HAS-CONTENT` + `ANE status=0x0` |
| **"erro Metal GPU-background = a voz quebrou"** | É do **Flutter render** (desenhar UI em background, iOS bloqueia GPU). A voz usa ANE+CPU, não a GPU de render | S2.E: voz processou normalmente apesar dos 195 erros de Metal/render |
| **"CoreML/fp16 degrada o score"** (0027) | CoreML ≈ CPU nos scores (0.213 vs 0.211) | A/B `classifierProvider` no device → fp16 descartado como causa |
| **"mel-context 1280 vs 1760 causa o score baixo"** (0027) | Scores idênticos (0.211 = 0.211) | A/B offline em Python ($0) → mel-context descartado como causa |
| **"copiar o threshold 0.45 do Ok Camera"** | 0.45 é da engine Sensory (escala diferente); o nosso é 0.34. Erro de categoria | Esclarecido na 0027 |
| **"custom verifier model resolve o score baixo"** | Verifier REDUZ falsos-positivos (aperta), não AUMENTA detecção | Pesquisa 2026: não aplicável a recall baixo |

---

## 8. ARMADILHAS DE TREINO (todas documentadas — evitar repetir)

| Armadilha | Detalhe | Fix |
|---|---|---|
| **Piper é english-only** | PT-BR EXIGE `tts_backend: voxcpm`. "Piper no CPU/Mac" para "Raro" é FALSO | VoxCPM (precisa GPU CUDA) |
| **Treino no Mac do dono = impossível** | MacBook Intel i5, GPU Intel Iris 1.5GB, SEM CUDA. VoxCPM precisa NVIDIA ~8GB | Treino no RunPod (~US$3) |
| **Google Colab** | Cai por timeout/idle 90min | Abandonado |
| **Kaggle P100 (sorteada)** | sm_60 incompatível VoxCPM → `CUDA: no kernel image` no fim do run | Forçar T4 via `--accelerator NvidiaTeslaT4` |
| **Kaggle T4 grátis** | Lento, run zumbi "RUNNING" 10h+ travado (GPU 0%) | Abandonado → RunPod |
| **HF download pendura (2 causas)** | (a) rate-limit anônimo 76h; (b) backend `hf_xet` trava CDN | `HF_TOKEN` + `pip uninstall hf-xet`. NUNCA `hf_transfer` |
| **RunPod PEP 668** | `pip install` falha; `set -e` mascara | `PIP_BREAK_SYSTEM_PACKAGES=1` + `command -v ... \|\| exit 1` |
| **5090 (sm_120) torch antigo** | Não funciona | template `cu128/torch280` |
| **Config errada inventada** | `wake_phrase`/`run --config` não existem (são `target_phrases`/`run <config>` posicional) | Reusar script validado, não "versão limpa" |
| **$SSHOPT quebra SSH** | ssh lê flags como nome de arquivo → timeout | flags SSH diretas no comando |
| **Pod ociosa estoura saldo no SETUP** | 2 rodadas estouraram baixando ACAV 16GB + idle 8h | kill-switch `persistent`, START logo, .onnx-pronto→terminate. (Stop/Pause continua cobrando, só Terminate zera) |
| **mel no CoreML** | Incompatibilidade de operadores | mel em CPU/XNNPACK; só classifier no CoreML |
| **API ORT 1.24.2 ≠ plano** | módulo `OnnxRuntimeBindings` (não `onnxruntime`); `appendCoreMLExecutionProvider(with:)` | Validar API real, não a do plano |
| **Dependency hell** | torchaudio 2.10+/Piper/speechbrain têm breaking changes | Fixar commit conhecido |
| **`--skip-acav` no build final** | OK p/ iterar recall, mas FP não-confiável (FPPH 2.08 vs 0.0 com acav) | ACAV obrigatório no build de produção |

---

## 9. ARMADILHAS DE VALIDAÇÃO / PROCESSO (erros que custaram tempo)

| Erro | O que aconteceu | Lição |
|---|---|---|
| **Eval sintético MENTE** | 91% sintético → 0% real (0027); 81% sintético = só "sinal precoce" (0028) | Gate = áudio real do iPhone, NUNCA sintético |
| **Unit tests verdes ≠ recall** | Testes positivos usavam `FakeClassifier`; o E2E real alimentava ZEROS. Silêncio passa idêntico por pipeline certo OU quebrado | Gate de recall OFFLINE com WAV real antes de wiring/re-treino |
| **Probe DESLIGOU a voz que funcionava** (0027) | Pra testar o substituto ONNX, derrubou-se o SFSpeech funcional + pediu teste antes de confirmar canal de log → dono ficou sem voz | Nunca derrubar o que funciona pra testar o não-provado |
| **Install falho lido como "fix não funcionou"** (0024) | Build falhou ao instalar (exit 1) mas pediu-se teste; dono testou binário VELHO | Confirmar `App installed:` + container UUID novo + timestamp ANTES de pedir teste |
| **Estimativas de tempo de cabeça** (0025) | "~5h" vs 10h30 reais | Medir delta real, nunca somar de memória |
| **Run zumbi não detectado** (0025) | "RUNNING" lido como vivo (GPU 0%, travado 8h) | Prova de vida = delta de log/bytes/GPU em 2 pontos |
| **`.gitignore` dos .onnx** (0025) | Bloqueou os modelos ("prova é descartável"); viraram os únicos → bug latente | Versionar com README de proveniência |
| **Feature-extractors não versionados** (0025) | Baixou só os classifiers; sem os 2 extractors o detector retorna nil | Descoberto+corrigido na 0026 |
| **Estiquei prova de A pra concluir B** (S2.E) | Usei o recall offline (modelo) pra "provar" que o background está OK — logicamente inválido | Teste sem áudio não julga problema de áudio; mede cada problema isolado |
| **Builds às pressas com bug** (S2.E) | 3 builds, cada um com um bug (mic não chegava ao detector; isAvailable exigia Speech no modo ONNX). Pedi teste sem validar sozinho | Validar a cadeia no log do device ANTES de pedir teste ao dono |
| **Troquei motor sem avisar** (S2.E) | Liguei ONNX (desligando SFSpeech) e pedi teste de "raro gravar" que estava desligado de propósito | Comunicar mudança de motor com clareza |

### Códigos de erro SFSpeech (interpretação correta, pra referência)
- **1110** = no-speech BENIGNO (silêncio) → NÃO reiniciar agressivo
- **301** = "request canceled" gerado pelo PRÓPRIO `task.cancel()` do reciclo (sintoma, não causa)
- **1700** = app em background (impossível usar SFSpeech em background por design)
- **Terminais reais** (reiniciar com backoff): 1101 / 1107 / 7 / 4 / 203

---

## 10. O QUE FUNCIONOU NO TREINO (lições positivas confirmadas)

- **Diversidade > volume:** aumentar vozes sintéticas (14→76/80 prompts) tirou o `raro_gravar` de 0/4 para **4/4** na voz do dono. **Diversidade de timbre é o fator que faz reconhecer voz real.** (Mas não resolveu o cross-fire do design de 2 comandos.)
- **n_samples=4000 basta** (a grade VoxCPM faz wrap `index%n`; 80 prompts = 912 vozes únicas; acima de 4000 é repetição).
- **ACAV robustece a fronteira** (FPPH 0.0 com acav vs 2.08 sem) — necessário pro background.
- **RunPod RTX 5090 funciona** (~92% sintético, ~US$3) com os 3 fixes de armadilha.
- **Real-only NÃO substitui sintético** (overfita 1 mic/cômodo). Consenso: HÍBRIDO (TTS multi-voz + 20–50 reais peso 3×).

---

## 11. PARÂMETROS DO CONCORRENTE (referência pra calibrar — do teardown Android)

- Áudio: **16kHz mono PCM**, chunks de 320 samples (20ms)
- Score mínimo (sv-score): **0.45** (escala Sensory, ≠ nossa)
- Debounce entre detecções: **2500ms** (já aplicado no nosso, corrigido de 25→20 embeddings na 0027)
- **RMS gate (VAD barato):** start 0.026 / stop 0.012
- Beep no wake (feedback)
- Background Android: ForegroundService CAMERA+MIC + WAKE_LOCK (**não existe no iOS** — lá é `UIBackgroundModes:audio`)
- iOS dele: `UIBackgroundModes: ['audio']` + zero entitlement especial (extraído do iPhone)

---

## 12. BUGS MENORES ABERTOS (baixa prioridade, documentados)

- **mel-context 1280 vs 1760:** o Swift alimenta o mel com chunk 1280; openWakeWord usa 1760 (1280+480 de contexto). Bug real, simétrico, **já descartado como causa do recall baixo**. Corrigir antes de re-derivar limiares finais.
- **`applicationDidEnterBackground` não dispara com câmera/áudio ativo:** o rótulo de estado no log diz "FOREGROUND" mesmo em background real (iOS mantém o app "ativo"). Cosmético, não-funcional.
- **Ring buffer só cobre o path da câmera:** o fix da janela morta (CMSampleBuffer) não cobre o path own-engine (AVAudioPCMBuffer). Aceito — tratar só se "raro parar" falhar em telas sem câmera (moot com toggle único).
- **Gate §10 ffprobe (pré-roll):** débito herdado desde 0023, nunca rodado.

---

## 13. CAMINHO À FRENTE (decisão pendente do dono) — REVISADO após os scores reais

Background provado. O modelo **reconhece "Raro" fracamente** (0.25) — falta fechar o **domain gap**, não trocar a palavra. Treino é na nuvem (~US$3 — Mac não treina). **A engenharia de dados que resolve isso NUNCA foi tentada.**

### CAMINHO RECOMENDADO (ordem certa — exaurir engenharia de dados ANTES de mexer no Blueprint)

**Opção PRINCIPAL — Treino HÍBRIDO com voz real do dono (mantém "Raro"):**
1. **Dataset real:** dono grava **50–100 amostras de "Raro"** variando distância, entonação (sussurro→grito), velocidade e ruído de fundo.
2. **Treino híbrido:** misturar os ~4000 samples sintéticos (VoxCPM) com os 50–100 reais, com **peso 3–5×** nos reais. (A voz real entra no **TREINO**, não só na validação — testar no modelo velho não resolve, ele nunca verá áudio fora da distribuição original.)
3. **Domain randomization:** aplicar **RIR + low-pass (abafamento de bolso/tecido) + ruído ambiente** aos positivos, para o caso de uso "telefone no bolso". (ACAV só trata falso-positivo; isto trata o falso-NEGATIVO, que é o problema atual.)
4. **(Secundário/experimento)** Testar spelling fonético na síntese ("Haaro", "Rrá-ro"). *Honestidade: os scores (0.25, não zero) sugerem que isto é menos importante — o modelo já capta "Raro"; priorizar 1–3.*

> **Por que isto antes de trocar a palavra:** trocar "Raro" por "Raro Câmera" sem antes tentar o treino híbrido é "ferir o Blueprint por conveniência de implementação" (`CONTRAPONTO-ADVERSARIAL-WAKEWORD.md`). O Blueprint pede "Raro". Só mudar o produto se a engenharia de dados falhar.

**Opção de FALLBACK — "Raro Câmera" (frase 4 sílabas):** SÓ se o treino híbrido (Opção principal) não atingir score útil. Aí a palavra mais longa vira justificável, com decisão de produto + ADR.

**O que NÃO fazer:** abaixar o threshold até qualquer ruído disparar (vira app que grava sozinho); testar voz real só no modelo VELHO (não resolve — voz real tem que entrar no treino); re-tentar engines pagas/gated; re-tentar 2 comandos; treinar no Mac; treinar com Piper em PT-BR; trocar a palavra antes de exaurir o treino híbrido.

---

## 14. 📍 ONDE ESTAMOS AGORA (estado em 2026-06-20, fim da S2.E)

**Resumo de uma frase:** a infraestrutura inteira de voz — incluindo o background com tela travada, que era a parte "impossível" — está **construída e provada no iPhone 12** (mas a prova ainda NÃO está consolidada em commit/session — ver abaixo). O bloqueio é o **modelo reconhecer "Raro" só fracamente (melhor score 0.25 vs threshold 0.5)** por **domain gap** — treino 100% sintético, nunca viu voz real. A solução é **treino híbrido com voz real do dono** (nunca tentado), não trocar a palavra.

⚠️ **Fragilidade da prova de background (ponto válido de auditoria):** a evidência (RMS pós-lock + ANE em background) está em logs `/tmp` + memória, mas o **código instrumentado é um build de teste NÃO commitado e sem session log**. Um rebuild limpo apaga a instrumentação e a prova "some". Antes de tratar como definitivo, consolidar: commit do `AudioSessionCoordinator`/`VoiceManager` + session log registrando o teste de RMS.

**Build atual no iPhone 12 (container `36BE5919`, profile 22:07):**
- Modo ONNX ligado (`useOnnxEngine = true` — ⚠️ build de teste)
- Threshold de teste em 0.10
- Instrumentação de teste ativa: log de RMS, log de picos, contador de frames
- O modelo `raro.onnx` (rodada 0029, toggle, 81% sintético) — **não reconhece "Raro" na voz real**

**O que está PRONTO e provado (não regredir):** §2 inteira — mic em background, detector na ANE, captura dedicada, cadeia de ação, SFSpeech foreground.

**O que está BLOQUEADO:** o disparo da gravação por voz, porque o modelo não pontua a palavra (§3).

**Trabalho de limpeza pendente ANTES de qualquer commit de produção:**
- [ ] Reverter `useOnnxEngine = true` → flag/env com default
- [ ] Reverter threshold de teste 0.10 → valor calibrado
- [ ] Remover instrumentação de teste (RMS log, log de picos, contador de frames)
- [ ] Remover `raro_gravar.onnx` / `raro_parar.onnx` órfãos do bundle + pbxproj
- [ ] Corrigir/aceitar o bug cosmético do rótulo de estado (§12)

**Pendências do dono:**
- [ ] **[DECISÃO]** Escolher o caminho da palavra (§13) — recomendação: gravar voz + testar offline antes de treinar

**Não-feito / não-testado (rastreado, não esquecido):**
- **Scores de "Raro" agora MEDIDOS** (offline, 2026-06-20): 0.06–0.25 (melhor raro_2=0.251). Config do teste estava CORRETA (modelo `raro` toggle × fixtures `raro_1..6.wav` que SÃO "Raro" isolado ~0.85s; fixtures `gravar_N`/`parar_N` são separadas e pontuam 0.01–0.07). **Correção de erro deste doc:** uma versão anterior dizia que "as fixtures são raro gravar/parar" — ERRADO.
- **Treino HÍBRIDO com voz real do dono + augmentation de bolso (RIR/low-pass): NUNCA tentado.** É a engenharia de dados que fecha o domain gap (§13). Os 3 modelos treinados (~US$11) foram 100% sintéticos.
- **Background provado mas NÃO consolidado:** instrumentação de RMS está em build de teste não-commitado; falta commit + session log.
- Lote cheio n_samples=15000 — tentado 2×, **cancelado** ambas (saldo+ETA); modelos usados são sempre "de prova"
- Refactor final 2 classifiers → 1 `raro` + re-bundle limpo (parcialmente feito nesta sessão, falta limpar)
- Wiring de produção do background (single mic owner + RMS gate + debounce 2500ms) — provado em teste, falta consolidar fora do modo de teste

---

## 15. ONDE ESTÁ CADA COISA (índice)

| Pergunta | Local |
|---|---|
| Decisão de engine de voz | ADR-0023 (`docs/decisions/`) |
| Decisão toggle único "Raro" | ADR-0024 |
| Wake word original | ADR-0009 |
| Pipeline ONNX (shapes, I/O) | memória `raro-pattern-wakeword-onnx-3stage-pipeline-shapes` |
| Background provado (ANE, RMS) | memória `raro-pattern-ios-background-wakeword-proven-ane-not-gpu` |
| Pesquisa de boas práticas 2026 | memória `raro-research-wakeword-best-practices-2026` |
| Por que SFSpeech foreground funciona | memória `raro-pattern-sfspeech-continuous-no-recycle-per-error` |
| Gate de recall offline obrigatório | memória `raro-pattern-wakeword-offline-recall-gate-before-wiring` |
| Arquitetura background do concorrente (iOS) | memória `raro-competitor-okcamera-ios-background-audio-entitlements` |
| Teardown Android do concorrente (parâmetros) | memória `raro-competitor-okcamera-android-apk-teardown` |
| Sensory gated (por que descartado) | memória `raro-competitor-sensory-voicehub-ios-sdk-gated` |
| Como treinar no RunPod | memória `raro-pattern-wakeword-train-runpod-5090-hf-token` |
| Kaggle P100 incompatível | memória `raro-pattern-kaggle-p100-incompatible-force-t4` |
| Não esticar prova de um problema p/ outro | memória `feedback_dont_stretch_one_test_to_conclude_another_problem` |
| Reler Blueprint antes de treinar caro | memória `feedback_reread_blueprint_before_expensive_train` |
| Código do detector | `apps/mobile/ios/Runner/Native/Voice/` |
| Modelo atual | `apps/mobile/ios/Runner/Resources/raro.onnx` |
| Sessions de voz | `docs/sessions/0023` a `0028` |
