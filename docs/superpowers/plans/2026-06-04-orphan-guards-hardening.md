# Proposta — Guardas órfãs (anti-recorrência) · hardening

> **Status:** Proposta (read-only). Levantada na auditoria de pré-flight S2.B (sessão 0018). **Não implementada** — documenta o gap e a guarda proposta para cada erro órfão. Executar exige sessão própria (1 sessão = 1 entregável) ou anexar como sub-tarefa de uma sessão de teste.

## Contexto

A auditoria de pré-flight S2.B inventariou 27 guardas vivas e cruzou-as contra todos os erros já cometidos (60 de session logs + 52 de memórias). Resultado: **10 erros órfãos** — erros cujo *fix está no código* mas **sem guarda viva** (hook que bloqueia / teste que pega) que impeça a recorrência. Hoje eles dependem só de memória passiva (avisa SE lida no contexto; não bloqueia nada).

Os erros de **segurança e convenção** já têm trava automática (block-env, block-secrets, block-forbidden-terms, block-pigeon-error-rawvalue, forbidden_literals_test, parity tests, commitlint, deny `--no-verify`). Os órfãos são, em sua maioria, **bugs de runtime/arquitetura** que os testes de widget mockados não pegam — exatamente a classe que mais machuca a S2.B (100% nativa AVFoundation + estado async).

## Gap estrutural transversal

**Os XCTests nativos (RunnerTests) não rodam no lefthook nem em CI** — só manualmente via `bun run --filter @raro/mobile test:ios`. Toda a guarda de câmera/gravação/foco/thumbnail validada por XCTest é, na prática, uma trava que ninguém puxa automaticamente. Para a S2.B isto é o gap mais relevante. **Proposta transversal:** decidir se `test:ios` entra no pre-push (custo: tempo de build iOS no commit) ou se vira passo obrigatório do `/verify-slice` com evidência anexada.

## Os 4 órfãos de alta severidade para a S2.B

### 1. Vault sidecar race (escrita atômica tmp+rename)
- **Erro:** `writeAsString` trunca antes de reescrever; galeria lendo via `listAll` na janela → `FormatException: Unexpected end of input`. Fix em `vault_service.dart` (tmp+rename atômico).
- **Por que órfão:** `vault_service_test` cobre save/list/delete/thumbnail, mas **nenhum** teste exercita `listAll` concorrente durante `write` nem assegura escrita atômica. Alguém pode reverter o tmp+rename para `writeAsString` direto e a suíte fica verde.
- **Relevância S2.B:** o replay grava mais arquivos no vault → mesma janela de race.
- **Guarda proposta:** teste Dart de regressão — disparar `save()` e `listAll()` concorrentes (`Future.wait`) N vezes e assertir que `listAll` nunca lança `FormatException`; OU assertir que nenhum `.json.tmp` órfão aparece. Reforço opcional: lint custom proibindo `writeAsString` direto em `.json` de metadata fora do helper atômico.

### 2. `ref` após dispose em listener async
- **Erro:** `ref.read`/`invalidate` depois de `await` num listener de stream lança "Cannot use Ref after disposed" se o provider foi disposto no gap. Fix: ler deps síncronas no `build` + `if (ref.mounted)` após await.
- **Por que órfão:** nenhum hook/lint/teste detecta uso de `ref` após `await` sem guard. A suíte roda providers **isolados** — o bug aparece só **em sequência** (passa isolado, falha em sequência). `grep` no `test/` por `ref.mounted` retorna vazio.
- **Relevância S2.B:** o `replay_buffer_provider` vai escutar stream nativo = exatamente o padrão que causou o bug.
- **Guarda proposta:** teste Dart que faz dispose do container no meio de um listener async e assegura ausência do throw; rodar a suíte de providers **em sequência no mesmo processo** (não isolada) para expor o bug. Opcional: regra de analyze custom / hook que avisa quando callback async de `ref.listen`/stream usa `ref.read|invalidate` sem `ref.mounted` após `await`.

### 3. Estado nativo-async precisa Notifier reativo
- **Erro:** gravação/sessão/wake/volume que muda via callback nativo com classe plana + bool local dessincroniza (REC travou no iPhone 12, sessão 0016). Também: recording sem `AVCaptureAudioDeviceInput` → `.mov`/`.mp4` mudo.
- **Por que órfão:** testes de widget com repo mockado **explicitamente não pegam** (declarado na memória); só device/log real. Nenhum gate automatizado exige Notifier reativo nem assegura input/output de áudio. Hard gate §10 é passivo.
- **Relevância S2.B:** o `replay_buffer_provider` tem estado que muda por callback nativo (enabled/saving/saved/failed).
- **Guarda proposta:** combinação — (a) lint/grep que sinaliza bool local de estado de gravação/sessão fora de um `@riverpod` Notifier; (b) XCTest no RunnerTests assertindo que a sessão de captura inclui caminho de áudio (replay/gravação não saem mudos); (c) `integration_test` on-device no gate de PR quando toca `recording_controller`/`camera_controller`/replay. (c) depende de resolver o gap estrutural acima.

### 4. Declarar pronto sem validação em device
- **Erro:** declarar feature de câmera/foco/gravação/lifecycle pronta sem run em iPhone físico.
- **Por que órfão:** só regra escrita em CLAUDE.md §10 (passiva). Nada automatizado verifica que houve run em device antes de marcar done; os XCTests que validariam parte disso nem rodam em pre-push/CI.
- **Relevância S2.B:** a S2.B é toda nativa; só device pega a regressão de coexistência/preview/foco.
- **Guarda proposta:** passo no `/verify-slice` (e idealmente gate de PR) que exige **evidência anexada** (trecho de Xcode Console com `os_log` do subsystem dedicado, ou saída de `integration_test --machine` on-device) quando o diff toca `CameraPlatformView`/`AVCaptureDevice`/Method Channel/recording/replay. Sem evidência, `/verify-slice` falha.

## Os 6 órfãos de severidade média/baixa (registro, sem ação imediata)

| # | Erro | Severidade S2.B | Guarda proposta (resumo) |
|---|---|---|---|
| 5 | SPM Firebase 15-vs-13 (deployment target) | média | teste no `test:contract` lendo o `Package.swift` gerado e falhando se achar `.iOS("13.0")` com Firebase nas deps |
| 6 | video_player leak / falta de dispose | média | teste de widget montando/desmontando preview assegurando `dispose`; lint sinalizando `VideoPlayerController` em widget de lista |
| 7 | flutter_tester órfãos travam commit | baixa | passo no início do lefthook pre-commit que detecta/mata engines `flutter_tester --disable-vm-service` vivos |
| 8 | dart-format reflow aborta commit | baixa | alinhar job dart-format do lefthook ao padrão biome (`--write` + `git add` em vez de `--set-exit-if-changed`) — trade-off a discutir |
| 9 | late final AnimationController dispose crash | baixa | lint/hook `.dart` avisando AnimationController como `late final` fora de `initState`; ou teste pump+dispose imediato |
| 10 | pumpAndSettle timeout com animação infinita | baixa | documentar no template de teste; auto-corrige (autor vê o timeout na hora) |

## Recomendação

Para a S2.B, os órfãos 1-3 (vault race, ref-after-dispose, Notifier reativo) são os que **mais provavelmente recorrem** porque o replay buffer reúne todos os três padrões (grava no vault + provider escutando stream nativo + estado async). A `flutter-test-author` pode escrever os testes de regressão (1, 2) red-before-green dentro da própria sessão de implementação da S2.B, sem precisar de sessão separada. O órfão 4 (device gate) e o gap estrutural (XCTest em CI) são decisões de processo a alinhar com o usuário.

## Referências

- Auditoria de pré-flight S2.B: sessão 0018 (a criar no fechamento)
- Memórias: `raro-pattern-vault-sidecar-atomic-write-race`, `raro-pattern-riverpod-ref-after-dispose-async-listener`, `raro-pattern-flutter-async-native-state-needs-notifier`, `feedback_device_debug_use_real_logs_not_assumptions`, `raro-pattern-flutter-spm-ios-13-hardcoded`, `raro-pattern-flutter-video-player-disposal`, `raro-pattern-flutter-tester-orphans-block-commit`, `raro-pattern-dart-format-hook-reflow-aborts-commit`, `raro-pattern-flutter-late-final-animationcontroller-dispose-crash`, `raro-pattern-flutter-pumpandsettle-infinite-animation-timeout`
- CLAUDE.md §8 (hooks), §10 (hard gates contextuais)
- ADR-0016 (harness E2E híbrido)
