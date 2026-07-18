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
| `android.speech.SpeechRecognizer` on-device | **ESCOLHIDO p/ foreground.** Grátis, sem modelo. `createOnDeviceSpeechRecognizer` = **API 31**; mas `checkRecognitionSupport`/`RecognitionSupport` = **API 33** (corrigido 2026-07-18 em fonte primária — a v1 dizia "31+", ERRADO). Com `minSdk 24` exige fallback por `SDK_INT`: 33+ usa `getInstalledOnDeviceLanguages()` (BCP-47 `"pt-BR"` com hífen); 24–32 tenta reconhecer e trata `ERROR_LANGUAGE_NOT_SUPPORTED`. pt-BR on-device NÃO é garantido por doc (device/OEM-dependente); **gate: `checkRecognitionSupport()` no M54 (API 36) ANTES da bridge**. Não serve p/ serviço contínuo em background. Memória `raro-pattern-android-speechrecognizer-checkrecognitionsupport-api33`. |
| Foreground service type `microphone` (Android 14+) | **ESCOLHIDO como arquitetura de background.** Exige `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_MICROPHONE` + `foregroundServiceType="microphone"` + notificação; só pode INICIAR com app visível; declaração no Play Console (targetSdk 34+). Com FGS ativo, captura segue com tela desligada. |
| Vosk (`vosk-model-small-pt-0.3`, 31 MB, Apache 2.0) | **ESCOLHIDO como engine de background.** AAR = `com.alphacephei:vosk-android:0.3.47` (LATEST no Maven Central, mar/2023 — confirmado 2026-07-18; **`0.3.50` é o tag do repo C++, NÃO o AAR Android, não usar**). Precisão mediana, suficiente p/ spotting de 2 frases fixas com matching fuzzy. `vosk_flutter`/`vosk_flutter_2` mortos (2023) → bridge Kotlin própria sobre o AAR. |
| Sensory TrulyNatural | Motor DEFINITIVO candidato (pt-BR nativo, provado pelo concorrente). Status por ADR-0028 (2026-07-17): comercialização ADIADA, contrato ainda não assinado. Vosk é a ponte gratuita ATÉ a Sensory entrar. A interface `WakeEngine` (§3) permite trocar Vosk→Sensory sem refazer serviço/Pigeon/UI — reconciliação explícita exigida no corpo do ADR-0029 (não são engines de background conflitantes; são fases da mesma decisão). |
| sherpa-onnx KWS / openWakeWord | **Descartados**: sem modelo pt-BR (mesma parede do ONNX próprio, sessão 0029). |
| whisper.cpp | Descartado: não-streaming, bateria alta. |

**Limites honestos:** background = tela desligada/app minimizado COM serviço ligado antes. **FGS type `microphone` é *while-in-use* (confirmado 2026-07-18): NÃO pode iniciar com app em background nem de `BOOT_COMPLETED`** — a transição para o FGS ocorre com o app VISÍVEL; uma vez rodando, persiste com tela apagada. App fechado (swipe) = sem caminho em Android moderno; Xiaomi/Samsung podem matar mesmo o FGS (isenção de bateria + modal M02 mitigam). Concorrência de mic: outro app capturando pode silenciar o nosso (doc oficial sharing-audio-input).

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

Vosk = dependência nova (AAR `com.alphacephei:vosk-android`) + asset de 31 MB → **ADR-0029 obrigatório antes do merge** (0028 já consumido em 2026-07-17 pelo ADR de wake phrases Sensory). O ADR-0029 cobre a decisão coesa: SpeechRecognizer foreground + Vosk background + foreground service `type=microphone` (a permissão `FOREGROUND_SERVICE_MICROPHONE` cabe aqui, sem ADR separado) + interface `WakeEngine` trocável. Deve **referenciar o ADR-0028** explicitamente: Vosk é a ponte gratuita Android até a Sensory entrar como engine definitivo — não são decisões conflitantes.

## 5. Erros

- `checkRecognitionSupport` sem pt-BR → `isAvailable=false` no foreground e Vosk assume também o foreground (fallback definido, não improviso).
- Falha de load do modelo Vosk / mic ocupado → `onListeningStateChanged(unavailable)` + log; nunca swallow.
- FGS negado/morto pelo SO → estado `unavailable`, UI reflete; sem retry infinito.

## 6. Validação (DoD)

0. **Confirmar install ANTES de pedir teste** (gate §10, memória `feedback_verify_device_install_before_test`): `flutter build` + install; ler `App installed:` + container UUID novo. Métrica idêntica ao teste anterior = binário velho — não pedir teste sem provar install fresco.
1. **Spike-gate** (primeiro passo do plan): `checkRecognitionSupport` no M54 provando pt-BR on-device — resultado registrado na spec/PR. **✅ PROVADO 2026-07-18 (M54, API 36):** `isOnDeviceRecognitionAvailable=true`; `installed=[pt-BR]` (instalado offline AGORA, não só supported); `PT_BR_ON_DEVICE_INSTALLED=true`. Design confirmado: SpeechRecognizer on-device = foreground, sem fallback Vosk no foreground neste device. Ferramenta: `voice/SpeechRecognitionProbe.kt`. Ressalva de produção: outros devices podem ter pt-BR só em `supported` (download) ou ausente — fallback SDK_INT + Vosk seguem necessários.
2. M54 app aberto: "raro gravar" inicia gravação real (Fatia 1), "raro parar" finaliza — 5/5 detecções em logcat.
3. M54 minimizado (toggle on): comandos funcionam via FGS + Vosk.
4. M54 tela desligada: idem (com ressalva OEM documentada).
5. Notificação fixa visível durante o FGS; desligar o toggle mata o serviço.
6. `analyze` + suíte verdes; contract test Pigeon inalterado; diff sem `.swift`.
