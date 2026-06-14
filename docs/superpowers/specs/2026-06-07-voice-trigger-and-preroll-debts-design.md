# 2026-06-07 — voice-trigger-and-preroll-debts

> Spec S2.C (Sprint 2). Duas frentes sequenciais: limpar os 3 débitos do pré-roll (Frente A) e entregar a feature de voz (Frente B). Brainstorming concluído com o dono em 2026-06-07; decisões abaixo travadas via Q-table.

## Status

`Approved`

## Owner / Implementer

- **Spec owner:** Eduardo Rodrigues (assina o WHAT)
- **Implementer agent:** `implementer`
- **Validator agent:** `validator`
- **Test author:** `flutter-test-author` (TDD red-before-green)
- **ADR gate:** `adr-guardian` (Frente B toca contrato Pigeon)

## Reading order (pre-flight obrigatório)

1. `docs/briefing/original-briefing.md` (Seção 5.4 — comando de voz)
2. `docs/Blueprint.md` (Seção 1 divergência #1; Seção 4 voz)
3. `docs/briefing/prototype/Prototipo-RARO.html` (onboarding voz ~L760-790; Settings "Controle de Gravação" ~L1055-1110; hint câmera `DIGA "RARO" PARA GRAVAR`)
4. `CLAUDE.md` (manual autoritativo; §10 gates, §11 anti-patterns)
5. ADRs: ADR-0009 (wake word "Raro"), ADR-0003 + Addendum 2026-06-07 (pré-roll), ADR-0011 (volume não-BT), ADR-0020 (pipeline unificado), ADR-0021 (formato gravado / gate §10)
6. Memórias: `raro-competitor-okcamera-replay-model` (modelo de voz do concorrente, dump 2026-06-07), `raro-pattern-ios-wake-word-no-native-api` (SFSpeechRecognizer Option A), `raro-pattern-flutter-async-native-state-needs-notifier` (estado nativo-assíncrono = Notifier), `raro-pattern-single-source-of-truth-persisted-settings` (preferência persistida), `raro-preroll-rec-design-s2c` (débitos do combinado), `raro-pattern-ios-xctest-pbxproj-4-insertions`, `raro-pattern-permission-handler-ios-podfile-macros`

## Problem

O pré-roll embutido no REC fechou e foi device-validado (sessão 0022), mas ficou com **3 débitos conhecidos** no arquivo combinado (áudio-priming, DTS nas emendas, nome cosmético) e **a voz nunca foi implementada** — só existe `VoiceConfig.wakeWord='Raro'` no shared e um stub Pigeon (`voicePing`/`voiceReady`). O briefing (5.4), o protótipo (onboarding + Settings + hint) e o ADR-0009 exigem que o usuário possa acionar a gravação por voz dizendo "Raro". Esta sessão limpa os débitos da área já provada e liga o segundo gatilho do save (voz), como camada que reusa o MESMO fluxo do botão REC.

## Sizing (auto-sizing)

- [ ] Quick
- [ ] Medium
- [x] **Large** — novo ADR (voz/SFSpeechRecognizer), expansão de contrato Pigeon (`voice_api.dart`), feature nativa iOS + Dart + UI + Settings. Exige `/new-plan` + ADR mergeado antes do codegen + design-fidelity-checker na tela de voz.

## Q-table (decisões travadas no brainstorming 2026-06-07)

| # | Question | Answer |
|---|----------|--------|
| 1 | Ordem das duas frentes? | **Débitos primeiro**, depois voz (limpa a área provada antes de construir) |
| 2 | Modelo de ativação da voz (concorrente = default sempre-on vs protótipo = modo selecionável)? | **Modo selecionável (fiel ao protótipo)** — toggle Voz/Volume mutuamente exclusivos em Settings; Voz ON ativa o listener; botão REC sempre funciona como base |
| 3 | Engine de wake word? | **SFSpeechRecognizer on-device + transcript match** (Option A da memória; validado pelo dump — concorrente usa equivalente nativo Android, sem lib paga). `requiresOnDeviceRecognition=true`, restart loop antes do teto de 1 min, backoff exponencial |
| 4 | Como a voz reusa o save do botão sem duplicar lógica? | **Extrair o toggle para `RecordingController.toggle()`** (fonte única); botão e voz chamam o mesmo método. TDD pina o comportamento atual ANTES de mover |
| 5 | Default de fábrica do modo de controle? | **Voz ON** (fiel ao protótipo/onboarding "Diga Raro"; concorrente também) |
| 6 | Volume control (modo OFF do protótipo) entra agora? | **Não — Sprint 3.** Toggle existe e mostra Voz/Volume, mas o lado Volume fica desabilitado/"em breve" (bridge `volume_api` + ADR-0011 já existem, merece fatia dedicada) |
| 7 | Comandos de voz? | **Dois comandos: "Raro gravar" (start) + "Raro parar" (stop)** — mais explícito que o wake-único do concorrente. `WakeCommand { start, stop }` |
| 8 | "Raro parar" durante gravação (conflito de mic recognizer↔áudio do vídeo)? | **Implementar os 2; device gate decide se "parar" fica.** Se o áudio do `.mp4` ficar limpo com o recognizer ativo durante REC → "parar" por voz fica em v1.0; se degradar/mutar → "parar" vira Sprint 3 (com fix de áudio dedicado) e v1.0 entrega "gravar" por voz + parar por botão |
| 9 | Feedback de escuta? | **Sempre visível quando Voz ON** (consertar a "escuta escondida" do concorrente): `listening` = indicador discreto + hint `DIGA "RARO" PARA GRAVAR`; `paused`/`unavailable` = estado apagado com micro-texto, NUNCA some silenciosamente; wake detectado = micro-confirmação efêmera (reusa infra do `PrerollConfirmation`) |
| 10 | Etapa manual no iPhone 12? | Usuário avisa quando conectar; **pausar e avisar antes** de qualquer device gate manual |

## Observable goals (testes verificáveis)

### Frente A — débitos do pré-roll

- [ ] A1: combinado salvo no vault como `raro_<UUID>.mp4` (não `replay_<UUID>.mp4`); `_idFromPath` extrai o id corretamente; teste Dart pina o id derivado do novo prefixo
- [ ] A2: `ffprobe` no combinado mostra áudio começando em ~0s (sem gap de ~350ms no início) — gate device
- [ ] A3: `ffprobe`/ffmpeg re-mux do combinado **sem** warning `non monotonically increasing dts`; XCTest pina IDR por chunk nos `videoSettings`
- [ ] Regressão: combinado continua HEVC+AAC, dims/fps reais do REC (não do buffer), `isReplay:false`, frames todos presentes (re-rodar gate §10/ADR-0021)

### Frente B — voz

- [ ] B-contract: `VoiceHostApi` expõe `startListening/stopListening/isAvailable`; `VoiceFlutterApi` expõe `onWakeDetected(WakeCommand)` + `onListeningStateChanged(VoiceListeningState)`; codegen 4 (Dart gitignored, Swift+Kotlin trackados)
- [ ] B-state: `VoiceController` (`@riverpod` Notifier) transiciona idle→listening→paused→unavailable observável; reage ao setting de modo; `onWakeDetected(start)` chama `RecordingController.toggle()` (start), `onWakeDetected(stop)` chama toggle (stop)
- [ ] B-toggle: `RecordingController.toggle()` decide start/stop e monta `RecordingOptions` com pré-roll quando armado — comportamento idêntico ao `_onRecTap` atual (pinado por teste antes de mover)
- [ ] B-settings: toggle Voz/Volume em Settings persiste no `settingsController` (default Voz ON); selecionar Voz liga o listener, Volume desabilitado mostra "em breve"
- [ ] B-feedback: indicador de voz rende diferente para listening/paused/unavailable (widget test); some? nunca (assert de presença em paused)
- [ ] B-perms: autorização de speech/mic negada → `VoiceState.unavailable` + UI "ativar nas Configurações", sem crash, sem silêncio
- [ ] B-native (device): dizer "Raro gravar" com câmera aberta e Voz ON → inicia gravação com pré-roll; restart loop não estoura cota; autorização negada → unavailable
- [ ] B-mic-gate (device, decide Q8): gravar clipe com recognizer ativo → ffprobe + ouvir o áudio; limpo → "Raro parar" fica; degradado → "parar" = Sprint 3

## UI / protótipo

- **Onboarding voz** (~L765): copy `"Raro, começar a gravar."` — coerente com o comando "Raro gravar"
- **Settings "Controle de Gravação"** (~L1060): dois cards ON/OFF — `Voz ativa · Diga "Raro"` / `Volume · + ou −`. Nesta sessão o card Volume fica desabilitado com selo "em breve"
- **Hint na câmera** (ADR-0009): `DIGA "RARO" PARA GRAVAR` aparece quando Voz ON + não gravando
- **Permissões** (P-perms ~L788): item Microfone já descreve "Para áudio do vídeo e para escutar o comando 'Raro'."
- Tokens canônicos do Blueprint Seção 4; reusar infra de animação do `PrerollConfirmation`/`ReplayArmRing`
- Trial = 30 dias (locked invariant) em qualquer copy nova

## Out of scope

- **Volume / botões laterais** como gatilho (modo OFF do protótipo) → Sprint 3 (bridge `volume_api` + ADR-0011)
- **Voz em background** → inviável no iOS sem entitlement de aprovação Apple; roda em foreground
- **Voz no Android nativo** → Sprint 3 (paridade)
- **Idioma do reconhecimento PT/ES/EN selecionável** (concorrente tem) → fora; v1.0 usa o locale do device/pt-BR. Reavaliar com i18n
- **Transcrição/exposição do transcript na UI** → YAGNI + privacidade; só o sinal "detectei comando X"
- **Picovoice/Whisper** → só se métricas de produção mostrarem detecção <80% ou falso+ >5% (memória), via ADR futuro
- **"Raro parar" durante REC** se o device gate provar que degrada o áudio → Sprint 3

## Risks

| Risco | Severidade | Mitigação |
|-------|-----------|-----------|
| Recognizer ativo durante REC degrada/muta o áudio do `.mp4` (disputa de mic com `AVCaptureAudioDeviceInput`) | MÉDIA-ALTA | Device gate (Q8) decide; fallback = "parar" por botão, recognizer pausa no REC |
| Rate limit SFSpeechRecognizer (1000 req/h) esgota com restart agressivo → para de escutar silenciosamente | MÉDIA | `requiresOnDeviceRecognition=true` (sem cota de servidor na prática) + backoff exponencial + estado `paused` SEMPRE visível na UI |
| Falso positivo de "raro" em fala normal PT | MÉDIA | Match só do comando completo ("raro gravar"/"raro parar"), não da palavra solta; threshold ajustável; métrica futura |
| Mover toggle do `_onRecTap` quebra o save device-validated | MÉDIA | TDD pina o comportamento atual (start/stop/pré-roll) ANTES de extrair; Surgical Changes |
| A2/A3 (áudio-priming/DTS) alteram o encode → regressão no formato gravado | MÉDIA | Gate §10/ADR-0021 obrigatório: ffprobe no `vault/<id>.mp4` combinado no iPhone 12 prova dims/fps/codec + emenda limpa |
| Modo de voz em estado efêmero por feature dessincroniza/não persiste (bug da 0022) | MÉDIA | Modo vive no `settingsController` persistido (memória `single-source-of-truth-persisted-settings`); `VoiceController` reage ao setting |
| XCTest novo não roda (some do alvo silenciosamente) | BAIXA-MÉDIA | 4 inserções no `project.pbxproj` (memória); verificar `Test Suite started` + contagem, não exit 0 |

## ADRs necessários

- [x] ADR existente: ADR-0009 (wake word "Raro") — base
- [x] ADR existente: ADR-0003 + Addendum (pré-roll) — débitos referenciam
- [ ] **ADR novo (Frente B, `adr-guardian` confirma): "Voz on-device com SFSpeechRecognizer — modo selecionável, foreground-only, dois comandos"** — formaliza engine (sem lib paga), modelo selecionável (vs concorrente default-on), restart loop + backoff, foreground-only no iOS, expansão do contrato `voice_api`. DEVE estar mergeado no branch ANTES do codegen do Pigeon (dispara `warn-adr-drift`)
- [ ] Débitos (Frente A) NÃO exigem ADR novo (não mudam stack nem contrato; são mitigações dentro do `ReplayBuffer.swift` já coberto pelo ADR-0003)

## Build sequence (alto nível; detalhe no plan)

1. **Frente A** (sem contrato Pigeon): A1 (nome) → A3 (IDR/DTS) → A2 (áudio-priming) → gate §10 device (avisar usuário)
2. **Frente B**: ADR novo (adr-guardian GO) → contrato Pigeon + codegen → TDD `RecordingController.toggle()` (pin antes de mover) → extrair toggle → TDD `VoiceController` → native `VoiceManager.swift` (+ pbxproj XCTest) → Settings toggle + persistência → feedback UI → plug wake→toggle → device gate (avisar usuário) → mic gate decide Q8

## References

- Briefing Seção 5.4 (comando de voz)
- Blueprint Seção 1 (divergência #1 wake word), Seção 4 (voz)
- Protótipo: onboarding voz, Settings "Controle de Gravação", hint câmera
- ADRs: 0009, 0003 (+Addendum), 0011, 0020, 0021
- Memórias: ver Reading order #6
- Dump do concorrente: `/tmp/raro-competitor-voice-dump/` (screenshots + XML, sessão S2.C 2026-06-07)
