# 0032 — Prep do Bloco 1 (Firebase): conta + configs posicionados + CLI + reconciliação de harness

- **Data:** 2026-06-23
- **Duração:** ~1h30
- **Participantes:** Eduardo Rodrigues + Claude Code (Opus 4.8)
- **Branch:** `feat/camera-native-bridge`
- **Commits:** `f211d8e` (gitignore Firebase) + commit de reconciliação desta sessão

## Objetivo

Preparar o terreno do **Bloco 1 (Firebase)** do PLANO-MESTRE — o dono criou a conta Firebase e baixou os arquivos de config — e, a pedido dele ("Temos tudo documentado e atualizado no harness?"), auditar e reconciliar todo o drift que o prep introduziu, para a próxima sessão ter contexto completo. **NÃO** é o Bloco 1 em si (o código de integração não foi tocado).

## Contexto inicial

Saída da sessão 0031 (Bloco 0 fechado: Android compila, App ID alinhado a `com.rarocamera`, label "Raro Camera", ONNX dormente). O dono então, fora de sessão, criou um projeto Firebase no console (`raro-camera`), registrou os apps iOS+Android com bundle `com.rarocamera`, e baixou `GoogleService-Info.plist` + `google-services.json`. As deps Firebase já estavam no `pubspec.yaml` desde o bootstrap, mas Firebase nunca foi inicializado (sem `firebase_options.dart`, sem `initializeApp` no `main.dart`).

## O que foi feito

**Posicionamento seguro dos configs (decisão do dono: "mover e proteger tudo agora").** Os 2 arquivos tinham sido baixados na **raiz do monorepo** (lugar errado, e o git os via como untracked → risco de commit acidental de chaves reais). Movidos para os lugares canônicos: `GoogleService-Info.plist` → `apps/mobile/ios/Runner/`; `google-services.json` → `apps/mobile/android/app/`. Validados (plist XML OK via `plutil -lint`; json válido). Bundle/package confirmados = `com.rarocamera` nos dois (consistente com Bloco 0.3).

**Proteção no git (`f211d8e`).** Adicionadas ao `.gitignore` (raiz): `**/GoogleService-Info.plist`, `**/google-services.json`, `**/firebase_options.dart`. Provado via `git check-ignore` que ambos ficaram ignorados; `git log --all --full-history` confirma que **nenhuma credencial jamais entrou no histórico** (incluindo stash/reflog) — sem vazamento, sem necessidade de history-rewrite ou rotação de chave. Commit só do `.gitignore` (zero credencial staged, dupla-checado), pushado com pre-push gate verde.

**flutterfire CLI instalado.** `dart pub global activate flutterfire_cli` → 1.4.0 em `~/.pub-cache/bin`. ⚠️ O `~/.pub-cache/bin` **não** está no PATH; a edição do `.zshrc` foi **bloqueada pelo classificador de segurança** (corretamente — "preparar agora" não autoriza editar perfil de shell). Workaround registrado: `export PATH="$PATH:$HOME/.pub-cache/bin"` no comando, ou caminho absoluto.

**Auditoria adversarial do harness (workflow, 8 agentes: 4 dims audit + 4 verify).** A pedido do dono ("temos tudo documentado?"). Achou **7 drifts** (0 crítico). A camada de verificação **refutou 2 alegações fabricadas** por agentes auditores (um inventou que AGENTS.md afirma o bundle ID; outro citou linha velha do CLAUDE.md) e **achou 3 drifts que os auditores perderam** — provando o valor do verify adversarial. Cada achado foi reconferido por mim na fonte real antes de corrigir.

**6 drifts objetivos corrigidos (lote desta sessão):**
- **[ALTO] `AGENTS.md:44`** ensinava `bun --filter @raro/mobile run codegen` — forma que **falha** (`No packages matched the filter`). Corrigido p/ `bun run --filter '@raro/mobile' codegen` (memória `raro-pattern-bun-filter-arg-order`).
- **[ALTO] PLANO-MESTRE** dizia "depende: conta Firebase do cliente" em 3 lugares (45/106/119) como se nada tivesse começado. Atualizado: nota de pré-reqs prontos + checkboxes 1.1/1.2/1.3 mantidos **abertos** (código não feito) + mecânica gradle corrigida (plugins DSL em `settings.gradle.kts`, não classpath legado).
- **[BAIXO] `block-env.sh`** não cobria `firebase_options.dart` (que nascerá com chave real). Adicionado ao `case` (provado funcionalmente: bloqueia o novo, não regride o plist, permite arquivo normal).
- **[BAIXO] `block-infra.md`** listava a tarefa de gitignore como pendente — marcada feita (`f211d8e`) + nota de configs posicionados.
- **[ALTO/MÉDIO] `reinject-roadmap.sh`** (maior alavancagem — injeta estado em toda sessão): data `2026-06-22`→`2026-06-23` + bloco "Firebase Bloco 1 PRÉ-REQS PRONTOS" (conta/apps/configs/CLI/PATH). Sintaxe validada (`bash -n`) + smoke test.

## O que NÃO foi feito (e por quê)

- **Bloco 1 em si (código)** — `flutterfire configure`, `Firebase.initializeApp`, plugins gradle, 3 handlers Crashlytics: é a próxima sessão. Este prep só preparou o terreno.
- **Edição do `.zshrc`** — bloqueada pelo classificador de segurança (correto). Próxima sessão exporta o PATH no comando.
- **Mover o registro do prep para o 0031** — proibido (append-only; 0031 já fechado/pushado). Por isso este 0032.
- **2 drifts MÉDIO/BAIXO deixados como nota, não corrigidos:** CLAUDE.md:23 agrupa "Firebase mock" (impreciso — é "não inicializado", não mock) — cosmético, baixo valor; `0001-INDEX.md` "Próxima sessão" defasada — será naturalmente sobrescrita pela linha 0032. Anotados aqui para não virarem drift esquecido.

## Aprendizados / surpresas

- **Trabalho fora de sessão vira drift invisível.** Todo o prep (conta, arquivos, CLI) aconteceu ~15h após o 0031 fechar, e o único artefato versionado era um commit de 5 linhas no `.gitignore` que não explicava que os arquivos existem localmente. Sem este 0032, a próxima sessão (sem memória) poderia recriar o projeto Firebase ou perder tempo "reinstalando" o CLI.
- **Verify adversarial pega fabricação, não só erro.** Os agentes auditores inventaram 2 fatos (AGENTS.md tem bundle ID; CLAUDE.md:23 com texto velho). Sem a camada de verificação contra o arquivo real, eu teria "corrigido" coisas que não existem. Confirmar cada achado na fonte antes de agir não é opcional.
- **As chaves dos configs são REAIS** (`AIzaSy...`, não placeholder) — eleva a importância da rede de proteção. Mas confirmado: nunca vazaram (gitignored + nunca no histórico). O hook `block-env` já cobria plist+json; faltava só o `firebase_options.dart` futuro.
- **O hook de SessionStart é onde o estado certo se propaga de graça.** Corrigir `reinject-roadmap.sh` vale mais que 10 docs lidos sob demanda — toda sessão futura lê o estado certo do Firebase prep sem custo.

## Próximos passos

- **[PRÓXIMA SESSÃO] Bloco 1 — Firebase/Crashlytics (agora é só código):**
  - `flutterfire configure` (exportar PATH: `export PATH="$PATH:$HOME/.pub-cache/bin"`) → gera `firebase_options.dart` (gitignored).
  - `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` no `main.dart`.
  - Plugin gradle google-services (DSL moderno em `settings.gradle.kts` + `app/build.gradle.kts`, NÃO classpath).
  - Crashlytics 3 handlers (FlutterError + PlatformDispatcher + Isolate — memória `raro-pattern-crashlytics-3-handlers`).
  - Confirmar analytics events disparando.
  - **Gate pós-`flutterfire configure`:** `git status` deve mostrar que os 3 arquivos Firebase (plist/json/firebase_options) NÃO aparecem para commit.
- **Push** da branch `feat/camera-native-bridge`.

## Referências

- Plan: [PLANO-MESTRE-finalizacao-entrega-cliente.md](../superpowers/plans/PLANO-MESTRE-finalizacao-entrega-cliente.md) (Bloco 1 atualizado com pré-reqs prontos)
- Spec: [block-infra.md](../04-ROADMAP-SPECS/block-infra.md) (tarefa gitignore marcada feita)
- Hooks: `block-env.sh` (cobre firebase_options.dart), `reinject-roadmap.sh` (estado prep + data)
- Docs: `AGENTS.md` (bun filter corrigido)
- Commits: `f211d8e` (gitignore) + commit de reconciliação 0032
- Sessão anterior: [0031](0031-bloco-0-destravar-android-build-app-id-label-onnx-dormente.md)
