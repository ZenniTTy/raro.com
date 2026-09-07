# 0034 — Vosk AAR 0.3.75 (ELF 16 KB) + rollback isolado

- **Data:** 2026-09-07
- **Status:** Proposed (Accepted só após gate M54 abaixo)
- **Decisores:** Eduardo Rodrigues
- **Tags:** deps, voice, android, store
- **Parcialmente supersede:** pin Maven `vosk-android:0.3.47` do [0029](0029-voz-android-speechrecognizer-vosk-fgs.md)
- **Não toca:** arquitetura do ADR-0029 (motor único, FGS `microphone`, gramática, modelo `vosk-model-small-pt-0.3`) nem Sensory ([0028](0028-wake-phrases-two-word-commands-sensory.md))

## Contexto

A Play exige, desde 2025-11-01, que apps com `targetSdk` 35+ suportem page size 16 KB em **64-bit** ([Support 16 KB page sizes](https://developer.android.com/guide/practices/page-sizes)). No Galaxy M54 (Android 16) o APK debug abre o diálogo *"Este app não é compatível com 16 KB. Falha na verificação de alinhamento ELF"*. Fatia **5.6b** do PLANO-MESTRE.

Medição na sessão 2026-09-06 (`objdump -p` no `app-release.apk`):

| Pin | ABI 64-bit `libvosk.so` | Restante 64-bit (Flutter, CameraX, JNA, …) |
|---|---|---|
| `vosk-android:0.3.47` | LOAD `2**12` (4 KB) — **único** desalinhado medido | `2**14` |
| `vosk-android:0.3.75` | LOAD `2**14` (16 KB) | `2**14` |

`armeabi-v7a/libvosk.so` no 0.3.75 continua `2**12`. A exigência da Play é 64-bit (`arm64-v8a` / `x86_64`); 32-bit está isento.

O app já usa **AGP 8.11.1** (≥ 8.5.1): zip-alignment de `.so` **descomprimidas** no APK/AAB já é o default. `ndkVersion = flutter.ndkVersion`.

### O que `useLegacyPackaging` **não** resolve

A doc oficial reserva `jniLibs.useLegacyPackaging = true` para AGP **≤ 8.5**, quando o `bundletool` não zipalign APKs gerados a partir do AAB. Isso comprime as nativas e evita falha de **zip** alignment. **Não relinka** um prebuilt. Citação da mesma página: *"If your app uses any prebuilt shared libraries, you must also recompile them in the same way and reimport the 16 KB-aligned libraries."*

`libvosk.so` 0.3.47 vem pronto no AAR. Packaging não muda `p_align`.

### Tentativa 2026-09-06 (não isolada)

Bump `0.3.47 → 0.3.75` (Maven: 16 KB em [vosk-api#1752](https://github.com/alphacep/vosk-api/issues/1752); JNA `5.13.0 → 5.18.1` no POM 0.3.75). APK release 122.5 MB: diálogo 16 KB **sumiu**, boot OK, FGS `microphone` subiu, zero `UnsatisfiedLinkError`.

O gate de voz foi **declarado falho** (horas de logcat sem `vosk wake matched`) e o pin voltou a `0.3.47`. Depois, no **mesmo** device, o dono confirmou `ControlMode.volume` persistido (`raro.control.mode` = `volume`): o Dart chama `stopListening` se o modo não é voz. Copy da HUD ainda mostra “DIGA RARO” em Volume. **A regressão de voz não foi isolada do modo.** Não há prova de que o AAR 0.3.75 quebrou o `Recognizer`.

Java `org.vosk.Recognizer` (gramática JSON, `reset`) permanece a mesma API usada por `VoskWakeEngine`. Esta fatia **não edita** esse ficheiro.

## Opções consideradas

1. **`useLegacyPackaging = true` e manter 0.3.47**
   - Prós: zero risco à voz; uma linha Gradle.
   - Contras: não altera ELF `LOAD` de `libvosk.so`; Play continua a recusar 64-bit desalinhado. **Rejeitada** (fonte primária).
2. **Rebuild do `libvosk.so` 0.3.47 com NDK r28 / `-Wl,-z,max-page-size=16384`**
   - Prós: preserva o binário cuja voz foi provada no M54 (0038).
   - Contras: Kaldi/Vosk não é o nosso código; build próprio é fatia grande, sem pin Maven reproduzível, e ainda precisaria de ADR de proveniência. Reserva se a opção 3 falhar **isolada**.
3. **Bump Maven `0.3.47 → 0.3.75` sem tocar no motor** (retry com modo Voz confirmado)
   - Prós: AAR oficial Apache 2.0; ELF 64-bit já medido `2**14`; JNA 5.18.1 fecha o `libjnidispatch` 4 KB que a Play flagava no 0.3.70; API Java inalterada; rollback = uma linha Gradle.
   - Contras: salto Kaldi 2023→2025; se a voz falhar **com** `ControlMode.voice`, o pin volta a 0.3.47 — **sem** patch em `VoskWakeEngine`.
4. **Bump só até 0.3.70** (16 KB no `libvosk`, JNA 5.13)
   - Prós: mesmo JNA do pin atual.
   - Contras: Play ainda pode flagar `libjnidispatch` 4 KB (#1752 / #1989); 0.3.75 existe precisamente para isso. Não isola melhor a voz do que o 0.3.75.

## Decisão

**Retry `com.alphacephei:vosk-android:0.3.75`.** Motor, FGS, gramática e modelo **congelados**. O 16 KB fecha no AAR, não no nosso parser.

**Não** usar `useLegacyPackaging` como “fix 16 KB”. **Não** excluir ABI por relato alheio (x86_64) sem medir o **nosso** AAB.

**Rollback (se o gate falhar com modo Voz confirmado):** pin de volta a `0.3.47`; reverter o adendo do 0029 e a linha da Blueprint; **não** empilhar fix no `VoskWakeEngine`. Aí sim a opção 2 (rebuild 0.3.47) vira o próximo ADR.

## Gate M54 (esta ADR só vira Accepted com isto)

Build: `flutter build apk --release` com OpenJDK 21. Instalar no M54.

1. Settings → modo **Voz** (não Volume). HUD: ponto teal (`VoiceListeningIndicator`), não só “DIGA RARO”.
2. App aberto: “raro gravar” → “raro parar”. Logcat `RaroVoice`: `vosk wake matched` START e STOP. Sem transcript.
3. Home: os dois de novo (FGS).
4. Diálogo 16 KB **ausente**. Zero crash R8 / `UnsatisfiedLinkError`.
5. `objdump -p` em `lib/arm64-v8a/libvosk.so` = `2**14`.

## Consequências

- Positivas: desbloqueia AAB na Play (64-bit); JNA alinhada; pin Maven reproduzível.
- Negativas: voz congelada só é **reprovada** se o gate acima falhar; até lá o risco Kaldi existe.
- Reverter: uma linha em `apps/mobile/android/app/build.gradle.kts`.

## Referências

- [developer.android.com/guide/practices/page-sizes](https://developer.android.com/guide/practices/page-sizes) (2026-09-06)
- [alphacep/vosk-api#1752](https://github.com/alphacep/vosk-api/issues/1752) (0.3.70 alinhou `libvosk`; 0.3.75 sobe JNA 5.18.1)
- Maven: [vosk-android 0.3.47](https://repo1.maven.org/maven2/com/alphacephei/vosk-android/0.3.47/) (JNA 5.13.0) · [0.3.75](https://repo1.maven.org/maven2/com/alphacephei/vosk-android/0.3.75/) (JNA 5.18.1)
- ADR-0029 (arquitetura) · PLANO-MESTRE 5.6b
