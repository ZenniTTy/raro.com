# 0024 — S2.C voz: SFSpeechRecognizer FUNCIONA (o "beco-sem-saída" da 0023 foi REFUTADO) — fix de reciclo + gates anti-repetição

- **Data:** 2026-06-10 → 2026-06-11
- **Duração:** sessão longa (várias compactações), centrada em device debug + reversão de conclusão arquitetural
- **Participantes:** Eduardo Rodrigues + Claude Code (Opus 4.8)
- **Branch:** `feat/camera-native-bridge`
- **Commits:** `57abed2`, `2685583`, `52fde9b`, `e33e7aa`, `c471c40`, `a6c8bfd`, `a43421a` (7 commits) + docs de close

## Objetivo

Entregar a voz funcional ("Raro gravar"/"Raro parar" acionando o mesmo save do REC) **sem** a migração de engine que a 0023 havia decidido. A sessão começou tentando treinar um modelo OpenWakeWord (ADR-0023) e terminou provando que **isso era desnecessário** — o SFSpeechRecognizer nativo e grátis, que a 0023 declarou beco-sem-saída, funciona para o escopo aceito (voz com **app aberto na tela**).

## Contexto inicial

A 0023 fechou com SFSpeech parqueado (`_voiceEngineAvailable=false`) e a decisão de migrar para OpenWakeWord — treinar modelo "Raro", ONNX Runtime + CoreML. O dono questionou repetidamente, ao longo da sessão, se valia a pena tanta complexidade num projeto de R$1.800 ("só precisa funcionar o básico mvp igual no ok camera") e, crucialmente, se o "bug" do SFSpeech ("funciona 1×") era real ou alucinação das pesquisas anteriores. Escopo reconfirmado pelo dono: voz só com **app aberto na tela** (background/locked é impossível no SFSpeech grátis, aceito); **não se preocupar com aprovação da loja**.

## O que foi feito

### Tentativa de treino (ABANDONADA) — `57abed2`, `2685583`, `52fde9b`
Notebook de treino migrado Colab→Kaggle (Colab desconecta por design), redirecionado download p/ `/kaggle/temp` (estouro de disco), n_samples 10000→2000 (não cabia nas 12h). **Tudo descartado** quando o dono questionou a premissa: não há modelo PT-BR pré-treinado público, treino é lento, e o caminho grátis já estava no código.

### Reabilitação do SFSpeech + coexistência com gravação — `e33e7aa`, `c471c40`
`_voiceEngineAvailable=true`. Voz passou a coexistir com a gravação via **2 fontes de áudio** (AVAudioEngine próprio quando câmera parada; buffers da `AVCaptureSession` via `appendAudioSampleBuffer` quando câmera ativa) + **dono único da AVAudioSession** (`automaticallyConfiguresApplicationAudioSession=false`, `.playAndRecord/.mixWithOthers`). Resolveu "raro parar não funciona durante a gravação" (a voz era desligada no REC).

### A CAUSA-RAIZ REAL (provada por log limpo) — `a6c8bfd` (parcial), `a43421a` (definitivo)
O sintoma da 0023 ("funciona EXATAMENTE 1×") **não** era limitação do endpointer/onset da Apple. Log do iPhone 12 (`pymobiledevice3 syslog live --match Runner`) provou: a `recognitionTask` era reciclada **a cada erro benigno `1110`** (no-speech, que o on-device emite por design ao detectar silêncio), gerando **521 reciclos vs 1 wake matched** num único PID (~6 reciclos/segundo, em rajadas a cada ~500ms). Na **janela morta** de cada reinício (~100-300ms até o task processar áudio) o `request` ficava `nil` → o comando dito ali era descartado. O `code=301` que aparecia era o `cancel()` do próprio reciclo (sintoma, não causa).

**Fix definitivo (`a43421a`, reescrita do `VoiceManager.swift`, +53/-27), sem trocar de engine:**
- **token de ciclo (`UUID`)**: `refreshCycle(token:)` só age se `activeCycle == token` → mata reciclo órfão/duplicado (o mesmo ciclo disparava reciclo por `result` E por `error`).
- **refresh único agendado**: `refreshWorkItem?.cancel()` antes de cada novo → não empilha `asyncAfter`.
- **ring buffer de `CMSampleBuffer`** (~24 buffers) replayado no request novo → **fecha a janela morta** (áudio dito no instante da troca não se perde). Limpo em `handleDetectedCommand` (evita re-detectar) e `teardownRecognition`.
- **refresh proativo a cada 50s** (não a cada erro) → previne decaimento de recurso do SFSpeech (doc Apple).
- **backoff só em erros TERMINAIS reais** (1101/1107/7/4/203/1700).

### Validação device (PROVA OBJETIVA)
iPhone 12, build profile, install confirmado via `devicectl` (`App installed:` container novo). Log do teste do dono ("funciona sem parar os 2"): **8 wake matched (4 start + 4 stop)**, **reciclos 521→7**, 0 debounce espúrio, 1 refresh proativo. Os dois comandos funcionam repetidamente durante a gravação. O anel de buffer travado (sintoma colateral) tem a mesma raiz (ponte Method Channel entupida de `onStateChanged`).

### Documentação anti-repetição (pedido explícito do dono)
- **Memória técnica nova:** `raro-pattern-sfspeech-continuous-no-recycle-per-error`.
- **Memória `raro-pattern-ios-wake-word-no-native-api` CORRIGIDA:** o diagnóstico "beco-sem-saída/funciona 1×" marcado como REFUTADO, com o registro histórico preservado p/ rastreabilidade.
- **2 memórias de processo:** `feedback_many_native_fixes_means_reread_logs_not_abandon_framework` (muitos fixes = re-ler log p/ causa real, não trocar de stack) + `feedback_verify_device_install_before_test` (confirmar install antes de pedir teste).
- **Gates §10 (CLAUDE.md):** linha p/ hot-path de voz/SFSpeech (verify install + prova de log) + linha transversal anti-abandono-de-stack (provar incapacidade por log limpo antes de ADR de troca).
- **Hook novo:** `.claude/hooks/warn-sfspeech-recycle-per-error.sh` (PreToolUse `.swift`, avisa ao mexer no ciclo de recognitionTask perto de erro/cancel) registrado em `settings.json` + CLAUDE.md §8 (9→10 hooks). Smoke-test ok, JSON válido.

## O que NÃO foi feito (e por quê)

- **ADR-0023 (OpenWakeWord) — DONO DECIDIU MANTER: background É necessário.** Quando surfaceada a opção de aposentar o ADR-0023 (já que SFSpeech resolve o foreground), o dono respondeu que **background/tela-bloqueada É necessário** e quer implementá-lo seguindo boas práticas, **sem quebrar o que já funciona** (SFSpeech foreground). Logo: SFSpeech foreground (entregue nesta sessão) **convive** com o motor de background OpenWakeWord (plano `2026-06-09-voice-wakeword-livekit-onnx.md`, parcialmente construído: `AudioSessionCoordinator`, ONNX Runtime SPM, `UIBackgroundModes:audio` já no projeto). **BLOQUEIO DURO:** o pipeline de background precisa do **modelo "Raro" treinado** (`raro_gravar.onnx`/`raro_parar.onnx`) — que NÃO existe e cujo treino é o muro desta sessão (Kaggle lento, sem modelo PT-BR pronto; Task 1 do plano PAUSA sem ambiente de treino). Caminho de treino local documentado: memória `raro-pattern-wakeword-train-cpu-piper-no-colab`. **Decisão de COMO destravar (treinar local vs. provar pipeline com modelo pré-treinado) pendente do dono.**
- **Caminho own-engine (telas sem câmera) NÃO tem ring buffer.** A janela morta só está coberta no path da câmera (CMSampleBuffer). Decisão consciente (Simplicity First): o caso real testado é tela-câmera-ativa; misturar CMSampleBuffer + AVAudioPCMBuffer no mesmo buffer seria especulativo. Tratar se "raro parar" falhar em outras telas.
- **Notebook de treino Kaggle** (`docs/superpowers/notebooks/raro-wakeword-training.ipynb`): commitado (rastreado, último toque `52fde9b`) como artefato do caminho OpenWakeWord abandonado. Pode ser removido se o dono decidir aposentar o ADR-0023; não atrapalha enquanto isso.
- **Gate §10 ffprobe da Frente A** (débito herdado da 0023): segue pendente.
- **Volume control:** Sprint 3.

## Aprendizados / surpresas

- **SFSpeechRecognizer FUNCIONA p/ wake-word contínuo no escopo on-screen — a conclusão da 0023 estava errada.** O "funciona 1×" era bug de arquitetura NOSSO (reciclar a cada 1110 benigno), não limite da Apple. O `1110` é só "no-speech" (silêncio); reciclar por causa dele deixa o motor surdo na janela morta. Quase custou uma migração inteira de engine (semanas de ONNX/treino) num projeto de R$1.800. Memória `feedback_many_native_fixes_means_reread_logs_not_abandon_framework`.
- **Muitos fixes empilhados ≠ "a ferramenta é incapaz".** O passo-atrás certo é re-ler o log LIMPO procurando a causa-raiz real e questionar o NOSSO uso da API — não abandonar o framework. O fix foi um 7º fix, não um motor novo. "Validação de mercado" (concorrente usa outra engine) provou só que ele tem escopo maior (background), não que SFSpeech é inadequado ao nosso escopo.
- **Confirmar install no device ANTES de pedir teste.** O build `a6c8bfd` falhou ao instalar (exit 1) mas pedi o teste; o dono testou o binário VELHO e os logs vieram idênticos (521 reciclos) — quase lido como "fix não funcionou". Métrica idêntica ao teste anterior = suspeita de install falho. Memória `feedback_verify_device_install_before_test`.
- **Pesquisa antes de propor caminho caro.** Gastou-se energia em treino/Picovoice/Sensory antes de exaurir o que já estava no código (SFSpeech desabilitado) + checar modelos públicos. O dono cortou isso perguntando "não tem repositório público?".

## Próximos passos

- **Decisão do dono sobre ADR-0023:** com SFSpeech funcionando no escopo on-screen, aposentar/addendar o ADR-0023 (OpenWakeWord) ou mantê-lo como caminho futuro p/ background? Registrar a decisão.
- **Limpar artefatos do treino abandonado** (notebooks Kaggle) do working tree.
- **Validar voz em telas sem câmera** (own-engine path) se o dono quiser voz fora da câmera — pode precisar do ring buffer lá também.
- **Gate §10 ffprobe da Frente A** (débito herdado).
- **Backlog Sprint 2:** volume button, RevenueCat sandbox, share, analytics. Android nativo = Sprint 3.

## Referências

- **Arquivos:** `VoiceManager.swift` (reescrita), `CameraManager.swift`/`RecordingPipeline.swift`/`AppDelegate.swift` (wiring 2-fontes), `voice_controller.dart` (`_voiceEngineAvailable=true`), `CLAUDE.md` (§8/§10), `.claude/hooks/warn-sfspeech-recycle-per-error.sh`, `.claude/settings.json`.
- **Memórias:** `raro-pattern-sfspeech-continuous-no-recycle-per-error` (nova), `raro-pattern-ios-wake-word-no-native-api` (corrigida), `feedback_many_native_fixes_means_reread_logs_not_abandon_framework` (nova), `feedback_verify_device_install_before_test` (nova).
- **ADRs:** ADR-0022 (voz SFSpeech — engine validada nesta sessão), ADR-0023 (OpenWakeWord — premissa refutada p/ escopo on-screen, decisão pendente).
- **PRs:** nenhum novo (PR #2 segue draft).

---

## Atualização (continuação da sessão) — investigação de background + CRUX PROVADO + decisão de modelo próprio

Depois do foreground entregue, o dono confirmou que **background É necessário** e pediu para seguir boas práticas **validando tudo em fonte primária** (Context7/WebSearch) para não repetir o desperdício da voz.

### Validações de fonte primária (Apple docs/forums, 2026-06-11)
- **SFSpeech é foreground-only por restrição FUNDAMENTAL do iOS** (erro 1700 em background). Não adianta tentar — comprovado. Background exige detector próprio sobre `AVAudioSession` de background.
- **Câmera não roda em background** (política de privacidade); desde iOS 7 a `AVCaptureSession` compartilha a `AVAudioSession` do app → áudio acoplado à câmera morre junto no background → app suspenso (`BackgroundTaskSuspended`, observado no device).
- **Mic-only em background É viável** (`UIBackgroundModes:audio` + `playAndRecord` + restart pós-interrupção). Tudo gravado na memória `raro-pattern-ios-wake-word-no-native-api`.

### CRUX PROVADO no iPhone 12 (de-risca a feature inteira)
Experimento `BackgroundAudioProbe` (sonda descartável no AppDelegate, depois revertida): ligou o `AudioSessionCoordinator` (mic-only, já no projeto) + heartbeat de frames, com SFSpeech gated off. **Resultado:** com a tela bloqueada (21:04:33→21:05:06), o heartbeat continuou firme (frames 50→600, cadência ~5s, 7 batimentos em background), **zero suspensão, zero interrupção**. O mic próprio sobrevive ao background. Prova completa em `docs/superpowers/notes/voice-background-crux-proof-iphone12.md`. A sonda foi revertida (foreground SFSpeech restaurado); a fundação `AudioSessionCoordinator` permanece commitada (37c863c).

### Decisão de engine de background (validada por custo)
- **Picovoice Porcupine** (validado 2026-06-11): cria "Raro" em minutos, SDK Flutter, PT-BR, leve p/ background — MAS free tier = 1 device com marca d'água; custom keyword + produção = **~US$6.000/ano (Enterprise)**. Inviável p/ app de R$9,90/mês (~280 assinantes/ano só p/ pagar). **Dono recusou o custo.**
- **DECISÃO: modelo próprio (ONNX/openWakeWord), grátis e vendável.** Treino via GPU alugada (~US$0,34/h, RunPod/Vast, <1h, <US$1) em vez do Colab/Kaggle instável. Próximo passo: análise de pontas soltas/incompatibilidades/breaking changes do caminho ONNX (Context7/WebSearch) ANTES de codar, depois executar o plano `2026-06-09-voice-wakeword-livekit-onnx`.

### Estado pós-continuação
- Foreground SFSpeech: funcionando e commitado (a43421a). Sonda revertida.
- **App no iPhone 12 ainda tem a sonda instalada (voz off)** — precisa de rebuild p/ restaurar a voz foreground no aparelho.
- Background: crux provado; falta detector ONNX + modelo "Raro" treinado (gate). É a próxima fatia.
