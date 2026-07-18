# ADR-0029 — Voz Android: SpeechRecognizer (foreground) + Vosk (background via FGS microphone)

- Status: Aceito
- Data: 2026-07-18
- Decisor: dono do produto (Eduardo)

## Contexto

No Android o reconhecimento de voz "raro gravar" / "raro parar" não existe — há apenas o stub Pigeon gerado (`VoiceApi.g.kt`), não registrado no `MainActivity`. O consumidor Dart (`features/voice/`) está completo e espera a implementação nativa. O iOS já funciona (SFSpeech foreground, restart-loop, ADR-0022).

O contrato Pigeon (`pigeons/voice_api.dart`) é fixo: `VoiceHostApi{isAvailable(async), startListening, stopListening}` + `VoiceFlutterApi{onWakeDetected(WakeCommand), onListeningStateChanged(VoiceListeningState)}`. Wake word = `"Raro"` de `raro_shared` (invariante), 2 comandos distintos (start/stop), NÃO toggle.

O dono pediu que o Android tenha escuta em **background** (tela apagada / app minimizado), "melhor e mais moderna que o iOS". A Sensory (ADR-0028) é o motor definitivo candidato (pt-BR nativo, licença de produção), mas a comercialização ainda não fechou — decisão de produto ABERTA. É preciso uma ponte gratuita que não bloqueie a entrega do APK.

Esta decisão foi validada em **fonte primária** (developer.android.com, Maven Central, alphacephei.com/vosk — 2026-07-18, subagent researcher), corrigindo divergências da spec de 2026-07-17.

## Opções consideradas

### Foreground (app visível)
1. **`android.speech.SpeechRecognizer` on-device** — grátis, sem modelo bundled, latência baixa. `createOnDeviceSpeechRecognizer` é API 31; disponibilidade pt-BR on-device é device/OEM-dependente.
2. Vosk também no foreground — funciona, mas carrega 31MB à toa quando o on-device do sistema resolve.

### Background (tela apagada / minimizado)
1. **Foreground service type `microphone` (API 34) + Vosk** — `com.alphacephei:vosk-android:0.3.47` (Apache 2.0) + modelo `vosk-model-small-pt-0.3` (31MB). Precisão mediana, suficiente para spotting de 2 frases fixas com matching fuzzy.
2. **Sensory TrulyNatural** — motor definitivo, mas contrato não assinado. Não pode ser a dependência desta fatia.
3. **sherpa-onnx / openWakeWord** — sem modelo pt-BR (mesma parede do ONNX próprio, sessão 0029). Descartados.
4. **App fechado (swipe)** — sem caminho honesto no Android moderno. Fora de escopo.

## Decisão

**Motor ÚNICO (Vosk) para foreground E background, atrás do MESMO Pigeon (zero mudança de contrato):**

> **Revisão 2026-07-18 (pós-auditoria adversarial):** a arquitetura original propunha DOIS motores — `SpeechRecognizer` on-device no foreground + Vosk no background, com handoff por ciclo de vida. A auditoria provou que coordenar dois donos do microfone (`AudioRecord`) por tempo é intrinsecamente frágil: colisão de mic na transição (`ERROR_RECOGNIZER_BUSY`), estado `inBackground` travado, falha assíncrona de promoção a FGS. A doc oficial de *sharing audio input* confirma que captura concorrente é comportamento indefinido por OEM. **Decisão do dono: motor único.** Um só `AudioRecord`, um só dono do mic, o tempo todo — elimina a classe inteira de bugs de handoff na raiz (não mitiga).

- **Foreground E background = FGS type `microphone` + Vosk** (`vosk-android:0.3.47`, modelo pt 31MB) atrás da interface **`WakeEngine`** trocável (`VoskWakeEngine` hoje; `SensoryWakeEngine` futuro). O FGS roda enquanto a escuta está ativa (o app visível é suficiente para INICIAR o FGS microphone — while-in-use permite); quando o app minimiza, nada muda (mesmo motor, mesmo `AudioRecord`). **Zero handoff.**
- **Vosk é a PONTE gratuita** até a Sensory (ADR-0028) entrar. A interface `WakeEngine` é o ponto de troca.
- **`SpeechRecognizer` on-device NÃO é usado no v1** — mas o spike-gate (`SpeechRecognitionProbe.kt`) provou pt-BR on-device no M54, deixando o caminho nativo VIÁVEL como otimização futura (fatia dedicada, com handoff event-driven bem testado, OU só-foreground sem background). Não reintroduzir sem ADR.

### Correções materiais vs. spec 2026-07-17 (validadas em fonte primária)

1. **`checkRecognitionSupport`/`RecognitionSupport` = API 33, NÃO 31.** `createOnDeviceSpeechRecognizer` é 31, mas o mecanismo de *descoberta de idioma on-device* é 33. Com `minSdk 24`, o spike-gate e a detecção de pt-BR exigem **fallback por `Build.VERSION.SDK_INT`**: em 33+ usar `checkRecognitionSupport` + `getInstalledOnDeviceLanguages()` (BCP-47 `"pt-BR"` com hífen); em 24–32 tentar reconhecer e tratar `ERROR_LANGUAGE_NOT_SUPPORTED`. Memória `raro-pattern-android-speechrecognizer-checkrecognitionsupport-api33`.
2. **Vosk AAR = `0.3.47`** (LATEST no Maven Central, mar/2023). `0.3.50` é o tag do repo C++ `alphacep/vosk-api` — NÃO é o AAR Android, não usar.
3. **FGS microphone é *while-in-use*:** NÃO pode iniciar com app em background nem de `BOOT_COMPLETED`. A transição para o FGS tem que ocorrer com o app VISÍVEL; uma vez rodando, persiste com tela apagada. O design de "ligar escuta" parte de um estado app-visível.
4. **`vosk_flutter`/`vosk_flutter_2` mortos** (2023) → bridge Kotlin própria sobre o AAR.

### Permissões / manifest (cobertas por este ADR)

`FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_MICROPHONE` + `RECORD_AUDIO` + `<service android:foregroundServiceType="microphone">` + notificação fixa. A permissão `FOREGROUND_SERVICE_MICROPHONE` cabe aqui, sem ADR separado.

## Consequências

- **Dependência nova `com.alphacephei:vosk-android:0.3.47`** + asset de 31MB (`vosk-model-small-pt-0.3`) — cobertos por este ADR.
- **Opt-in:** toggle "Escuta em segundo plano" em Settings (persistido, fonte única — memória `raro-pattern-single-source-of-truth-persisted-settings`), desligado por default. Ao ligar: pedir isenção de otimização de bateria; Xiaomi → modal M02.
- **Spike-gate obrigatório** (1º passo do plan): provar `checkRecognitionSupport` pt-BR no M54 (API 36) ANTES da bridge completa. Se pt-BR on-device ausente → Vosk assume também o foreground (fallback definido).
- **Anti-lição iOS:** não reciclar o recognizer por erro benigno de silêncio (`ERROR_NO_MATCH`/`ERROR_SPEECH_TIMEOUT` → restart limpo esperado, contado em log). Métrica de validação = contagem de detecções em logcat (memória `raro-pattern-sfspeech-continuous-no-recycle-per-error`, sessão 0024).
- **Referencia o ADR-0028** explicitamente: Vosk é a ponte; Sensory é o destino.
- Contrato Pigeon **inalterado**; diff sem `.swift`.

## Pendências não bloqueantes (provar antes do release, não da fatia)

- Policy do Play Console sobre declaração de FGS microphone em targetSdk 34+ (não validada em fonte primária nesta rodada).
- Valores int e semântica de reciclo de `ERROR_NO_MATCH`/`ERROR_SPEECH_TIMEOUT` no modo contínuo — provar no device com log, igual iOS.
- Licença explícita por-modelo do `vosk-model-small-pt-0.3` (o AAR é Apache 2.0; os small seguem o padrão, mas a tabela não imprime por-linha).

## Referências

- Spec: `docs/superpowers/specs/2026-07-17-voz-android-speechrecognizer-vosk-design.md`
- ADR-0028 (wake phrases Sensory — engine definitivo)
- ADR-0022 (voz on-device iOS SFSpeech) / ADR-0024 (comando único vs toggle)
- Memórias: `raro-pattern-android-speechrecognizer-checkrecognitionsupport-api33`, `raro-pattern-sfspeech-continuous-no-recycle-per-error`, `raro-competitor-okcamera-android-apk-teardown` (params Sensory do concorrente)
