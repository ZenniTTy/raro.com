# Notas de treino — modelo wake-word "Raro"

> Registro vivo do treino dos classificadores de voz do RARO. Suporta o gate de viabilidade do iPhone 12 (ADR-0023).
>
> ## ⚠️ CORREÇÃO 2026-06-11 (sessão 0024) — supersede VoxCPM/Kaggle abaixo
> - **TTS = Piper** (não VoxCPM): VoxCPM exige CUDA pesado e é proibitivo; o caminho prático é Piper PT-BR. `livekit-wakeword` usa Piper.
> - **Venue = GPU Linux alugada (RunPod/Vast ~US$1-4)**, NÃO Kaggle nem Mac. O treino exige Linux+CUDA (Piper synthetic-gen + trainers Linux/WSL2); Kaggle funciona mas é mais lento e tem cap semanal. Memória `raro-pattern-wakeword-train-cpu-piper-no-colab` (corrigida).
> - **Pinar deps** do livekit-wakeword/openWakeWord (~fev/2026 — breaking changes torchaudio 2.10+/Piper/speechbrain). Não usar `main` cru.
> - **Lado iOS:** onnxruntime 1.24.2; CoreML EP via `appendCoreMLExecutionProviderWithOptions:`; mel roda em CPU/XNNPACK.

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

O detector roda **3 sessões ONNX em cadeia**: áudio -> `melspectrogram` -> `embedding_model` ->
`<classifier>`. Os 4 arquivos vão para `apps/mobile/ios/Runner/Resources/`.

| Arquivo | Papel | Input (nome, shape, dtype) | Output (nome, shape) | Stateful? |
|---|---|---|---|---|
| `melspectrogram.onnx` | Áudio 16 kHz mono -> mel spectrogram | áudio PCM 16 kHz mono (nome/shape **a confirmar via Passo 6/18 do notebook**) | mel features (**a confirmar via Passo 6/18**) | Não (transform puro) |
| `embedding_model.onnx` | Mel -> embeddings (Google speech embedding, frozen) | mel features (**a confirmar via Passo 6/18**) | embeddings (**a confirmar via Passo 6/18**) | Não (transform puro) |
| `raro_gravar.onnx` | Classificador do comando **START** | `embeddings`, `(1, 16, 96)`, float32 (batch dinâmico) | `score`, `(1, 1)` | Não (a sessão ONNX é stateless) |
| `raro_parar.onnx` | Classificador do comando **STOP** | `embeddings`, `(1, 16, 96)`, float32 (batch dinâmico) | `score`, `(1, 1)` | Não (a sessão ONNX é stateless) |

Observações:
- **Opset 18** nos classificadores (confirmado na doc oficial de export). Quantização INT8 opcional
  geraria `<model_name>.int8.onnx` (não usada por padrão neste fluxo).
- O **contrato dos classificadores** (`embeddings (1,16,96)` float32 -> `score (1,1)`) é fixo e
  confirmado na doc oficial; é o que a Task 3 (Swift) assume. Os shapes dos dois estágios genéricos
  (`melspectrogram`/`embedding_model`) saem na saída do **Passo 6/18 do notebook** — registrar aqui
  quando rodar.
- **O DETECTOR (camada Swift) é STATEFUL**, mesmo as sessões ONNX sendo stateless: ele mantém um
  **ring buffer de embeddings de 16 frames** (janela ~2 s = 32.000 samples a 16 kHz produz 16
  embeddings) e desliza essa janela a cada chunk de áudio antes de chamar o classificador. O estado
  (buffer + cooldown/debounce) vive no `WakeWordDetector`, não no grafo ONNX.

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

## Métricas medidas (preencher após rodar)

> **PREENCHER APÓS KAGGLE.** Valores saem do Passo 7 (tamanhos) e Passo 8 (recall/FP) do notebook.

| Modelo | Recall (eval offline) | FP/hora (eval) | Tamanho `.onnx` | `n_samples` | `steps` | `model_size` | Data do treino |
|---|---|---|---|---|---|---|---|
| `raro_gravar.onnx` | _(preencher)_ | _(preencher)_ | _(preencher)_ | _(preencher)_ | _(preencher)_ | _(preencher)_ | _(preencher)_ |
| `raro_parar.onnx` | _(preencher)_ | _(preencher)_ | _(preencher)_ | _(preencher)_ | _(preencher)_ | _(preencher)_ | _(preencher)_ |

Tamanho dos genéricos (registrar uma vez): `melspectrogram.onnx` = _(preencher)_ ·
`embedding_model.onnx` = _(preencher)_.

Notas livres do treino (o que variou, voz que falhou, ajuste de `n_samples`, etc.):

- _(preencher)_

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
