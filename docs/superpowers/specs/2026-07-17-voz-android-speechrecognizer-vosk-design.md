# Spec — Voz Android: "raro gravar"/"raro parar" foreground + background — Fatia 3/4 pré-APK

> Data: 2026-07-17 · Status: design aprovado pelo dono · Pesquisa 2026-07-17 com fontes oficiais (developer.android.com, alphacephei.com/vosk, k2-fsa, pub.dev)
> Depende da Fatia 1 (gravação Android real) — sem ela o comando não tem o que executar.

## 1. Estado atual

- Pigeon pronto: `VoiceHostApi{isAvailable,startListening,stopListening}` + `VoiceFlutterApi{onWakeDetected(WakeCommand), onListeningStateChanged(VoiceListeningState)}` ([pigeons/voice_api.dart](../../../apps/mobile/pigeons/voice_api.dart)). Dart consumidor completo (`features/voice/`).
- Android: SÓ o stub gerado. Sem impl, NÃO registrado no `MainActivity.kt`.
- iOS: SFSpeech foreground funciona (restart-loop + `VoiceCommandParser` transcript matching; ADR-0022).
- Wake word = `"Raro"` de `raro_shared` (invariante). 2 comandos distintos (start/stop), NÃO toggle.

## 2. Pesquisa — decisões e descartes (2026-07-17)

| Opção | Veredito |
|---|---|
| `android.speech.SpeechRecognizer` on-device (API 31+) | **ESCOLHIDO p/ foreground.** Grátis, sem modelo. pt-BR on-device NÃO é garantido por doc — depende do "Speech Services by Google" do aparelho; **gate: `checkRecognitionSupport()` no M54 ANTES da bridge**. Não serve p/ serviço contínuo em background (sessões curtas, restart-loop frágil fora de UI). |
| Foreground service type `microphone` (Android 14+) | **ESCOLHIDO como arquitetura de background.** Exige `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_MICROPHONE` + `foregroundServiceType="microphone"` + notificação; só pode INICIAR com app visível; declaração no Play Console (targetSdk 34+). Com FGS ativo, captura segue com tela desligada. |
| Vosk (`vosk-model-small-pt-0.3`, 31 MB, Apache 2.0) | **ESCOLHIDO como engine de background.** Precisão mediana, suficiente p/ spotting de 2 frases fixas com matching fuzzy. Projeto em manutenção (última release 2024) — risco aceito. Plugin Flutter morto → bridge Kotlin própria sobre o AAR. |
| Sensory TrulyNatural | Motor DEFINITIVO candidato (pt-BR nativo, provado pelo concorrente) — preço pendente (NDA ok). A interface `WakeEngine` (§3) permite trocar Vosk→Sensory sem refazer serviço/Pigeon/UI. |
| sherpa-onnx KWS / openWakeWord | **Descartados**: sem modelo pt-BR (mesma parede do ONNX próprio, sessão 0029). |
| whisper.cpp | Descartado: não-streaming, bateria alta. |

**Limites honestos:** background = tela desligada/app minimizado COM serviço ligado antes. App fechado (swipe) = sem caminho em Android moderno; Xiaomi/Samsung podem matar mesmo o FGS (isenção de bateria + modal M02 mitigam). Concorrência de mic: outro app capturando pode silenciar o nosso (doc oficial sharing-audio-input).

## 3. Arquitetura

Duas camadas atrás do MESMO Pigeon (zero mudança de contrato):

```
VoiceHostApiImpl (Kotlin, registrado no MainActivity)
 ├── ForegroundVoiceRecognizer  — SpeechRecognizer on-device, restart-loop,
 │     VoiceCommandParser.kt (porta 1:1 do parser Swift; wake word de raro_shared
 │     via constante espelhada — hard rule "Raro")
 └── VoiceBackgroundService     — FGS type=microphone, notificação fixa,
       └── WakeEngine (interface) ← VoskWakeEngine (AudioRecord 16kHz mono → Vosk)
                                    [futuro: SensoryWakeEngine]
```

- **Handoff:** app visível → `ForegroundVoiceRecognizer`. Toggle background LIGADO + app vai pra background durante uso da câmera → FGS assume o mic. App volta → FGS libera, recognizer foreground reassume. Nunca os dois capturando juntos.
- **Comando detectado em background** → o FGS aciona a gravação via o mesmo caminho nativo do CameraManager (câmera precisa estar com sessão viva; se o SO matou a câmera, o comando loga e notifica em vez de crashar).
- **Opt-in:** toggle "Escuta em segundo plano" em Settings (persistido, fonte única — memória `raro-pattern-single-source-of-truth-persisted-settings`). Desligado por default. Ao ligar: pedir isenção de otimização de bateria; Xiaomi → modal M02.
- **Anti-lições iOS aplicadas:** não reciclar recognizer por erro benigno de silêncio (equivalente Android: `ERROR_NO_MATCH`/`ERROR_SPEECH_TIMEOUT` → restart limpo esperado, contado em log); métrica de validação = contagem de detecções em logcat (sessão 0024).

## 4. ADR

Vosk = dependência nova (AAR `com.alphacephei:vosk-android`) + asset de 31 MB → **ADR-0028 obrigatório antes do merge** (estratégia de engine de voz Android: SpeechRecognizer foreground + Vosk background com interface trocável p/ Sensory).

## 5. Erros

- `checkRecognitionSupport` sem pt-BR → `isAvailable=false` no foreground e Vosk assume também o foreground (fallback definido, não improviso).
- Falha de load do modelo Vosk / mic ocupado → `onListeningStateChanged(unavailable)` + log; nunca swallow.
- FGS negado/morto pelo SO → estado `unavailable`, UI reflete; sem retry infinito.

## 6. Validação (DoD)

1. **Spike-gate** (primeiro passo do plan): `checkRecognitionSupport` no M54 provando pt-BR on-device — resultado registrado na spec/PR.
2. M54 app aberto: "raro gravar" inicia gravação real (Fatia 1), "raro parar" finaliza — 5/5 detecções em logcat.
3. M54 minimizado (toggle on): comandos funcionam via FGS + Vosk.
4. M54 tela desligada: idem (com ressalva OEM documentada).
5. Notificação fixa visível durante o FGS; desligar o toggle mata o serviço.
6. `analyze` + suíte verdes; contract test Pigeon inalterado; diff sem `.swift`.
