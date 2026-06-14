# Notas de treino — modelo wake-word "Raro"

> Registro vivo do treino dos classificadores de voz do RARO. Suporta o gate de viabilidade do iPhone 12 (ADR-0023).
>
> ## ✅ FATOS VALIDADOS 2026-06-11 (sessão 0024, fonte primária livekit-wakeword 0.2.1)
> - **TTS = VoxCPM (NÃO Piper).** Confirmado na doc oficial: **Piper é english-only**; PT-BR EXIGE `tts_backend: voxcpm`. (Correção de um erro intermediário desta sessão que dizia "use Piper" — Piper não gera português aqui.) Aviso oficial: *acurácia multilíngue é menor → subir `voice_design_prompts` p/ 50-100 + `n_samples` alto.*
> - **Venue:** VoxCPM exige **CUDA (~8GB VRAM)**. Vale **Kaggle (T4/P100 16GB, grátis — mas VoxCPM é lento, cuidar do cap de 9h/sessão + 30h/sem)** OU **RunPod/Vast 4090 (mais rápido, ~US$1-4, você opera)**. **Não roda no Mac.** Mitigar disco-cheio (erro anterior): caches em `/kaggle/working` ou `/workspace` via `HF_HOME`.
> - **Versão pinada:** `pip install "livekit-wakeword[train,eval,export,voxcpm]==0.2.1"` (Python ≥3.11). System deps: `espeak-ng libsndfile1 ffmpeg sox portaudio19-dev`.
> - **Kit turnkey pronto:** `configs/raro_gravar.yaml` + `configs/raro_parar.yaml` + `train-raro.sh` (ver Runbook abaixo).
> - **Lado iOS:** onnxruntime 1.24.2; CoreML EP via `appendCoreMLExecutionProviderWithOptions:`; mel roda em CPU/XNNPACK.

## Runbook turnkey (como rodar o treino)

**Arquivos do kit** (em `docs/superpowers/notebooks/`): `configs/raro_gravar.yaml`, `configs/raro_parar.yaml`, `train-raro.sh`. API/config validados em fonte primária (não testados por execução — sem GPU no ambiente de autoria; confira saídas na 1ª rodada).

**Opção A — Kaggle (grátis, familiar):**
1. Novo Notebook → Settings → Accelerator = **GPU T4 x2** (ou P100); Internet = **On**.
2. Upload da pasta `notebooks/` (os 2 YAML + o `.sh`) como Dataset, ou cole o conteúdo em células.
3. Numa célula: `!WORK=/kaggle/working bash train-raro.sh` (full) ou `!QUICK=1 WORK=/kaggle/working bash train-raro.sh` (prova rápida primeiro).
4. ⚠️ VoxCPM é lento — se passar de ~8h, reduza `n_samples` ou rode 1 comando por sessão. Baixe os `.onnx` + metrics do Output.

**Opção B — RunPod/Vast (rápido, ~US$1-4):**
1. Alugue uma instância **RTX 4090** com template PyTorch/CUDA (Ubuntu).
2. No terminal: `git clone` (ou upload) → `cd .../notebooks` → `WORK=/workspace bash train-raro.sh`.
3. Baixe `raro_gravar.onnx` + `raro_parar.onnx` + metrics JSON.

**Sempre:** comece com `QUICK=1` (prova de pipeline + sinal precoce de recall barato) ANTES do treino cheio. Se o QUICK já vier com recall horrível, pare e ajuste antes de gastar o treino completo.

## Engine e decisões

- **Engine de treino:** [`livekit-wakeword`](https://github.com/livekit/livekit-wakeword) — Apache-2.0,
  baseado no openWakeWord, com cabeça **Conv-Attention** (menos falsos-positivos, preserva estrutura
  temporal da janela de 16 frames de embeddings).
- **Idioma:** PT-BR puro, via backend **VoxCPM** (`tts_backend: voxcpm`). A própria doc oficial avisa:
  *"multilingual models currently achieve lower accuracy than English models"* — por isso o gate de
  recall e o eventual reforço com gravações reais são parte do plano.
- **Decisão 5a (dois classificadores de frase inteira):** o RARO precisa distinguir dois comandos.
  Wake-word puro só detecta UMA frase, então treinamos **dois** classificadores rodando a pipeline
  duas vezes:
  - `"raro gravar"` -> `raro_gravar.onnx` (comando **START**)
  - `"raro parar"` -> `raro_parar.onnx` (comando **STOP**)
- **Estágios compartilhados:** `melspectrogram.onnx` + `embedding_model.onnx` são genéricos (extração de
  features), vêm bundlados no pacote pip e são os mesmos para os dois comandos.
- **Wake word = "Raro"** (ADR-0009, hard rule em `raro_shared`). Nunca outra palavra.
- **Notebook de treino:** [`../notebooks/raro-wakeword-training.ipynb`](../notebooks/raro-wakeword-training.ipynb)
  (rodar no **Kaggle** com GPU T4/P100 — Colab grátis foi descartado porque desconecta no meio do treino;
  Kaggle dá 9h/sessão estáveis. Ver memória `raro-pattern-wakeword-train-cpu-piper-no-colab`).
- **Spec da feature:** [`../specs/2026-06-09-voice-wakeword-livekit-onnx-engine-design.md`](../specs/2026-06-09-voice-wakeword-livekit-onnx-engine-design.md).
- **ADR de engine:** `docs/decisions/0023-voice-engine-dedicated-not-sfspeechrecognizer.md`.

## Contrato de I/O dos modelos ONNX (o que a Task 3 implementa)

> **✅ VALIDADO POR INSPEÇÃO DIRETA DOS .onnx (sessão 2026-06-14).** Os shapes/nomes/dtypes abaixo
> NÃO são mais "a confirmar" — foram extraídos com `onnx.load(...).graph` dos 4 arquivos reais já
> versionados em `apps/mobile/ios/Runner/Resources/`. A Task 3 (Swift) lê DAQUI e não inventa shapes.
> Fonte primária corroborante: openWakeWord `utils.py` (streaming) + livekit docs `export-and-inference.md`.
> Memória: `raro-pattern-wakeword-onnx-3stage-pipeline-shapes`.

O detector roda **3 sessões ONNX em cadeia**: áudio -> `melspectrogram` -> `embedding_model` ->
`<classifier>`. Os 4 arquivos estão em `apps/mobile/ios/Runner/Resources/`.

> ⚠️ **DÉBITO ABERTO p/ a Task 3 (não esquecer):** os 4 `.onnx` estão no disco + git, mas **NÃO estão
> referenciados no `project.pbxproj`** (projeto NÃO é file-system-synchronized — confirmado:
> 0 `PBXFileSystemSynchronizedRootGroup`). **Sem as inserções no pbxproj eles NÃO entram no bundle** e
> `Bundle.main.url(forResource:)` retorna `nil` em runtime (bug silencioso). Adiar foi decisão consciente:
> o pbxproj será tocado UMA vez junto com o `WakeWordDetector.swift` + seu XCTest (cada arquivo de
> produção/teste novo exige 4 inserções — PBXBuildFile, PBXFileReference, PBXGroup, build phase; para os
> modelos: PBXFileReference + PBXBuildFile + entrada no `97C146EC...` PBXResourcesBuildPhase / Copy Bundle
> Resources). Ver memória `raro-pattern-ios-xctest-pbxproj-4-insertions`. **Validar no device que os 4
> carregam (smoke-test de `Bundle.main`) antes de confiar no detector.**

| Arquivo | Papel | Input (nome, shape, dtype) | Output (nome, shape, dtype) | Opset | Stateful? |
|---|---|---|---|---|---|
| `melspectrogram.onnx` | Áudio 16 kHz mono -> mel spectrogram | `input`, `[batch_size, samples]`, FLOAT | `output`, `[time, 1, ?, 32]`, FLOAT (**32 mel bins**) | 13 | Não (transform puro) |
| `embedding_model.onnx` | Mel -> embeddings (frozen, Google speech embedding) | `input_1`, `[?, 76, 32, 1]`, FLOAT (**janela de 76 mel frames × 32 bins**) | `conv2d_19`, `[?, 1, 1, 96]`, FLOAT (**embedding 96-dim**) | 13 | Não (transform puro) |
| `raro_gravar.onnx` | Classificador do comando **START** | `embeddings`, `[batch, 16, 96]`, FLOAT | `score`, `[batch, 1]`, FLOAT | 18 | Não (a sessão ONNX é stateless) |
| `raro_parar.onnx` | Classificador do comando **STOP** | `embeddings`, `[batch, 16, 96]`, FLOAT | `score`, `[batch, 1]`, FLOAT | 18 | Não (a sessão ONNX é stateless) |

Encadeamento provado (a saída de um estágio é o input do próximo):
`áudio[1, N]` → mel `[T, 1, ?, 32]` → (janela 76×32) → embedding `[?,1,1,96]` → (ring buffer 16) → classifier `[1, 16, 96]` → `score[1,1]`.

Algoritmo de streaming (validado no `utils.py` do openWakeWord, que o livekit 0.2.1 reusa):
- **Passo de áudio: 1280 samples (80 ms @ 16 kHz).** O mel processa a cada 1280 samples acumulados.
- **Janela do embedding: 76 mel frames × 32 bins**, deslizando com **step_size = 8** mel frames.
- **Classifier lê os ÚLTIMOS 16 embeddings** -> `(1, 16, 96)`. (~2 s = 32.000 samples = 16 embeddings.)
- **Normalização do mel:** `x/10 + 2` (default openWakeWord). Áudio float32; a doc aceita int16 ou float32 [-1,1].

Observações:
- **Opset 13** nos genéricos, **opset 18** nos classificadores. Sem quantização INT8 (fluxo default).
- **Limiares ótimos (usar estes, NÃO 0.5):** `raro_gravar` = **0.34**, `raro_parar` = **0.23**
  (de `*_eval.json`; ver tabela de métricas abaixo).
- **iOS — seleção de EP POR modelo:** `melspectrogram` roda em **CPU/XNNPACK** (operadores incompatíveis
  com CoreML, confirmado 0024); o classifier (e provavelmente o embedding) no **CoreML EP**
  (`appendCoreMLExecutionProviderWithOptions:`). Smoke-test de carga dos 3-4 modelos no device é
  obrigatório antes de confiar.
- **O DETECTOR (camada Swift) é STATEFUL**, mesmo as sessões ONNX sendo stateless: mantém um ring
  buffer de mel frames (≥76) E um ring buffer de embeddings (≥16). O estado (buffers + cooldown/debounce)
  vive no `WakeWordDetector`, não no grafo ONNX. Os 2 classificadores compartilham mel+embedding (rodam
  1×, alimentam os dois scores).

## Proveniência dos arquivos (sha256 — anti bug silencioso)

Os 4 `.onnx` em `Runner/Resources/`, com origem auditável:

| Arquivo | sha256 | Origem |
|---|---|---|
| `melspectrogram.onnx` | `ba2b0e0f8b7b875369a2c89cb13360ff53bac436f2895cced9f479fa65eb176f` | pacote pip `livekit-wakeword==0.2.1` (`livekit/wakeword/resources/`) — MESMA versão do treino |
| `embedding_model.onnx` | `70d164290c1d095d1d4ee149bc5e00543250a7316b59f31d056cff7bd3075c1f` | idem (genérico, frozen) |
| `raro_gravar.onnx` | `3d5f5ec715ce224bd9cdb768fbe461c03b72bc56c8cdf5f64283d24036416267` | treino RunPod 5090 (sessão 0025) — classificador START |
| `raro_parar.onnx` | `e96fce98c0135b47928e1f5caef545f397b482274da544dde62126c6272ad016` | treino RunPod 5090 (sessão 0025) — classificador STOP |

> **Por que os genéricos vieram do pacote 0.2.1 e não do openWakeWord:** garantir que mel+embedding
> sejam EXATAMENTE os que a engine usou no treino dos classificadores — proveniência idêntica elimina
> risco de incompatibilidade silenciosa de variante/versão (que só apareceria como recall ruim no
> device). A sessão 0025 baixou só os 2 classificadores do RunPod e terminou o pod; os 2 genéricos
> ficaram para trás (bug latente) — resolvido aqui extraindo-os da mesma versão pinada.

## Parâmetros de referência do concorrente (calibração)

Valores reais extraídos do teardown do concorrente "Ok Câmera" (memória
`raro-competitor-okcamera-android-apk-teardown`). São **referência para calibrar o detector na Task 3**,
não exigências do treino:

| Parâmetro | Valor de referência | Uso |
|---|---|---|
| Sample rate | 16 kHz mono | Captura/áudio do detector |
| Chunk de streaming | 20 ms (320 samples) | Tamanho do bloco alimentado ao buffer |
| Janela do classificador | ~2 s (32.000 samples -> 16 embeddings) | Janela deslizante de inferência |
| Score threshold | ~0.45 | Limiar de disparo do `score` |
| Debounce | 2500 ms | Evita disparos repetidos da mesma fala |
| Cooldown inicial | 2500 ms | Silêncio logo após ativar a escuta |
| RMS gate (start) | 0.026 | Porta de energia antes de inferir (poupa bateria) |
| RMS gate (stop) | 0.012 | Histerese da porta de energia |
| Beep no wake | sim | Confirmação sonora ao detectar (copiar comportamento) |

## Métricas medidas (eval offline — rodada de PROVA, sessão 0025)

> Valores reais do eval da própria ferramenta (`*_eval.json`). São de **prova** (`n_samples=2000`),
> não do lote cheio (cancelado por custo — ver sessão 0025). Suficientes p/ a 1ª validação no iPhone.

| Modelo | Recall @ ótimo | Recall @ 0.5 | FP/hora | Limiar ótimo | Accuracy | Tamanho `.onnx` | Data |
|---|---|---|---|---|---|---|---|
| `raro_gravar.onnx` | **91,4%** | 88% | 0,18 | **0,34** | 94,0% | 99.190 B | 2026-06-13 |
| `raro_parar.onnx` | **92,2%** | 88% | 0,18 | **0,23** | 94,0% | 99.190 B | 2026-06-13 |

Validação: ~17h de áudio negativo, 500 positivos / 30.584 negativos por classe. Hardware: RunPod RTX 5090.
Arquitetura: conv_attention/small. TTS: VoxCPM (PT-BR). `n_samples=2000` (prova).

Tamanho dos genéricos: `melspectrogram.onnx` = 1.087.958 B (~1,0 MB) ·
`embedding_model.onnx` = 1.326.578 B (~1,3 MB). Total dos 4 no bundle ≈ **2,6 MB**.

Notas livres do treino:

- Lote cheio (`n_samples=15000`) tentado e **cancelado aos 60%** (VoxCPM desacelerou ~3-4 s/clip,
  saldo da GPU acabaria antes do fim). Plano B se o iPhone reprovar: lote cheio OU +`voice_design_prompts`
  (50-100). Detalhes: sessão 0025 + `COMO-TREINAR-runpod-4090.md`.

## Gate de aceite

- **Gate oficial: recall > 80% no iPhone 12 físico** (Task 7), com voz real, várias vozes/distâncias,
  e falsos-positivos baixos rodando áudio sem a palavra. Medido no device, **não** no Simulator
  (spec, seção "Gate de viabilidade").
- O **eval offline** do Passo 8 do notebook (voz sintética) é só um **indicador precoce**. Se já vier
  abaixo de 80%, **parar e reavaliar antes de seguir** — não adianta integrar um modelo fraco.
- **Plano B se o recall ficar abaixo do gate:**
  1. Aumentar `n_samples` e/ou `steps` no YAML; subir `model_size` de `small` para `medium`.
  2. Reforçar `custom_negative_phrases` em PT-BR (os negativos automáticos do livekit-wakeword são
     enviesados para inglês — alerta da própria doc oficial).
  3. Complementar a base sintética com **gravações reais** de voz PT-BR (incluindo voz feminina).
  4. Em último caso, reavaliar engine paga (Porcupine/Sensory) com **decisão de custo explícita do
     dono** — fora do escopo atual (conflita com R$ 9,90/mês). Não ligar a voz
     (`_voiceEngineAvailable=true`) sem passar o gate (ADR-0023).
