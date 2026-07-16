# 0031 — Bloco 0 do PLANO-MESTRE: destravar build Android + App ID + label + ONNX dormente

- **Data:** 2026-06-22
- **Duração:** ~2h30
- **Participantes:** Eduardo Rodrigues + Claude Code (Opus 4.8)
- **Branch:** `feat/camera-native-bridge`
- **Commits:** `3d24c13` (destravar build android), `74a6516` (teste de paridade android applicationId+label)

## Objetivo

Executar o **Bloco 0 do PLANO-MESTRE** (1 sessão = 1 entregável fechado): destravar e estabilizar o projeto para que compile e rode nas 2 plataformas, sem dívida silenciosa. Sub-tarefas: 0.1 destravar build Android; 0.2 decidir wake-word ONNX órfão; 0.3 resolver App ID Android divergente; 0.4 corrigir `android:label`.

## Contexto inicial

Saída das sessões 0029 (wake-word ONNX inviável → revertido p/ SFSpeech foreground) + 0030 (reconciliação de todo o harness + criação do PLANO-MESTRE). Estado de partida: iOS sólido no iPhone 12; **Android não compilava** (`CameraHostApiImpl.kt` sem `startRecording`/`stopRecording` que o `CameraApi.g.kt` regen 2026-06-07 exige); App ID Android divergente (`com.rarocamera.raro_mobile` vs `com.rarocamera` do iOS); `android:label` = "raro_mobile"; scaffold ONNX órfão no bundle. Wake-word background = STANDBY (dono negocia licença Sensory). Nenhum código de produção havia sido tocado desde a 0028.

## O que foi feito

**0.1 — Build Android destravado (`3d24c13`).** Implementado `startRecording`/`stopRecording` em `CameraHostApiImpl.kt` como stub síncrono que lança `FlutterError(code = "sessionFailed")` — a fronteira Pigeon converte em `PlatformException` limpa no Dart (não `UnsupportedOperationException` cru, que viraria code genérico). Conferido que o `recording_controller.dart` já trata via `on Object { state = RecordingIdle(); rethrow }` → falha graciosa, sem crash nem estado travado. **Drift extra descoberto no 1º build** (não previsto no doc): a regen Pigeon também trocou `CameraCapabilities.supportedResolutions/supportedFps` por `supportedFormats: List<FormatCapability>`; `CameraManager.discoverCapabilities` foi reescrito p/ montar a matriz (720/1080/4K × 30/60) com `requiresPhysicalLens = 4K@60` espelhando iOS/ADR-0021. Pré-scan do resto da árvore Kotlin (ReplayBuffer impl OK, nenhum outro uso dos campos removidos) evitou um 3º build cego. **Gate provado:** `flutter build appbundle` → `app-release.aab` (58.6MB) + 320 testes Dart verdes + 50 contract tests.

**0.2 — ONNX wake-word mantido dormente (decisão do dono).** Auditado: nada em produção referencia os 3 Swift (`WakeWordDetector`/`WakeWordPipeline`/`OnnxModelSession`) nem os 3 `.onnx` (~2,4MB) — são órfãos. Remover exigiria cirurgia no `project.pbxproj` (risco de quebrar build iOS que funciona) e o `ios_pbxproj_parity_test` **quebraria** (ele exige que esses Swift permaneçam referenciados). Como o dono negocia licença Sensory e o scaffold pode ser reaproveitado, mantido dormente com nota em `apps/mobile/ios/Runner/Native/Voice/README.md`. Histórico em `01a1f67`.

**0.3 — App ID Android alinhado ao iOS (`3d24c13`).** Dono escolheu `com.rarocamera` (igual iOS). Mudado só `applicationId` no gradle; `namespace` Kotlin segue `com.rarocamera.raro_mobile` (pode divergir — não afeta identidade nas lojas, evita renomear toda a árvore de fontes). Descoberto que `AppIdentity.applicationId` no `raro_shared` **já dizia** `com.rarocamera` desde sempre — o gradle é que estava em violação; o fix alinhou à fonte de verdade. Reconciliado Blueprint + CLAUDE.md + hook `reinject-roadmap.sh`.

**0.4 — `android:label` → "Raro Camera" (`3d24c13`).**

**Extra (`74a6516`) — fechada lacuna de harness levantada pelo dono.** Existia `info_plist_parity_test` validando `CFBundleIdentifier` no iOS, mas **nenhum** equivalente Android — foi por isso que o drift do applicationId sobreviveu meses. Renomeado `android_manifest_parity_test.dart` → `android_identity_parity_test.dart` (git mv, blame preservado) cobrindo: applicationId (gradle, **igualdade exata** não `contains` — pega regressão mesmo com prefixo compartilhado), `android:label` == `displayName`, namespace **pode** divergir (documenta a divergência intencional), permissões (preservado). **Provado red-before-green:** regredir applicationId e label fez o teste falhar; restaurado. 53 contract + 323 suite verdes.

## O que NÃO foi feito (e por quê)

- **Sem validação em device Android real** — não havia device conectado, e 0.1 é um stub "ainda-não-implementado" (não há gravação para testar). Provado por build + testes + análise de código da cadeia de erro. Prova de device vem no Bloco 3.1.
- **ONNX órfão NÃO removido do bundle** — decisão deliberada do dono (manter dormente). O ~2,4MB só importa no release (Bloco 5).
- **Nenhum ADR aberto** — confirmado que 0.1 só implementa o lado Kotlin de um contrato Pigeon **já existente** (schema `pigeons/*.dart` não tocado; `warn-adr-drift` observa o source, não a impl); contrato de gravação já coberto por ADR-0018/0020. App ID é decisão de produto (registrada no Blueprint), não de stack.
- **Bloco 1 (Firebase) não iniciado** — é a próxima sessão; depende da conta Firebase do cliente.

## Aprendizados / surpresas

- **O doc do Bloco 0.1 era necessário mas não suficiente.** "Implementar startRecording/stopRecording" destravava só o 1º erro; o build revelou um 2º (drift do `supportedFormats`). Lição reforçada: o gate é `flutter build appbundle passa`, não "implementei o que o doc listou". Goal-Driven Execution = loop até o critério objetivo, não até a checklist do doc.
- **A recomendação original do doc (remover ONNX) teria quebrado um contract test.** Perguntar ao dono em vez de seguir o doc cegamente evitou um breaking change no `ios_pbxproj_parity_test`. O harness tinha uma trava que o doc não conhecia.
- **Lacuna de simetria no harness é entropia que se esconde.** O drift do applicationId só sobreviveu porque havia gate iOS sem o par Android. Fechar a simetria (não só corrigir o valor) é o que impede a reincidência.
- **`cd` dentro de um comando Bash quebrou um restore relativo** durante o red-test: regredí o manifest, o `cd apps/mobile` mudou o cwd, e o `cp` de volta com caminho relativo falhou silenciosamente — o manifest ficou com o valor regredido. Peguei porque **verifiquei o estado em vez de assumir** o restore; corrigi via `git checkout --`. Lição: em red-tests destrutivos, restaurar pela fonte de verdade do git (não por backup relativo) e sempre conferir o working tree depois.
- **Pre-commit lefthook ≠ pre-push.** O pre-commit roda dart-format/biome/block-secrets; o **pre-push** roda `lint && test && test:contract`. O `test:contract` (gate §10 obrigatório p/ mudança de bridge) **não** dispara no commit — tem que ser rodado à mão antes de declarar pronto. Na 1ª passada eu tinha pulado; o dono perguntou e eu rodei (50→53 verdes).

## Próximos passos

- **[PRÓXIMA SESSÃO] Bloco 1 — Firebase/Crashlytics** (depende da conta Firebase do cliente): `flutterfire configure`, `GoogleService-Info.plist` + `google-services.json`, `Firebase.initializeApp` no `main`, plugin gradle; Crashlytics 3 handlers (memória `raro-pattern-crashlytics-3-handlers`); confirmar analytics disparando.
- **Push da branch** `feat/camera-native-bridge` (2 commits desta sessão).
- **Backlog de harness (opcional):** considerar um contract test análogo p/ `versionName`/`versionCode` se virarem fonte de drift (hoje vêm do Flutter, sem risco).

## Referências

- Plan: [PLANO-MESTRE-finalizacao-entrega-cliente.md](../superpowers/plans/PLANO-MESTRE-finalizacao-entrega-cliente.md) — Bloco 0 marcado ✅
- ADRs: nenhum criado (0.1 implementa contrato existente ADR-0018/0020; 0.3 é decisão de produto no Blueprint)
- Arquivos: `CameraHostApiImpl.kt`, `CameraManager.kt`, `build.gradle.kts`, `AndroidManifest.xml`, `Native/Voice/README.md` (novo), `android_identity_parity_test.dart` (renomeado+ampliado), Blueprint, CLAUDE.md, `reinject-roadmap.sh`
- Commits: `3d24c13`, `74a6516`
- Sessão anterior: [0030](0030-harness-reconciliation-plano-mestre-entrega.md)
