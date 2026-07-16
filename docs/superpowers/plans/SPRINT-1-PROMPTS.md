# Sprint 1 — Prompts (Foundation + Walking Skeleton iOS)

> ✅ FECHADO (histórico, 2026-06-22). Sprint 1 concluído. Roadmap vigente = `PLANO-MESTRE-finalizacao-entrega-cliente.md`. Mantido como registro.

> **Uso**: este arquivo contém TODOS os prompts copy-paste para sessões da Sprint 1. Abra → encontre o prompt → copie → cole em chat novo Claude Code. Self-contained: não precisa abrir outros arquivos.

**Entrega Sprint 1**: cleanup memórias/CLAUDE.md/docs + merge `feat/camera-native-bridge` em `develop` + 12 telas Flutter navegáveis no iPhone 12 com Riverpod 3 providers swap-able (hard-coded data, signature real). Free Apple ID. iOS-only. Não paga $99. Não toca Android.

**Tasks Sprint 1**: A (cleanup) → B (workflow refactor) → C (camera merge) → D (splash + onboarding) → E (permissions + camera UI shell) → F (settings + gallery) → G (preview + paywall + checkout) → H (smoke test + closure).

---

## Como usar este arquivo

1. **Primeira sessão Sprint 1** → cole o prompt **"1.0 — Kickoff"** (audit completo 30-50min, gate, execução Task A).
2. **Sessões seguintes** → cole **"1 — Sessão de execução"** substituindo `[TASK]` pela letra (B/C/D/E/F/G/H).
3. **Última sessão** → cole **"1 — Sessão de closure"** (smoke test fim-a-fim + Blueprint mark).
4. **Quebrou algo** → cole **"Recovery"**.
5. **Sessão anterior pausou mid-Task** → cole **"Continuação"**.
6. **Só validar MD sem executar** → cole **"Audit-only"**.

---

## 1.0 — Kickoff (primeira sessão Sprint 1)

Cole este prompt EXATO, sem modificar:

```
Sessão Sprint 1 KICKOFF — Foundation + Walking Skeleton iOS.

═══════════════════════════════════════════════════════════════
CONTEXTO PROJETO (carregue antes de qualquer execução)
═══════════════════════════════════════════════════════════════

Projeto RARO: app Flutter (iOS + Android) de câmera pro consumidor final. Desenvolvedor único (não-engenheiro, dev 100% via Claude Code). Stack opinativa em docs/Blueprint.md §2. Após 6 sessões e 144+ commits, branch feat/camera-native-bridge tem 73 commits non-merged. Sprint 0 (sessão anterior) entregou: master plan v2 em ~/.claude/plans/glimmering-dancing-pnueli.md + 3 sprint MDs em docs/superpowers/plans/ + SPRINT-N-PROMPTS.md files. Nenhum código de produção tocado.

Estratégia 3-Sprint: Sprint 1 (walking skeleton + cleanup) → Sprint 2 (backend real iOS) → Sprint 3 (Android parity + TestFlight + cliente). Sprint 1 entrega: cleanup memórias/CLAUDE.md/docs, branch camera merged em develop, 12 telas Flutter navegáveis no iPhone 12, Riverpod 3 providers swap-able (implementação hard-coded mas signature real pra Sprint 2 substituir sem mudar UI). FREE Apple ID (Xcode rebuild 7-day refresh). NÃO toca Android. NÃO paga $99.

PRINCÍPIO Karpathy #4 (Goal-Driven Execution): 1 sessão = 1 entregável fechado declarado upfront. Mid-flight detours viram backlog de nova sessão.

═══════════════════════════════════════════════════════════════
FASE 1 — Contextualização (read-only, ~5 min)
═══════════════════════════════════════════════════════════════

1. Rode /prime (re-injeta Blueprint + INDEX + invariants locked).
2. Leia INTEIRO, na ordem:
   a) docs/Blueprint.md — atenção §2 (stack pinada), §5 (telas), §11 (roadmap 3-sprint)
   b) CLAUDE.md (manual autoritativo, todas seções)
   c) docs/superpowers/plans/sprint-1-foundation-walking-skeleton.md (executável desta sessão)
   d) docs/superpowers/plans/sprint-2-backend-logic-ios.md (validar consistência cross-sprint)
   e) docs/superpowers/plans/sprint-3-android-parity-testflight-client.md (validar consistência cross-sprint)
   f) docs/sessions/0001-INDEX.md (último estado)
   g) docs/sessions/0006-camera-task-19-focus-perf.md + docs/sessions/0007-sprint0-* se existir (estado mais recente)
3. Liste em ≤200 palavras: estado entrada ESPERADO pelo Sprint 1 MD (pre-flight checklist) vs estado REAL observado agora. Se há gap NOMEIE explicitamente (e.g., "pre-flight pede iPhone 12 conectado, não foi confirmado").

═══════════════════════════════════════════════════════════════
FASE 2 — Audit mecânico (1 agente Explore, ~5 min)
═══════════════════════════════════════════════════════════════

4. Despache 1 agente Explore com este prompt EXATO:

"Audit mecânico do docs/superpowers/plans/sprint-1-foundation-walking-skeleton.md. Para cada Task (A, B, C, D, E, F, G, H), validar:

(a) FILE PATHS: todos paths citados existem (apps/mobile/lib/features/*, apps/mobile/pubspec.yaml, CLAUDE.md, docs/Blueprint.md, etc.) OU são paths válidos pra criação nova (sem typo, sem diretório-pai inexistente).

(b) SHELL COMMANDS: sintáticos pra macOS zsh + bun + flutter. Especificamente validar:
    - bun --filter @raro/mobile run dev:ios -- -d <udid>
    - bun --filter @raro/mobile run codegen
    - flutter analyze, flutter test, flutter build ios
    - xcrun xctrace list devices
    - cp -r, rm, git status, git commit, git merge --no-ff, git push, git branch -d

(c) PLACEHOLDERS: nenhuma task contém TBD, TODO, 'implement later', 'similar to Task N' sem detalhe, 'add appropriate', 'fill in', '...'.

(d) REFERÊNCIAS:
    - Specs: docs/superpowers/specs/2026-05-28-camera-task-19-closure-design.md, docs/superpowers/specs/2026-05-26-camera-native-bridge-design.md
    - ADRs: docs/decisions/0010-dual-subscription-plans.md, docs/decisions/0015-camera-native-bridge-strategy.md
    - Memórias: listar quais memórias o MD cita E confirmar existência em /Users/eduardorodrigues/.claude/projects/-Users-eduardorodrigues-Documents-Projetos-Clientes-vitor-workana-app-raro/memory/

(e) CROSS-MD CONFLITO: ler também sprint-2-backend-logic-ios.md e sprint-3-android-parity-testflight-client.md. Há decisão técnica em Sprint 1 que será CONTRADITA por Sprint 2 ou 3? (e.g., Sprint 1 define provider signature que Sprint 2 não vai conseguir implementar; Sprint 1 cria estrutura que Sprint 3 quebra).

(f) GOALS BINÁRIOS: cada G1-G6 do Sprint 1 é mensurável objetivamente (não 'app funciona melhor' mas 'app abre splash, navega pra onboarding 1, exibe widget X')?

(g) DONE CRITERIA POR TASK: cada Task A-H tem DONE criteria observável (não interpretativo)?

(h) CONSISTÊNCIA TIPO: signatures/types/method names citados em Task posteriores (E, F, G) batem com o que foi definido em Tasks anteriores (D)?

Reporte em ≤500 palavras estruturado: PASS por critério (a-h) ou holes específicos (cite arquivo + linha + descrição do hole)."

═══════════════════════════════════════════════════════════════
FASE 3 — Audit best-practices 2026 via WebSearch + Context7 (1 agente Explore, ~15-20 min)
═══════════════════════════════════════════════════════════════

5. Despache 1 agente Explore com este prompt EXATO:

"Audit best-practices 2026 do Sprint 1 MD. Para cada item EXTERNO abaixo (dependência, API, padrão), valide via Context7 (preferência) OU WebSearch focado em maio 2026 best practices. Reporte: VERSÃO CURRENT? BREAKING CHANGES desde a versão pinada? RECOMMENDED ALTERNATIVE em 2026? Cite URLs.

Lista exaustiva de items pra validar (NÃO ignore nenhum):

1. **Flutter SDK 3.44+** ainda current em maio 2026? Há 3.45 ou 3.46 com breaking changes que afetariam walking skeleton (widgets, navigator, Material 3)?

2. **Riverpod 3 (flutter_riverpod ^3.3.1) com codegen (@riverpod annotation + part 'file.g.dart' + riverpod_annotation ^4.0.2 + riverpod_generator)** ainda canonical em 2026? Riverpod 4 foi lançado com breaking? Pattern `@riverpod class Foo extends _$Foo { @override Foo build() {} }` ainda recomendado?

3. **go_router ^17.2.3** ainda current ou há 18.x com migration obrigatória? Pattern com GoRouter routes + builder ainda recomendado?

4. **freezed_annotation ^3.1.0 + freezed (dev) ^3.x** ainda canonical em 2026 pra data classes / unions? Pattern @freezed class X with _$X ainda atual?

5. **permission_handler ^12.0.1** ainda current? Memória raro-pattern-permission-handler-ios-podfile-macros ainda aplicável (Podfile macros GCC_PREPROCESSOR_DEFINITIONS PERMISSION_CAMERA=1)?

6. **shared_preferences ^2.5.5** ainda current ou foi superseded por outra API (e.g., flutter_secure_storage padrão pra non-sensitive setting)?

7. **path_provider ^2.1.5** ainda current?

8. **video_player package (Flutter SDK)** ainda recomendado em 2026? Memória raro-pattern-flutter-video-player-disposal sobre dispose rigoroso ainda aplica?

9. **share_plus ^13.1.0** ainda current?

10. **device_info_plus ^13.1.0** ainda current?

11. **intl ^0.20.2** ainda current? Em Sprint 1 NÃO usado mas listed em pubspec — verificar se é dep ativa ou pode mover pra deps Phase 2.

12. **logger ^2.7.0** ainda canonical em 2026 pra logging Flutter?

13. **alchemist ^0.14.0** ainda current pra golden tests Flutter 3.44+?

14. **mocktail ^1.0.5** ainda canonical em 2026 vs mockito ou nova alternativa?

15. **Pigeon ^26.3.2** ainda current (Sprint 1 NÃO modifica Pigeon contracts mas Sprint 2/3 modificam — validar pra cross-sprint)?

16. **Bun como package manager pra monorepo Flutter** ainda padrão moderno em 2026 ou voltou pra npm/yarn/pnpm? Pattern `bun --filter @raro/mobile run X` ainda válido?

17. **lefthook** pre-commit ainda canonical vs husky/pre-commit (Python) em 2026?

18. **commitlint Conventional Commits 1.0.0** ainda padrão indústria 2026?

19. **biome** (ao invés de prettier/eslint) — config atual ainda canonical?

20. **iOS free Apple ID + Xcode 7-day cert refresh** workflow ainda funciona pra debug build em iOS 17/18/19 sem Apple Dev Program $99? Memória raro-pattern-flutter-debug-vs-release-on-device ainda válida?

21. **iOS 26 (se aplicável ao iPhone 12)** tem mudanças que quebrariam algo do walking skeleton (debug mode restriction, sandbox changes)? Memória relacionada existe?

22. **Flutter wireless debug iPhone** ainda funcional em maio 2026 ou Apple bloqueou (ver Flutter issues #135380, #119493)?

23. **CocoaPods → SPM migration ADR-0014** ainda recomendado em 2026 ou Apple/Flutter mudaram direção? Memória raro-pattern-flutter-spm-ios-13-hardcoded ainda relevante (Flutter 3.44 darwin.dart:71 issue)?

24. **Method Channels via Pigeon** vs alternative (e.g., FFI direto, Dart-Native interop nova) — Pigeon ainda canonical em 2026?

25. **Padrão feature folder layout** (lib/features/<feature>/{application,data,domain,presentation}) ainda canonical em 2026 pra Flutter+Riverpod ou comunidade migrou pra outro (e.g., flat lib/, ou DDD strict)?

26. **iPhone 12 hardware**: ainda recebe iOS updates em 2026? Memória raro-pattern-ios-avcapture-iphone12-dualwide-zoom-mapping ainda válida com firmware atual?

Reporte em ≤1200 palavras estruturado por item (1-26):
- Item: [nome]
- Status: CURRENT / DEPRECATED / SUPERSEDED
- Versão atual maio 2026: [vX.Y.Z]
- Breaking changes desde versão pinada no MD: [sim/não + detalhe]
- Recomendação: KEEP / UPGRADE / REPLACE com [alternativa]
- Source: [URL]

Para itens 20-26 (workflow + memórias), reporte: AINDA APLICÁVEL / OBSOLETO + evidência."

═══════════════════════════════════════════════════════════════
FASE 4 — Consolidação + Gate (você decide)
═══════════════════════════════════════════════════════════════

6. Consolide reports FASE 2 + FASE 3 num único relatório estruturado. Categorize cada finding:
   - **BLOQUEANTE**: file path inexistente, comando quebrado, dep DEPRECATED com migration obrigatória, contradição cross-MD, memória obsoleta que invalida task, breaking change desde versão pinada.
   - **WARNING**: API mudou mas é compatível, recomendação evoluiu mas atual ainda funciona, dep tem nova major mas não obrigatória.
   - **INFORMATIVE**: contexto histórico, opção alternativa.

7. Reporte pra mim em formato:
   - "BLOQUEANTES (X):" lista
   - "WARNINGS (Y):" lista
   - "INFORMATIVE (Z):" lista
   - "DECISÃO PROPOSTA: [executar | corrigir MD primeiro | escalar dúvida]"

8. AGUARDE minha confirmação explícita ANTES de FASE 5.
   - Se 0 BLOQUEANTES: posso aprovar "executar"
   - Se ≥1 BLOQUEANTE: corrigir MD primeiro com commit `docs(docs): sprint 1 md audit fixes` (lefthook GREEN, sem --no-verify)
   - Se dúvida estratégica (e.g., Riverpod 3 deprecated, refatorar todo Sprint?): escalar pra mim, eu decido

═══════════════════════════════════════════════════════════════
FASE 5 — Execução (APENAS após gate clean)
═══════════════════════════════════════════════════════════════

9. Execute Sprint 1 Task A inteira (A1 backup memórias → A2 auditar cada memória → A3 deletar critério-based → A4 merges → A5 CLAUDE.md §8 align → A6 commit 1 `chore(cleanup): align claude.md §8 hooks`).

10. Para cada step destrutivo (rm, git push, git branch -d, git checkout .), confirme comigo ANTES de executar. Mostre o comando proposto, espere meu OK.

11. Lefthook GREEN obrigatório em commits. Se falhar: pare, diagnose causa-raiz, NÃO use --no-verify.

═══════════════════════════════════════════════════════════════
FASE 6 — Closure
═══════════════════════════════════════════════════════════════

12. Rode /session-end:
    - registra entrada em docs/sessions/0008-sprint1-task-a-cleanup.md
    - define próximo objetivo "Sprint 1 Task B (workflow refactor)"
    - commit `chore(session): close 0008`

13. Reporte final em ≤200 palavras: tasks done, commits criados, blueprint §11 checkbox atualizado se aplicável, próxima sessão = "Sprint 1 Task B".

═══════════════════════════════════════════════════════════════
GUARDRAILS VIGENTES (não-negociáveis)
═══════════════════════════════════════════════════════════════

- "FORA DE ESCOPO" pra qualquer drift mid-task. Backlog vira nota.
- 1 sessão = Task A fechado. NÃO avance pra Task B sem nova sessão.
- Sem --no-verify em commits.
- Confirme destrutivos.
- Workflows multi-agent só FASE 2 + FASE 3 audits. Sem outros workflows adversariais.
- Se em qualquer momento sentir necessidade de "vamos auditar de novo", SINAL pra parar a sessão e abrir spec dedicada — não interromper Task A.
```

---

## 1 — Sessão de execução (Task subsequente, após Kickoff feito)

Cole substituindo `[TASK]` pela letra (B, C, D, E, F, G, H):

```
Sessão Sprint 1 — Task [TASK].

CONTEXTO: Sprint 1 já passou pelo Kickoff completo (audit FASE 1-4) em sessão anterior. Esta sessão executa apenas Task [TASK].

Setup (~3 min):
1. /prime
2. git log --oneline -10 + git status → confirme commits Tasks anteriores (A até [TASK-1]) presentes, branch limpa.
3. Leia docs/superpowers/plans/sprint-1-foundation-walking-skeleton.md APENAS seção "Task [TASK]" + "Riscos conhecidos" + "Out of scope".
4. Mini-audit (sem WebSearch — herda do Kickoff): file paths citados em Task [TASK] existem? Memórias citadas existem? DONE criteria observável? Cite holes em ≤100 palavras ou "Mini-audit clean".
5. Se holes mecânicos: corrigir MD primeiro com commit `docs(docs): sprint 1 task [TASK] md fixes`.

Execução:
6. Execute Task [TASK] step-by-step conforme MD. Confirme destrutivos comigo antes.
7. flutter analyze + flutter test GREEN antes de commit. Sem --no-verify.

Closure:
8. /session-end → entrada em docs/sessions/, próximo objetivo "Sprint 1 Task [PRÓXIMA]".
9. Reporte: tasks done, commits, blueprint § atualizado.

Guardrails idem Kickoff. 1 sessão = Task [TASK] fechado, não avance.
```

**Letras de Task válidas Sprint 1**: A (cleanup), B (workflow refactor), C (camera merge — exige validação perceptual no iPhone 12), D (splash + onboarding), E (permissions + camera UI shell), F (settings + gallery), G (preview + paywall + checkout), H (smoke test fim-a-fim + closure).

---

## 1 — Sessão de closure (Task H smoke test final)

```
Sessão de closure Sprint 1.

1. /prime
2. Verifique Blueprint §11 — todos checkboxes Sprint 1 Tasks A-G ✅ (exceto Task H que é esta sessão)? Se aberto, nomeie.
3. Smoke test fim-a-fim manual no iPhone 12: splash (1.5s) → onboarding 1 → "Próximo" → onboarding 2 → "Próximo" → permissions → "Permitir" → camera UI shell → tap REC (timer roda) → tap REC (para) → tap settings → mudar quality + replay duration → voltar → tap gallery → tap thumbnail → preview play/pause → voltar → camera com popup subscription (mockado pra não-subscribed) → tap CTA → paywall → selecionar plano → checkout → confirm → camera volta → trial countdown visível em Settings → About.
4. Sem crash. Sem regressão camera nativa (focus, lens 0.5x/1x, format).
5. Marcar Blueprint §11 Sprint 1 todos ✅.
6. Criar docs/sessions/<NNNN>-sprint1-closure.md + atualizar INDEX.
7. Commit final: `docs(blueprint): mark sprint 1 telas + cleanup done`.

Próxima sessão: Sprint 2 Kickoff — abrir SPRINT-2-PROMPTS.md (apenas se Sprint 1 todos ✅ E você confirmar disponibilidade pra backend logic real).
```

---

## Audit-only (validar Sprint 1 MD sem executar)

```
Audit-only Sprint 1 MD docs/superpowers/plans/sprint-1-foundation-walking-skeleton.md.

NÃO execute Tasks. Apenas:
1. /prime
2. Leia o MD inteiro + sprint-2 + sprint-3 (cross-MD check)
3. Despache 2 agentes Explore em paralelo:
   - Agente 1: rode o mesmo prompt FASE 2 do Kickoff 1.0 (audit mecânico)
   - Agente 2: rode o mesmo prompt FASE 3 do Kickoff 1.0 (audit best-practices 2026 via WebSearch + Context7)
4. Consolide em BLOQUEANTES / WARNINGS / INFORMATIVE.
5. AGUARDE minha decisão.

NÃO commita nada, NÃO altera código de produção.
```

---

## Recovery (algo quebrou)

```
Recovery session.

Sintoma: [descreva em 1-2 frases]

1. /prime
2. git status + git log --oneline -10
3. Identifique último commit estável (lefthook GREEN, analyze 0 issues, test PASS)
4. Reporte hipóteses + opções de recovery (revert vs fix forward)
5. NÃO faça reset destrutivo sem confirmação.

Se sintoma "Firebase iOS 15 vs 13": aplique memória raro-pattern-flutter-ios-regen-xcconfig-spm-recovery:
  - quit Xcode → bun --filter @raro/mobile run pub:get → rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-* → reabrir Xcode → aguardar Package Resolution → build via terminal.

Se sintoma "Build SUCCEEDED mas app não roda": memória raro-pattern-xcode-preaction-modifies-workspace:
  - xclogparser parse --file <log>.xcactivitylog --reporter flatJson → inspect Build Phases executadas.
```

---

## Continuação (sessão pausada mid-Task)

```
Continuação Sprint 1 Task [TASK].

Sessão anterior pausou mid-Task. Último estado:
[descreva]

1. /prime
2. git status + git log --oneline -5
3. Releia sprint-1-foundation-walking-skeleton.md seção "Task [TASK]" identificando próximo step não-concluído
4. Reporte: qual step faltava? Tem trabalho parcial não-commitado?
5. AGUARDE meu OK antes de prosseguir.
```

---

## Lembretes universais (vale pra TODA sessão Sprint 1)

- **`/prime` SEMPRE** no início — re-injeta Blueprint + INDEX + invariants.
- **Kickoff 1.0 SEMPRE faz audit completo FASE 1-4 ANTES de executar Task A**. Sessões subsequentes herdam o audit.
- **"FORA DE ESCOPO"** pra qualquer drift mid-task. Backlog vira nova sessão.
- **Sem `--no-verify`** em nenhum commit. Lefthook falhar = diagnose causa-raiz.
- **Confirme destrutivos**: `rm`, `git reset --hard`, `git push --force`, `git branch -d`, `git checkout .`. Pergunte antes.
- **`/session-end`** ao final.
- **Workflows multi-agent** só FASE 2 + FASE 3 do Kickoff.
- **NUNCA mexa em `pubspec.yaml`, `Blueprint.md`, `native_bridges/`** sem ADR aberto primeiro.
- **Locked invariants** (NÃO mudar): wake word = "Raro", free trial = 30 dias, planos = R$ 9,90 mensal / R$ 89,90 anual, Bundle ID = `com.rarocamera`.

---

## Em palavras simples

Esse arquivo é tua receita pra Sprint 1. Quando abrir uma sessão pra trabalhar nessa Sprint:

**Primeira vez** (Kickoff): cola o prompt "1.0 — Kickoff". O agente vai gastar 30-50min auditando 26 libs/APIs/patterns externos via WebSearch+Context7 ANTES de tocar em código. Você decide "executar" ou "corrigir o MD primeiro". Só depois roda Task A (cleanup memórias).

**Sessões seguintes**: cola "1 — Sessão de execução" trocando `[TASK]` pela letra da próxima Task (B, C, D, E, F, G, H). Audit muito mais leve (Sprint já foi auditado no Kickoff). Roda Task, commita, fecha.

**Última sessão** (Closure): cola "1 — Sessão de closure". Smoke test fim-a-fim no iPhone 12 nas 12 telas, marca Blueprint, fecha Sprint 1. Próximo passo: abrir SPRINT-2-PROMPTS.md.

Não precisa entender o conteúdo técnico do audit — você acompanha pelo terminal + pelo report final que o agente te entrega antes de executar.

