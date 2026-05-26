# 0001 — Bootstrap do projeto (Fases 1–5)

- **Data:** 2026-05-25
- **Duração:** ~6h (incremental, multi-sprint)
- **Participantes:** Eduardo Rodrigues (humano) + Claude Code (AI)
- **Branch:** `develop`
- **Commits:** `c40e55d` (initial) até `1869c43` (sprint 5.4-fixes) — 32 commits total — ver `git log`

## Objetivo

Executar o skill `bootstrap-mobile-flutter` contra o briefing do projeto RARO (Raro Camera) para sair do "repo vazio com briefing" para "monorepo completo, documentado, com harness e workflow spec-driven configurado".

## Contexto inicial

- Repo `develop` com 1 arquivo: `original-briefing.md` (briefing imutável)
- Protótipo Claude Design disponível em URL interna Anthropic (`api.anthropic.com/v1/design/...`)
- Tentativas iniciais de fetch falharam (404, depois passou de 10MB do WebFetch)
- Resolução: Eduardo salvou `Prototipo RARO.html` (99KB) e `raro-logo.png` na root do repo manualmente

## O que foi feito

### Fase 1 — Blueprint (commit `da902f8`)

- Briefing movido para `docs/briefing/original-briefing.md` (imutável)
- Protótipo movido para `docs/briefing/prototype/Prototipo-RARO.html` + asset `raro-logo.png`
- Context7 + pub.dev consultados para fixar versões de 14 libs
- 6 divergências briefing × protótipo identificadas e resolvidas:
  1. Wake word: `"Raro"` (não OkCamera) — Eduardo + protótipo prevalecem
  2. Free trial: 30 dias (não 15) — Eduardo decidiu briefing prevalece
  3. Planos: ambos mensal + anual — protótipo prevalece
  4. Volume buttons: implementar — protótipo prevalece
  5. Tradução em tempo real: fora de escopo
  6. Onboarding Xiaomi: híbrido (auto MIUI + manual)
- Blueprint v1.0 escrito em `docs/Blueprint.md` com aprovação registrada

### Fase 2 — Scaffold (commits `fe07c7b` → `a2585c3`, 6 µ-sprints)

- 2.1 — `package.json` root, `bunfig.toml`, `.editorconfig`, `.gitignore`
- 2.2 — `apps/mobile` via `flutter create org=com.rarocamera`, pubspec com 14 deps fixadas, `analysis_options.yaml` strict, smoke test
- 2.3 — `packages/shared` Dart puro com `AppIdentity`, `VoiceConfig` (wakeWord='Raro'), `SubscriptionConfig` (freeTrialDays=30), 6 enums, 26 event names
- 2.4 — `turbo.json` + `biome.json` + `package.json` wrappers em workspaces
- 2.5 — `lefthook.yml` (pre-commit + pre-push + commit-msg) + `commitlint.config.cjs` com scope-enum
- 2.6 — `setup.sh` idempotente em 5 steps

### Fase 3 — Foundation (4 µ-sprints, commits `9703cc5` → `4f0d133`)

- 3.1 — `AGENTS.md` thin redirect + `CLAUDE.md` manual autoritativo de 13 seções com Karpathy 4 princípios
- 3.2 — `docs/01-PROJECT.md` até `10-CHANGELOG.md` + `docs/index.md`
- 3.3 — `docs/decisions/0000-template.md` + ADRs 0001 a 0012 derivados do Blueprint
- 3.4 — `0000-template.md` de sessions + `0001-bootstrap.md` (este arquivo) + `0001-INDEX.md`

### Sprint 2.7-fixes (5 commits retroativos pós-Fase 3)

Sprint disparado por pergunta crítica do usuário ("Tudo o que fizemos seguiu boas práticas? Nada foi alucinado?"). Auditoria interna encontrou 5 gaps:

- 2.7-1 (`8ea4d47`) — `01-PROJECT.md` dizia "15 dias + nota explicando que é 30"; reescrito para "30 dias" direto sem contradição.
- 2.7-2 (`3a01580`) — hook `dart-format` em `lefthook.yml` tinha `cd "$(dirname {staged_files})"` que ia quebrar com múltiplos arquivos; corrigido para `dart format {staged_files}` direto.
- 2.7-3 (`9f83059`) — warning "14 packages incompatible" investigado: todas são transitive deps travadas por `flutter_test`/`riverpod_lint`. Registrado em ADR 0001 com explicação completa.
- 2.7-4 (`53a571c`) — smoke test do mobile expandido: além de `find.text('RARO')`, agora valida `VoiceConfig.wakeWord=='Raro'`, `freeTrialDays==30`, `bundleId=='com.rarocamera'`, ambos SKUs presentes.
- 2.7-5 (`85fc636`) — `README.md` minimal criado (repo tinha 131 arquivos tracked sem README).

### Fase 4 — Harness (6 µ-sprints, commits `70afb5d` → `d29cbb5`)

- 4.1 — `.claude/` estrutura + `settings.json` mínimo
- 4.2 — 4 hooks passivos: `block-env.sh`, `block-secrets.sh`, `format-dart.sh`, `reinject-roadmap.sh`
- 4.3 — 4 hooks ativos: `run-riverpod-codegen.sh`, `analyze-changed-dart.sh`, `warn-adr-drift.sh`, `verify-task.sh`
- 4.4 — 7 subagents em `.claude/agents/`: `implementer`, `validator`, `adr-guardian`, `researcher`, `flutter-test-author`, `flutter-perf-auditor`, `design-fidelity-checker`
- 4.5 — 8 slash commands em `.claude/commands/`: `commit`, `session-end`, `docs-lint`, `prime`, `new-spec`, `new-plan`, `verify-slice`, `ingest-source`
- 4.6 — `slice-checklist.md` + `settings.json` final integrando 8 hooks em 4 eventos

### Sprint 4.7-fixes (5 commits retroativos pós-Fase 4)

Segunda rodada de auditoria do usuário. Achados:

- 4.7-1 (`b46e5c8`) — `$schema` URL em `settings.json` apontava para schema inexistente; removido.
- 4.7-2 (`7690981`) — `verify-task.sh` em Stop event rodaria `bun run lint && test` (~5-10s) a cada turno do agente; movido para utilitário invocável manualmente.
- 4.7-3 (`e560e48`) — `analyze-changed-dart.sh` redundante com `bun run lint` no pre-push; removido do disco e do settings.json.
- 4.7-4 (`e3f2b0f`) — `warn-adr-drift.sh` tinha blacklist hardcoded de ADRs 0000-0012 que ia quebrar quando ADR 0013 fosse criado; reescrito para detectar arquivos com status `A` em `docs/decisions/`.
- 4.7-5 (`5092dc1`) — `setup.sh` não validava `python3` apesar de 6 dos 7 hooks dependerem dele; adicionado `need python3` + nota no README.

### Fase 5 — Spec-Driven (3 µ-sprints, commits `0a559f7` → `0cd5d97`)

- 5.1 — `docs/superpowers/specs/0000-template.md` + `docs/superpowers/plans/0000-template.md` com 7 execution rules e Phase 0 pre-flight
- 5.2 — `CLAUDE.md` Seção 6 com workflow TLC 4 fases (Specify → Design → Tasks → Execute) + auto-sizing Quick/Medium/Large + sinais que escalam
- 5.3 — `docs/10-CHANGELOG.md` expandido com tudo entregue + validação final 100% verde

### Sprint 5.4-fixes (em andamento)

Terceira rodada de auditoria. Drift documental detectado:

- 5.4-1 (`1869c43`) — `reinject-roadmap.sh` listava 4 hooks; atualizado para 7 + harness completo.
- 5.4-2 (este commit) — este arquivo (`0001-bootstrap.md`) estava congelado em Fases 1-3; estendido para Fases 1-5 + sprints retroativos.
- 5.4-3 — `0001-INDEX.md` atualizar tabela.
- 5.4-4 — `docs/index.md` adicionar seção `.claude/`.
- 5.4-5 — `README.md` remover "Docker" (não usado em projeto client-only) e adicionar `.claude/` à árvore.

## O que NÃO foi feito (e por quê)

- **Primeira feature spec** (`feat/camera-native-bridge`) — bootstrap entrega os templates e o workflow, mas não cria spec real. Esse é o próximo passo pós-bootstrap, fora do escopo desta sessão.
- **Fontes TTF** (Space Grotesk / Inter / JetBrains Mono) — declaração no `pubspec.yaml` foi removida no µ-sprint 2.2 porque os `.ttf` não existem. Serão adicionados como spec `chore/native-fonts` ou no primeiro spec de tema.
- **Firebase config files** — `google-services.json` / `GoogleService-Info.plist` ausentes intencionalmente (criados pelo cliente em sua conta Firebase, NÃO commitados — bloqueados por hook `block-env`).
- **RevenueCat API keys** — fora do escopo do bootstrap, configurar via env vars no primeiro spec de subscription.
- **Build release** (`.ipa` / `.aab`) — exige signing certs do cliente; fora do escopo.

## Aprendizados / surpresas

- **`flutter_lints ^7.0.0` foi alucinação minha.** Real era `^6.0.0`. Validei via `curl pub.dev/api/...` depois do erro do `flutter pub get`. Reforça: nunca pular o Context7/pub.dev gate.
- **`custom_lint 0.8.1` × `riverpod_lint 3.1.3` incompatíveis.** Riverpod adiantou pra analyzer 9, custom_lint ainda em analyzer 8. Solução: remover `custom_lint` explícito — `riverpod_lint 3.1.3` virou standalone com `analysis_server_plugin`. Importante registrar para devs futuros que tentem adicionar `custom_lint` "de volta".
- **`cd` no Bash tool não persiste entre chamadas.** Causou `apps/apps/mobile/` lixo quando criei o Flutter num `cd apps && flutter create mobile`. Lição: sempre caminhos absolutos.
- **Hook `block-secrets` me pegou** ao commitar o próprio `lefthook.yml` que usa palavras "api_key", "password" em regex. Refinei o pattern para casar atribuições com valor base64-like ≥16 chars.
- **`commitlint subject-case lowercase` me pegou** em `Fase 2 µ-sprint 2.5` (capital F). Não tirei a regra — confirmou que o gate funciona. Mensagens em português exigem atenção.
- **Endpoint Claude Design retorna bundle inteiro >10MB** independente de `?open_file=`. WebFetch tem teto de 10MB → impossível fetch do protótipo via tool. Solução foi Eduardo baixar e salvar localmente. Vale registrar como pattern para projetos futuros.

## Próximos passos (pós-bootstrap)

Bootstrap completo. Próxima sessão deve:

1. Abrir em nova sessão para que `reinject-roadmap.sh` injete contexto e os 8 slash commands fiquem disponíveis.
2. Rodar `/new-spec camera-native-bridge` — primeira feature do Roadmap prioridade 1 ([docs/04-ROADMAP.md](../04-ROADMAP.md)).
3. Invocar `superpowers:brainstorming` para preencher a spec.
4. Avaliar sizing (Quick/Medium/Large) — `feat/camera-native-bridge` provavelmente Large (novo native bridge + ADR de contrato).
5. Se Large: `/new-plan camera-native-bridge` e seguir workflow TLC completo.

Especialmente atenção a:
- Contract test em iOS + Android desde o início (gate do `slice-checklist.md`)
- ADR de contrato JSON do Method Channel `com.rarocamera/camera`
- Discovery de lentes 0.5×/1× em devices reais (Simulator não exibe lente ultra-wide)

## Referências

- [Blueprint.md](../Blueprint.md)
- [decisions/0001-stack-decisions.md](../decisions/0001-stack-decisions.md) até `0012`
- Commits: `git log --oneline` no branch `develop`
