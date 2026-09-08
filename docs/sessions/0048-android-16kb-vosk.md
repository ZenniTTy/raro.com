# Sessão 0048 — Android 16 KB / vosk-android 0.3.75 (5.6b, ADR-0034)

- **Data:** 2026-09-06/07
- **Participantes:** Eduardo Rodrigues + Cursor Grok
- **Branch:** `fix/android-16kb-page-size`
- **PR:** [#18](https://github.com/ZenniTTy/raro.com/pull/18) **MERGEADA** em `develop` (`a542699`, 2026-09-07)
- **Commits:** `8cfba51` `18775e5` `c2bb89f` `c8729de` (+ close desta sessão)

## Objetivo

Fechar o diálogo de alinhamento ELF 16 KB no Android 16 (Play / `targetSdk` 35+) **sem** tocar o motor Vosk. Única lib 64-bit desalinhada medida: `libvosk.so` do AAR `0.3.47` (LOAD `2**12`).

## Contexto inicial

Fatia 5.6b do PLANO-MESTRE. Gate: se a voz regredir no M54, **reverter o bump**, não empilhar patch em `VoskWakeEngine`. `useLegacyPackaging` não relinka prebuilt (doc oficial Android 16 KB). AGP já 8.11.1.

## O que foi feito

- Pin Maven `com.alphacephei:vosk-android:0.3.75` (JNA transitiva POM **5.18.1**). `VoskWakeEngine` **intacto**.
- ADR-0034 Accepted (fonte primária Maven + page-sizes). Adendo no ADR-0029 só na coordenada Maven.
- Blueprint §2.3 e `CLAUDE.md` pin 0.3.75 (senão o próximo `/prime` restaurava 0.3.47).
- **Prova M54 (APK release 122,5 MB, mesmo pid):** diálogo 16 KB ausente; 64-bit `unaligned=0`; FGS `microphone` sobe; dono: “raro gravar” / “raro parar”; logcat `vosk wake matched -> START/STOP` (pid **20104**). Sem transcript.
- A “voz morta” da 1ª tentativa **não era o AAR**: `ControlMode.volume` persistido (`raro.control.mode` = `volume`) faz o Dart chamar `stopListening`.
- Review PR #18 (aprovada): R8 `-keep class com.sun.jna.**` — `*` não cobre `ptr/` e `internal/` (Cleaner 5.18.1; memória `raro-pattern-android-release-r8-strips-jna-vosk`).

## O que NÃO foi feito (e por quê)

- Medir o **AAB** (Play valida o bundle; `bundletool` reempacota `.so`). `flutter build appbundle --release` falhou em `GeneratedPluginRegistrant` + `integration_test` (javac release). Fora desta fatia. Ressalva no 5.6b / ADR-0034.
- Pin Gradle explícito da JNA (entra transitiva; CI limpo pode resolver outra versão).
- `abiFilters` — `libvosk.so` arm64 8,86 → 10,04 MB (+13%); splits do AAB mitigam.
- Copy “DIGA RARO” no modo Volume — backlog (custou horas de logcat).
- Reabrir ONNX / Sensory / motor Vosk.

## Aprendizados / surpresas

- Hipótese “0.3.75 quebra a voz” foi **desmentida** no device. Conferir `ControlMode` e o HUD antes de acusar o AAR.
- `armeabi-v7a/libvosk.so` continua `2**12`; Play isenta 32-bit.
- R8 keep com um `*` é a mesma classe de bug do UnsatisfiedLinkError no boot — só aparece em release.

## Próximos passos

- Loja: 5.1 Apple Dev, 5.2 keystore (`CN=Android Debug`), 5.4/5.6 AAB assinado + medição ELF no AAB, 2.4/2.7 trial 30d nas lojas.
- Backlog: HUD Volume; P05a Lock; M02 Xiaomi; M03 Bluetooth.
- **Não reabrir** Vosk nem ONNX sem ADR.

## Referências

- ADR-0034 · ADR-0029 (addendum pin) · PLANO-MESTRE 5.6b
- [PR #18](https://github.com/ZenniTTy/raro.com/pull/18)
