# Sprint 1 — Foundation + Walking Skeleton iOS (Detailed Execution Plan)

> **REQUIRED SUB-SKILL** para sessões de execução: `superpowers:subagent-driven-development` ou `superpowers:executing-plans`. Steps usam checkbox (`- [ ]`) para tracking.

**Goal**: Limpar acúmulo + fechar branch `feat/camera-native-bridge` + entregar app navegável end-to-end no iPhone 12 com todas 12 telas do prototype HTML, dados hard-coded via Riverpod 3 providers (swap-able em Sprint 2).

**Arquitetura**: Cleanup → Camera merge → Walking skeleton (Riverpod 3 providers reais, implementação mock). Tudo iOS-only, free Apple ID (rebuild via Xcode 7-day refresh).

**Tech Stack**: Flutter 3.44+, Dart 3.12, Riverpod 3 codegen, go_router 17, shared_preferences, permission_handler — todas já em `apps/mobile/pubspec.yaml`. **Exceção (audit 2026-05-29)**: `video_player` (usado na Task G) **não está** em `pubspec.yaml` nem na stack pinada do Blueprint §2 → é dep nova e exige ADR (micro-ADR ou adendo Blueprint §2) ANTES da Task G, conforme CLAUDE.md §3 ("Atualizar dep = abrir ADR"). Ver pré-requisito em Task G1.

---

## Contexto

Estado de entrada (Sprint 0 deliverable):
- Master plan v2 em `/Users/eduardorodrigues/.claude/plans/glimmering-dancing-pnueli.md` (referência)
- Branch `feat/camera-native-bridge` no commit `3b79021` (73 commits ahead de `develop`)
- Spec `camera-task-19-closure-design.md` status "In implementation — partial" (G4 ring code escrito mas não validado perceptualmente)
- 5 fixes da Sessão 0006 já em código mas não exercidos em device

Estado de saída (depois de Sprint 1):
- Memórias ≤ 25 (de 35), MEMORY.md ≤ 30 linhas
- CLAUDE.md atualizado (§8 com 9 hooks reais, §11 anti-patterns critério-cortada, §6 simplificado). Roadmap 3-sprint vive em **Blueprint §11** (Task B3), não em CLAUDE.md (correção audit 2026-05-29: não existe CLAUDE.md §15)
- Branch `feat/camera-native-bridge` MERGED em `develop` + deletada local + remote
- 12 telas Flutter navegáveis no iPhone 12 (dados mockados, Riverpod providers)
- App instalado no iPhone 12 via Xcode (cert 7-day refresh)

---

## Pre-flight checklist (rodar no início da sessão)

- [ ] **Estado git**: `git status` → working tree clean. `git branch --show-current` → `feat/camera-native-bridge` ou `develop` (qualquer um aceito; se for outro, parar)
- [ ] **iPhone 12 conectado**: `xcrun xctrace list devices 2>&1 | grep -i iphone` mostra o UDID
- [ ] **Free Apple ID ativo**: Xcode → Settings → Accounts → ver apple id listado com "Personal Team"
- [ ] **Bun + Flutter health**: `bun --version` (≥1.0) + `flutter doctor` (sem ERROR)
- [ ] **Backup memórias feito** (Task A1 abaixo cria; se já existe `memory-backup-*` skip)
- [ ] **Master plan lido**: usuário confirma que leu `/Users/eduardorodrigues/.claude/plans/glimmering-dancing-pnueli.md`
- [ ] **Audit pré-execução rodado**: usuário pediu agent pra auditar ESTE MD vs codebase atual — agent reportou 0 alucinações de file path / 0 comandos inválidos / 0 specs inexistentes

---

## Sprint Goals (observáveis binários)

- **G1 — Cleanup landed**: 2 commits temáticos em `develop` ou branch correta, lefthook GREEN, sem `--no-verify`.
- **G2 — Camera branch merged**: `feat/camera-native-bridge` aparece em `git log develop --oneline | head -20` como merge commit. Branch deletada local (`git branch -d`) e remote (`git push origin --delete`).
- **G3 — App roda no iPhone 12 com 12 telas navegáveis**: usuário consegue: splash → onboarding 1 → onboarding 2 → permissions → camera (UI shell, REC mock) → settings → gallery (mocks) → preview (mock) → paywall → checkout (mock subscribe) → trial countdown.
- **G4 — Riverpod 3 providers em uso**: cada feature tem `application/<name>_provider.dart` com `@riverpod` annotation, implementação retornando dados hard-coded mas signature pronta pra swap em Sprint 2.
- **G5 — Lefthook gates GREEN**: `flutter analyze` 0 issues, `flutter test` PASS, contract tests PASS, commitlint GREEN em todos commits.
- **G6 — Docs aligned com estado real**: CLAUDE.md §8 lista 9 hooks reais, §11 (anti-patterns) cortado por critério objetivo, §6 simplificado; **Blueprint §11** contém o roadmap 3-sprint com checkbox por tela/feature (Task B3). (Correção audit 2026-05-29: não existe CLAUDE.md §15 — o roadmap é do Blueprint, não do CLAUDE.md.)

---

## Sessões previstas (cadência emergente, não promessa)

| # | Objetivo | Entregável | Files tocados principais |
|---|---|---|---|
| **S1.A** | Backup + Memory cleanup + CLAUDE.md §8 align | Commit 1 cleanup | `~/.claude/projects/.../memory/*`, `CLAUDE.md` |
| **S1.B** | CLAUDE.md §6/§11 simplify + Blueprint §11 + INDEX | Commit 2 workflow refactor | `CLAUDE.md`, `docs/Blueprint.md`, `docs/sessions/0001-INDEX.md`, `docs/sessions/0007-*.md` |
| **S1.C** | Camera merge (perceptual validation + spec Done) | Merge commit em develop | spec status, `0001-INDEX.md`, branch merge |
| **S1.D** | Walking skeleton: Splash + Onboarding 1 + Onboarding 2 | 3 telas iOS navegáveis | `lib/features/splash/`, `lib/features/onboarding/`, `lib/app.dart` |
| **S1.E** | Walking skeleton: Permissions + Camera UI shell (P05 visual) | 2 telas + camera UI fiel ao prototype | `lib/features/permissions/`, `lib/features/camera/presentation/` |
| **S1.F** | Walking skeleton: Settings + Gallery | 2 telas com state persistido + grid mock | `lib/features/settings/`, `lib/features/gallery/` |
| **S1.G** | Walking skeleton: Preview + Sub popup + Paywall + Checkout | 4 telas + trial logic mockado | `lib/features/preview/`, `lib/features/paywall/`, `lib/features/checkout/` |

Cada S1.X é potencialmente 1 sessão. Cadência real emerge — se S1.D terminar em 30min, encadeia S1.E na mesma sessão; se travar, fecha sessão e retoma.

---

## Tasks atômicas

### Task A — Cleanup memórias (S1.A)

#### A1. Backup do diretório memory

**Files**: nenhum (cria novo diretório fora do repo)

**DONE criteria**: `ls /Users/eduardorodrigues/.claude/projects/-Users-eduardorodrigues-Documents-Projetos-Clientes-vitor-workana-app-raro/memory-backup-2026-05-29/MEMORY.md` retorna o arquivo (backup íntegro).

- [ ] **Step 1**: Rodar
  ```bash
  cp -r /Users/eduardorodrigues/.claude/projects/-Users-eduardorodrigues-Documents-Projetos-Clientes-vitor-workana-app-raro/memory \
        /Users/eduardorodrigues/.claude/projects/-Users-eduardorodrigues-Documents-Projetos-Clientes-vitor-workana-app-raro/memory-backup-2026-05-29
  ```
- [ ] **Step 2**: Verificar
  ```bash
  ls /Users/eduardorodrigues/.claude/projects/-Users-eduardorodrigues-Documents-Projetos-Clientes-vitor-workana-app-raro/memory-backup-2026-05-29/ | wc -l
  ```
  Esperado: 35 arquivos (igual ao original).

#### A2. Auditar cada memória vs CLAUDE.md §11

**Files**: somente leitura.

**DONE criteria**: tabela explícita em variável temporária identificando cada memória como KEEP, DELETE, ou MERGE-INTO-{name}.

- [ ] **Step 1**: Listar todas memórias com tamanho:
  ```bash
  ls -la /Users/eduardorodrigues/.claude/projects/-Users-eduardorodrigues-Documents-Projetos-Clientes-vitor-workana-app-raro/memory/*.md | awk '{print $5, $9}' | sort -n
  ```
- [ ] **Step 2**: Para cada memória, aplicar critério (CRITÉRIO objetivo do Furo 2 do master plan):
  - **DELETE se**: (a) conteúdo matches >70% de uma entrada de CLAUDE.md §11 OR (b) descreve bug SDK-específico de versão única com evidência de não-recorrência (e.g., iOS 26 FigCaptureSourceRemote err=-17281 noise — comprovado benigno).
  - **MERGE-INTO-X se**: cobre subset de outra memória mais ampla (e.g., `raro-pattern-android-camerax-ultra-wide-unreliable.md` cabe como seção em `raro-pattern-android-mediacodec-buffer-management.md`).
  - **KEEP se**: padrão load-bearing aplicável a >1 feature OU pattern de processo (feedback_*).
- [ ] **Step 3**: Documentar decisão no commit message do Task A4. Sem decisão isolada — registra junto com o delete.

**Memórias candidatas iniciais ao DELETE** (validar critério antes):
- Os 6 `raro_mem_raro-pattern-*` arquivos (sessão 0006 — todos JÁ em CLAUDE.md §11 atual ou redundantes com sessão 0006 log)
- `raro-pattern-ios-cvpixelbufferpool.md` (defer Sprint 2 — replay buffer, vira parte do Sprint 2 MD em vez de memória standalone)
- `raro-pattern-ios-avcapture-multicam-not-needed.md` (decisão já em ADR-0015, não precisa memória)

**Memórias candidatas a MERGE**:
- `raro-pattern-android-camerax-ultra-wide-unreliable.md` → seção dentro de `raro-pattern-android-mediacodec-buffer-management.md`

**Memórias candidatas a KEEP intactas** (load-bearing comprovado):
- Todas `feedback_*` (process learnings, aplicáveis a qualquer feature)
- `raro-pattern-flutter-ios-regen-xcconfig-spm-recovery.md` (recuperação recorrente)
- `raro-pattern-flutter-spm-ios-13-hardcoded.md` (raiz do problema SPM, referenciada em sessões 0003/0004/0005/0006)
- `raro-pattern-permission-handler-ios-podfile-macros.md` (gatcha sutil, fácil voltar a esquecer)
- `raro-pattern-xcode-preaction-modifies-workspace.md` (recovery flow documentado)
- `raro-pattern-revenuecat-trial-app-store-connect.md` (Sprint 2 backend real precisa)
- `raro-pattern-ios-volume-button-kvo-app-store-review.md` (Sprint 2 volume button precisa)
- `raro-pattern-ios-wake-word-no-native-api.md` (Sprint 2 wake word precisa)
- `raro-pattern-flutter-debug-vs-release-on-device.md` (Sprint 3 quando $99 pago)
- `raro-pattern-android-13-media-permissions.md` (Sprint 3 Android)
- `raro-pattern-xiaomi-miui-hyperos-detection.md` (Sprint 3 polish modal)

#### A3. Deletar memórias DELETE

**Files**: arquivos identificados em A2.

**DONE criteria**: `ls memory/*.md | wc -l` ≤ 25 (ou outro número justificado).

- [ ] **Step 1**: Para cada arquivo classificado DELETE em A2, rodar:
  ```bash
  rm /Users/eduardorodrigues/.claude/projects/-Users-eduardorodrigues-Documents-Projetos-Clientes-vitor-workana-app-raro/memory/<filename>.md
  ```
- [ ] **Step 2**: Atualizar `MEMORY.md` removendo entradas correspondentes (manter formato 1-linha por entrada com `- [Title](file.md) — hook`).
- [ ] **Step 3**: Verificar
  ```bash
  ls /Users/eduardorodrigues/.claude/projects/-Users-eduardorodrigues-Documents-Projetos-Clientes-vitor-workana-app-raro/memory/*.md | wc -l
  wc -l /Users/eduardorodrigues/.claude/projects/-Users-eduardorodrigues-Documents-Projetos-Clientes-vitor-workana-app-raro/memory/MEMORY.md
  ```

#### A4. Aplicar merges (se A2 identificou algum)

**Files**: arquivos target dos merges.

**DONE criteria**: arquivos source deletados, arquivos target têm nova seção integrada.

- [ ] **Step 1**: Para cada par {source, target} de A2:
  - Editar `target.md` adicionando seção "## Sub-pattern: <source short title>" com conteúdo essencial do source
  - `rm source.md`
- [ ] **Step 2**: Atualizar `MEMORY.md` index (remover source, anotar target expandido).

#### A5. CLAUDE.md §8 align (hooks reais)

**Files**: `/Users/eduardorodrigues/Documents/Projetos/Clientes/vitor-workana/app-raro/CLAUDE.md`

**DONE criteria**: §8 lista 9 hooks atuais (não 6).

- [ ] **Step 1**: Ler `CLAUDE.md §8` (linhas ~177-208 aprox).
- [ ] **Step 2**: Editar a tabela de hooks pra incluir os 4 faltantes:
  | `block-forbidden-terms.sh` | PreToolUse Write/Edit/MultiEdit | Bloqueia menção de OkCamera, Ok Camera, etc. |
  | `block-pigeon-error-rawvalue.sh` | PreToolUse Write/Edit/MultiEdit | Bloqueia String(<enum>.rawValue) em Pigeon (perde semântica) |
- [ ] **Step 3**: Validar contagem: §8 deve listar 9 hooks (block-env, block-secrets, block-forbidden-terms, block-pigeon-error-rawvalue, warn-adr-drift, format-dart, run-riverpod-codegen, reinject-roadmap, verify-task).

#### A6. Commit 1 — `chore(cleanup): trim memories + align claude.md hooks`

**Files**: stage as edições de Task A.

**DONE criteria**: 1 commit feito, lefthook GREEN, `git status` clean.

- [ ] **Step 1**: Stage seletivo:
  ```bash
  git add CLAUDE.md
  ```
  (memórias estão fora do repo, não vão pro git — backup local serve)
- [ ] **Step 2**: Commit com mensagem específica:
  ```bash
  git commit -m "$(cat <<'EOF'
  chore(cleanup): align claude.md §8 hooks com estado real

  - §8 atualizada de 6 → 9 hooks (block-forbidden-terms, block-pigeon-error-rawvalue,
    verify-task adicionados; tabela completa agora reflete .claude/hooks/)
  - Memórias deletadas/merged separadamente (não versionadas, backup local em
    memory-backup-2026-05-29/)
  - MEMORY.md index local atualizado pra ≤30 linhas, ≤25 entradas

  Sprint 1 / Task A.
  EOF
  )"
  ```
- [ ] **Step 3**: Verificar lefthook output GREEN no terminal output. Se RED, parar e diagnosticar — NÃO usar `--no-verify`.

---

### Task B — CLAUDE.md §6/§11 simplify + Blueprint §11 + Sprint MDs commits (S1.B)

#### B1. Simplificar CLAUDE.md §6 (Workflow de feature)

**Files**: `CLAUDE.md`

**DONE criteria**: §6 menciona 4 regras não-negociáveis do master plan + remove auto-sizing tabela (cabia explicar mas não está sendo seguida — vira ruído).

- [ ] **Step 1**: Ler §6 atual.
- [ ] **Step 2**: Substituir pela versão simplificada:
  ```markdown
  ## 6. Workflow de feature (1 sessão = 1 entregável fechado)

  ### Regras não-negociáveis (vigentes a partir de Sprint 1)

  1. **1 sessão = 1 entregável fechado declarado upfront.** "Entregável fechado" = (a) UI fiel ao prototype, (b) navegação in/out funciona, (c) estado persiste se aplicável, (d) testes não regridem. Mid-flight tangents proibidas — viram backlog de Sessão+1.
  2. **Toda sessão começa com `/prime`** + audit do Sprint MD vigente (usuário invoca).
  3. **Toda sessão termina com `/session-end`** que: appenda em `docs/sessions/`, define objetivo da próxima sessão em 1 linha, commit `chore(session): close N`.
  4. **Workflows multi-agent são opt-in via `/audit`**, nunca default. Se necessidade de audit adversarial surgir mid-feature, isso é SINAL pra parar e criar spec dedicada — não interromper a sessão atual.

  ### Sprint MDs ativos

  - `docs/superpowers/plans/sprint-1-foundation-walking-skeleton.md` (em execução)
  - `docs/superpowers/plans/sprint-2-backend-logic-ios.md` (backlog)
  - `docs/superpowers/plans/sprint-3-android-parity-testflight-client.md` (backlog)

  ### Spec/plan templates (uso de exceção, não rotina)

  Pra mudança fora dos Sprint MDs (ex: nova lib externa, mudança arquitetural não-roadmap):
  - `docs/superpowers/specs/0000-template.md` + `docs/superpowers/plans/0000-template.md`
  ```

#### B2. Aplicar critério objetivo em CLAUDE.md §11 (anti-patterns)

**Files**: `CLAUDE.md`

**DONE criteria**: Cada anti-pattern restante satisfaz pelo menos UM dos 3 critérios: (a) impacto não-recuperável, (b) aplicável a >1 feature, (c) não cabe em memória.

- [ ] **Step 1**: Ler §11 atual (29 anti-patterns).
- [ ] **Step 2**: Para cada bullet, classificar:
  - **KEEP** se atende >=1 critério acima.
  - **MOVE-TO-MEMORY** se é hyper-específico mas útil (e.g., padrões CATransaction → vira memória se ainda não tem).
  - **DROP** se já está coberto por outro bullet ou memória.
- [ ] **Step 3**: Reescrever §11 com apenas os KEEP, mantendo ordem original quando possível.
- [ ] **Step 4**: Anti-patterns provavelmente **KEEP** (todos atendem >=1 critério):
  - Wake word "Raro" (impacto não-recuperável — App Store rejection se errado)
  - Free trial / planos / Bundle ID (impacto não-recuperável — moeda real)
  - Riverpod 3 codegen (aplicável a TODAS features)
  - Imports relativos (aplicável a todo o lib/)
  - `setState` em widget Riverpod (aplicável a todo o lib/)
  - try-catch-(_) sem log (aplicável a tudo)
  - `print()` em produção (aplicável a tudo)
  - Strings literais UI fora de .arb (Sprint 3 i18n exige)
  - terminal-first iOS (aplicável a workflow inteiro)
  - `--no-verify` proibido (aplicável a workflow inteiro)
- [ ] **Step 5**: Anti-patterns provavelmente **MOVE-TO-MEMORY** (hyper-específicos, mas se já não está em memória, mover):
  - CATransaction.setDisableActions (já em memória atual)
  - CATransaction.flush (já em memória atual)
  - isSmoothAutoFocusEnabled ramp (já em memória atual)
  - KVO permanente vs per-tap (já em memória atual)
  - UiKitView gestureRecognizers (já em memória atual)
  - "fix sem logs reais" (já em memória `feedback_device_debug_use_real_logs_not_assumptions`)
  - Pigeon String(rawValue) (já em hook `block-pigeon-error-rawvalue.sh` + memória)
- [ ] **Step 6**: Validar resultado: contagem de bullets em §11 ≤ 12 (alvo 11). Anotar reduzido 29 → Y na commit message.

#### B3. Atualizar Blueprint §11 com roadmap 3-Sprint

**Files**: `docs/Blueprint.md`

**DONE criteria**: §11 contém tabela 3-sprint com checkbox por tela / feature, substituindo qualquer roadmap anterior.

- [ ] **Step 1**: Ler `docs/Blueprint.md §11` atual.
- [ ] **Step 2**: Substituir por:
  ```markdown
  ## 11. Roadmap (3 Sprints — vigente a partir de 2026-05-29)

  > Cada Sprint tem MD detalhado em `docs/superpowers/plans/sprint-N-*.md`.

  ### Sprint 1 — Foundation + Walking Skeleton iOS
  Status: ⏳ Em execução

  Cleanup:
  - [x] Sprint 0: master plan v2 + 3 sprint MDs criados
  - [ ] Memórias trimmed (≤25)
  - [ ] CLAUDE.md aligned (§8 9 hooks, §11 critério-cortada, §6 simplificado)
  - [ ] Branch `feat/camera-native-bridge` merged em `develop`

  Telas (12 Walking Skeleton):
  - [ ] P01 Splash
  - [ ] P02 Onboarding 1 ("Grave sem tocar")
  - [ ] P03 Onboarding 2 ("Nunca perca o momento")
  - [ ] P04 Permissions (camera + mic)
  - [ ] P05 Camera UI shell (REC mock, lens switch real, HUD)
  - [ ] P06 Subscription popup
  - [ ] P07 Settings (persistência via shared_preferences)
  - [ ] P08 Gallery (5 vídeos mock em assets/)
  - [ ] P09 Preview (video_player mock)
  - [ ] P10 Paywall (cards selecionáveis)
  - [ ] P11 Checkout (Apple Pay/Google Play mock)
  - [ ] Trial countdown (DateTime.now() + shared_preferences)

  ### Sprint 2 — Backend/Lógica Real iOS
  Status: 📋 Planejado em `sprint-2-backend-logic-ios.md`

  - [ ] Recording real (MP4 H.264/H.265 → vault)
  - [ ] Replay buffer 15/30s native (ring buffer iOS)
  - [ ] Wake word "Raro" iOS (SFSpeechRecognizer)
  - [ ] Volume button trigger iOS (KVO AVAudioSession)
  - [ ] RevenueCat paywall real (sandbox)
  - [ ] Vault + share via share_plus
  - [ ] Gallery persistência real

  ### Sprint 3 — Android Parity + TestFlight + Cliente
  Status: 📋 Planejado em `sprint-3-android-parity-testflight-client.md`

  - [ ] Android native bridges (CameraX, replay, voice, volume)
  - [ ] Apple Developer Program pago + TestFlight pipeline
  - [ ] Google Play Console + Internal Testing track
  - [ ] i18n PT/ES/EN (ARB + intl)
  - [ ] P12/P13/P14 modais
  - [ ] Performance gates (golden tests + integration_test E2E)
  - [ ] Cliente convidado em TestFlight + Internal Testing
  ```

#### B4. Criar session log 0007

**Files**: `docs/sessions/0007-sprint0-reset-roadmap-workflow.md` (criar) + `docs/sessions/0001-INDEX.md` (atualizar)

**DONE criteria**: arquivo novo existe com objetivo + commits desta sessão; INDEX atualizado com nova linha.

- [ ] **Step 1**: Criar `docs/sessions/0007-sprint0-reset-roadmap-workflow.md` com formato canônico:
  ```markdown
  # Sessão 0007 — Sprint 0 reset + master plan + 3 sprint MDs

  **Data**: 2026-05-29
  **Branch**: feat/camera-native-bridge (ou docs branch dedicada se criada)
  **Goal**: criar master plan v2 + 3 sprint MDs detalhados (Sprint 1/2/3)

  ## Decisões
  - Estratégia 3-Sprint substitui Fases v1
  - Cleanup com critério objetivo (Furos 2 e 4 do master plan)
  - Riverpod 3 providers em vez de MockData class (Furo 3)
  - Free Apple ID até Sprint 3 (TestFlight = $99 quando cliente)
  - Xcode terminal-first §13 validado por research 2026

  ## Entregáveis
  - Master plan v2: ~/.claude/plans/glimmering-dancing-pnueli.md
  - 3 sprint MDs em docs/superpowers/plans/

  ## Commits (Sprint-0 reais — `06ec0fb`..`1160c9f`, 4 commits)
  - 06ec0fb docs(docs): sprint 1/2/3 detailed execution plans
  - 0e17eb9 docs(docs): session prompts copy-paste para iniciar cada sprint
  - d319847 docs(docs): session prompts rigorous self-contained kickoffs per sprint
  - 1160c9f docs(docs): split session prompts em 3 arquivos por sprint

  ## Próxima sessão
  Executar Sprint 1.C — Camera merge (validação perceptual no iPhone 12).
  ```
- [ ] **Step 2**: Atualizar `docs/sessions/0001-INDEX.md` inserindo a linha **abaixo de 0008** (0007 é cronologicamente anterior — Sprint-0 antecede a Task A; a tabela é most-recent-on-top e 0008 é mais recente):
  ```
  | [0007](0007-sprint0-reset-roadmap-workflow.md) | 2026-05-29 | sprint 0: master plan v2 + 3 sprint MDs (reset estratégico) | `feat/camera-native-bridge` | `06ec0fb`…`1160c9f` (4 commits) |
  ```

#### B5. Commit 2 — `docs(harness): §6 simplify + §11 criterion cut + blueprint sprint roadmap`

> **Nota scope (audit 2026-05-29):** `workflow` **não** está no scope-enum de `commitlint.config.cjs`. Usar `docs(harness)` (precedente `4f9085e`). Type `docs` porque a mudança é doc/process-only (CLAUDE.md + Blueprint + session), não código.

**Files**: stage as edições de Tasks B1-B4.

**DONE criteria**: 1 commit feito, lefthook GREEN.

- [ ] **Step 1**: Stage:
  ```bash
  git add CLAUDE.md docs/Blueprint.md docs/sessions/0001-INDEX.md docs/sessions/0007-sprint0-reset-roadmap-workflow.md
  ```
- [ ] **Step 2**: Commit:
  ```bash
  git commit -m "$(cat <<'EOF'
  docs(harness): §6 simplify + §11 criterion cut + blueprint sprint roadmap

  CLAUDE.md:
  - §6 substituído por 4 regras não-negociáveis + sprint MD references
    (removido auto-sizing tabela — não estava sendo seguida)
  - §11 cortado de 29 → 11 anti-patterns aplicando critério: keep se (a)
    impacto não-recuperável, (b) aplicável >1 feature, (c) não cabe em
    memória. Patterns hyper-específicos movidos pra memória local.

  docs/Blueprint.md §11:
  - Roadmap reescrito como 3-Sprint com checkbox por tela/feature.
  - Sprint 1 (walking skeleton 12 telas iOS), Sprint 2 (backend real iOS),
    Sprint 3 (Android + TestFlight + cliente).

  Sessão 0007 logada + INDEX atualizado.

  Ref: master plan v2 em ~/.claude/plans/glimmering-dancing-pnueli.md
  EOF
  )"
  ```

---

### Task C — Camera merge (S1.C)

#### C1. Validação perceptual no iPhone 12

**Files**: nenhum (validação manual).

**DONE criteria**: usuário confirma "OK" após teste físico.

- [ ] **Step 1**: Conectar iPhone 12 via USB (ou wireless se já pareado).
- [ ] **Step 2**: Rodar
  ```bash
  cd /Users/eduardorodrigues/Documents/Projetos/Clientes/vitor-workana/app-raro
  bun --filter @raro/mobile run dev:ios -- -d $(xcrun xctrace list devices 2>&1 | grep -i "iPhone 12" | head -1 | sed -E 's/.*\(([0-9A-Fa-f-]+)\).*/\1/')
  ```
- [ ] **Step 3**: Quando app abrir na câmera, dar 10 taps em pontos diferentes do preview.
- [ ] **Step 4**: Verificar:
  - Ring aparece em <50ms percebido (deve ser sub-frame)
  - Focus settle perceptivamente OK em <300ms
  - Logs no terminal mostram `os_log` entries do `com.rarocamera/focus`
- [ ] **Step 5**: Usuário aprova: "OK" → seguir pra C2. Se NÃO OK: parar Sprint 1, abrir spec `camera-focus-latency-residual` (Quick sizing) em sessão dedicada.

#### C2. Marcar spec camera-task-19 como Done

**Files**: `docs/superpowers/specs/2026-05-28-camera-task-19-closure-design.md`

**DONE criteria**: bloco de status no topo do arquivo lê "**Status**: Done — Sprint 1.C validation".

- [ ] **Step 1**: Editar bloco "Status" no topo do arquivo (procurar `**Status**:` linha).
- [ ] **Step 2**: Atualizar pra:
  ```markdown
  **Status**: Done — Sprint 1.C perceptual validation 2026-XX-XX
  ```
- [ ] **Step 3**: Adicionar parágrafo no final do arquivo:
  ```markdown
  ## Closure (Sprint 1.C)

  Validação perceptual no iPhone 12 conduzida em 2026-XX-XX. Tap-to-focus
  ring visível em <50ms, focus settle <300ms. 5 fixes da Sessão 0006
  confirmados em campo. Spec movida pra Done.

  Próximo: Sprint 2 backend real (recording + replay buffer).
  ```

#### C3. Atualizar spec camera-native-bridge (a parent spec)

**Files**: `docs/superpowers/specs/2026-05-26-camera-native-bridge-design.md`

**DONE criteria**: status reflete "Done — bridge + Task 19 validated".

- [ ] **Step 1**: Editar bloco Status no topo. Atualizar para:
  ```markdown
  **Status**: Done — bridge + Task 19 validated em Sprint 1.C
  ```

#### C4. Merge `feat/camera-native-bridge` → `develop`

**Files**: branch operations.

**DONE criteria**: `git log develop --oneline | head -5` mostra merge commit; branch `feat/camera-native-bridge` deletada local + remote.

- [ ] **Step 1**: Garantir branch atual está limpa:
  ```bash
  git status   # working tree clean
  ```
- [ ] **Step 2**: Switch pra develop e atualizar:
  ```bash
  git checkout develop
  git pull origin develop
  ```
- [ ] **Step 3**: Merge (preferir merge commit explícito, não squash, pra preservar histórico de aprendizado):
  ```bash
  git merge --no-ff feat/camera-native-bridge -m "Merge feat/camera-native-bridge — Sprint 1.C closes Task 19"
  ```
- [ ] **Step 4**: Resolver conflitos se houver (não esperados — branch é forward-only desde split).
- [ ] **Step 5**: Push develop:
  ```bash
  git push origin develop
  ```
- [ ] **Step 6**: Deletar branch local + remote:
  ```bash
  git branch -d feat/camera-native-bridge
  git push origin --delete feat/camera-native-bridge
  ```
- [ ] **Step 7**: Verificar
  ```bash
  git log develop --oneline | head -10
  git branch -a | grep camera-native-bridge   # esperado: nada
  ```

#### C5. Update spec status commit

**Files**: 2 spec status updates de C2 + C3.

**DONE criteria**: commit em `develop` registra closure.

- [ ] **Step 1**: Stage + commit:
  ```bash
  git add docs/superpowers/specs/2026-05-28-camera-task-19-closure-design.md \
          docs/superpowers/specs/2026-05-26-camera-native-bridge-design.md
  git commit -m "docs(camera): close spec camera-native-bridge + task-19 (sprint 1.c)"
  git push origin develop
  ```

---

### Task D — Walking skeleton: Splash + Onboarding (S1.D)

#### D1. Feature folder structure

**Files**: criar diretórios.

**DONE criteria**: estrutura segue convenção `lib/features/<feature>/{application,data,domain,presentation}/`.

- [ ] **Step 1**: Criar estrutura:
  ```bash
  cd /Users/eduardorodrigues/Documents/Projetos/Clientes/vitor-workana/app-raro/apps/mobile
  mkdir -p lib/features/splash/{application,presentation}
  mkdir -p lib/features/onboarding/{application,domain,presentation}
  ```

#### D2. Splash screen (P01)

**Files**:
- Create: `apps/mobile/lib/features/splash/presentation/splash_screen.dart`
- Create: `apps/mobile/lib/features/splash/application/splash_controller.dart`
- Create: `apps/mobile/test/features/splash/splash_screen_test.dart`

**DONE criteria**: tela mostra logo + dot loader; auto-navega pra `/onboarding/1` após 1.5s; widget test passa.

- [ ] **Step 1**: Escrever widget test em `splash_screen_test.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:raro_mobile/features/splash/presentation/splash_screen.dart';

  void main() {
    testWidgets('SplashScreen mostra logo + dot loader', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: SplashScreen()),
        ),
      );
      expect(find.byKey(const Key('splash_logo')), findsOneWidget);
      expect(find.byKey(const Key('splash_loader')), findsOneWidget);
    });
  }
  ```
- [ ] **Step 2**: Rodar `bun --filter @raro/mobile run test test/features/splash/`. Esperado: FAIL (SplashScreen não existe ainda).
- [ ] **Step 3**: Implementar mínimo:
  ```dart
  // splash_screen.dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';

  class SplashScreen extends ConsumerStatefulWidget {
    const SplashScreen({super.key});

    @override
    ConsumerState<SplashScreen> createState() => _SplashScreenState();
  }

  class _SplashScreenState extends ConsumerState<SplashScreen> {
    @override
    void initState() {
      super.initState();
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        // navigation via go_router será adicionada quando router setup completo
      });
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo/raro_logo.png', key: const Key('splash_logo')),
              const SizedBox(height: 24),
              const CircularProgressIndicator(key: Key('splash_loader')),
            ],
          ),
        ),
      );
    }
  }
  ```
- [ ] **Step 4**: Rodar test. Esperado: PASS.
- [ ] **Step 5**: Commit:
  ```bash
  git add apps/mobile/lib/features/splash apps/mobile/test/features/splash
  git commit -m "feat(splash): p01 splash screen com logo e dot loader"
  ```

#### D3. Onboarding 1 (P02) "Grave sem tocar"

**Files**:
- Create: `apps/mobile/lib/features/onboarding/presentation/onboarding_page_1.dart`
- Create: `apps/mobile/lib/features/onboarding/domain/onboarding_step.dart` (entity)
- Create: `apps/mobile/lib/features/onboarding/application/onboarding_progress_provider.dart`
- Create: `apps/mobile/lib/features/onboarding/application/onboarding_progress_provider.g.dart` (codegen output, NÃO editar manualmente)
- Create: `apps/mobile/test/features/onboarding/onboarding_page_1_test.dart`

**DONE criteria**: tela fiel ao prototype (mic icon, copy "Grave sem tocar"); botão "Próximo" avança pra P03; estado persistido via Riverpod provider; widget test passa.

- [ ] **Step 1**: Definir entity (Sprint 1 simples; Sprint 2 expandirá):
  ```dart
  // onboarding_step.dart
  enum OnboardingStep { intro, replay, permissions, done }
  ```
- [ ] **Step 2**: Provider Riverpod 3 com persistência via shared_preferences (signature Sprint 2 reusará):
  ```dart
  // onboarding_progress_provider.dart
  import 'package:riverpod_annotation/riverpod_annotation.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import '../domain/onboarding_step.dart';

  part 'onboarding_progress_provider.g.dart';

  @riverpod
  class OnboardingProgress extends _$OnboardingProgress {
    static const _key = 'raro.onboarding.step';

    @override
    Future<OnboardingStep> build() async {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      return raw == null ? OnboardingStep.intro : OnboardingStep.values.byName(raw);
    }

    Future<void> advanceTo(OnboardingStep step) async {
      state = AsyncData(step);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, step.name);
    }
  }
  ```
- [ ] **Step 3**: Rodar codegen:
  ```bash
  bun --filter @raro/mobile run codegen
  ```
  Esperado: `onboarding_progress_provider.g.dart` criado sem erros.
- [ ] **Step 4**: Escrever widget test `onboarding_page_1_test.dart`:
  ```dart
  // testa: copy "Grave sem tocar" visível; botão "Próximo" chama advanceTo(replay)
  ```
- [ ] **Step 5**: Implementar `onboarding_page_1.dart` com layout fiel ao prototype (mic SVG + título + descrição + botão "Próximo").
- [ ] **Step 6**: Rodar tests. PASS.
- [ ] **Step 7**: Commit:
  ```bash
  git add apps/mobile/lib/features/onboarding apps/mobile/test/features/onboarding
  git commit -m "feat(onboarding): p02 onboarding 1 'grave sem tocar' + provider riverpod"
  ```

#### D4. Onboarding 2 (P03) "Nunca perca o momento"

**Files**:
- Create: `apps/mobile/lib/features/onboarding/presentation/onboarding_page_2.dart`
- Create: `apps/mobile/test/features/onboarding/onboarding_page_2_test.dart`

**DONE criteria**: tela fiel ao prototype (waveform viz + copy); botão "Próximo" navega pra `/permissions`; widget test passa.

- [ ] Mesmo padrão de D3 (test first, implement, run, commit).
- [ ] Commit: `feat(onboarding): p03 onboarding 2 'nunca perca o momento'`.

#### D5. go_router setup pra integrar splash + onboarding + camera

**Files**:
- Modify: `apps/mobile/lib/app.dart`
- Create: `apps/mobile/lib/app/router.dart` (se não existe)
- Modify: `apps/mobile/test/app_test.dart` se existe

**DONE criteria**: navegação splash → /onboarding/1 → /onboarding/2 → /permissions funciona end-to-end no Simulator; integration test passa.

- [ ] **Step 1**: Definir rotas:
  ```dart
  // router.dart
  import 'package:go_router/go_router.dart';
  import '../features/splash/presentation/splash_screen.dart';
  import '../features/onboarding/presentation/onboarding_page_1.dart';
  import '../features/onboarding/presentation/onboarding_page_2.dart';

  final appRouter = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding/1', builder: (_, __) => const OnboardingPage1()),
      GoRoute(path: '/onboarding/2', builder: (_, __) => const OnboardingPage2()),
      // permissions, camera, etc. — adicionados em D5-D7+
    ],
  );
  ```
- [ ] **Step 2**: Wire em `app.dart`:
  ```dart
  MaterialApp.router(routerConfig: appRouter)
  ```
- [ ] **Step 3**: Rodar `bun --filter @raro/mobile run dev:ios -- -d <simulator-udid>`. Navegar manualmente. Validar sequência.
- [ ] **Step 4**: Commit: `feat(app): wire go_router pra splash + onboarding routes`.

---

### Task E — Walking skeleton: Permissions + Camera UI shell (S1.E)

#### E1. Permissions screen (P04)

**Files**:
- Create: `apps/mobile/lib/features/permissions/presentation/permissions_screen.dart`
- Create: `apps/mobile/lib/features/permissions/application/permission_status_provider.dart`
- Create: `apps/mobile/test/features/permissions/permissions_screen_test.dart`

**DONE criteria**: tela fiel ao prototype (camera + mic icons, copy, botão "Permitir"); usa `permission_handler` (já em pubspec); avança pra `/camera` quando ambas grantadas; widget test mocka permission handler.

- [ ] **Step 1**: Provider Riverpod com status:
  ```dart
  enum CamMicStatus { pending, granted, denied }

  @riverpod
  Future<CamMicStatus> permissionStatus(PermissionStatusRef ref) async {
    final cam = await Permission.camera.status;
    final mic = await Permission.microphone.status;
    if (cam.isGranted && mic.isGranted) return CamMicStatus.granted;
    if (cam.isDenied || mic.isDenied) return CamMicStatus.denied;
    return CamMicStatus.pending;
  }
  ```
- [ ] **Step 2**: Widget test mockando `Permission` via `mocktail`.
- [ ] **Step 3**: Implementar UI fiel.
- [ ] **Step 4**: Wire route em `router.dart`.
- [ ] **Step 5**: Commit: `feat(permissions): p04 permissions screen com camera+mic via permission_handler`.

#### E2. Camera UI shell (P05) — UI fiel + lens switch REAL + REC button mockado

**Files**:
- Modify: `apps/mobile/lib/features/camera/presentation/camera_screen.dart` (criar se substitui o `camera_test_harness_screen.dart`)
- Create: `apps/mobile/lib/features/camera/presentation/widgets/rec_button.dart`
- Create: `apps/mobile/lib/features/camera/presentation/widgets/hud_overlay.dart`
- Create: `apps/mobile/lib/features/camera/presentation/widgets/buffer_pill.dart`
- Create: `apps/mobile/lib/features/camera/presentation/widgets/lens_switcher.dart`
- Create: `apps/mobile/lib/features/camera/application/recording_state_provider.dart`
- Create: `apps/mobile/test/features/camera/camera_screen_test.dart`

**DONE criteria**: tela visualmente igual ao prototype (HUD com resolution/fps/lens, REC button no centro inferior, buffer pill superior, lens switcher 0.5x/1x); REC button toggla state visualmente + timer fake; lens switch chama bridge real (já funciona); test smoke passa.

- [ ] **Step 1**: Recording state provider mockado:
  ```dart
  @riverpod
  class RecordingState extends _$RecordingState {
    @override
    Recording build() => const Recording.idle();
    
    void toggle() {
      state = state is RecordingIdle ? Recording.active(startedAt: DateTime.now()) : const Recording.idle();
    }
  }
  ```
- [ ] **Step 2**: Widgets HUD + REC button + buffer pill + lens switcher fiéis ao prototype.
- [ ] **Step 3**: Stack composition: `CameraPlatformView` (bridge native existente) + Flutter overlay (HUD, REC, pill, switcher).
- [ ] **Step 4**: Widget test smoke: tela renderiza, tap em REC alterna state, tap em lens chama bridge.
- [ ] **Step 5**: Commit: `feat(camera): p05 ui shell completa (hud, rec mock, buffer pill, lens switch real)`.

---

### Task F — Walking skeleton: Settings + Gallery (S1.F)

#### F1. Settings screen (P07)

**Files**:
- Create: `apps/mobile/lib/features/settings/presentation/settings_screen.dart`
- Create: `apps/mobile/lib/features/settings/application/settings_provider.dart` (todos os toggles + slidersem shared_preferences)
- Create: `apps/mobile/lib/features/settings/domain/recording_settings.dart` (entity freezed)
- Create: `apps/mobile/test/features/settings/settings_provider_test.dart`

**DONE criteria**: todos sliders/toggles persistem em shared_preferences; rebuild → estado preservado; widget test cobre persist/load.

- [ ] **Step 1**: Entity freezed:
  ```dart
  @freezed
  class RecordingSettings with _$RecordingSettings {
    const factory RecordingSettings({
      @Default(Resolution.fhd) Resolution resolution, // 720p, 1080p, 4K, 4K60
      @Default(Fps.thirty) Fps fps, // 30 / 60
      @Default(true) bool stabilization,
      @Default(ReplayDuration.thirtySec) ReplayDuration replayDuration, // 15s / 30s
      @Default(ControlMode.volume) ControlMode controlMode, // voice / volume
      @Default(AppLocale.ptBR) AppLocale locale, // PT / ES / EN
    }) = _RecordingSettings;
  }
  ```
- [ ] **Step 2**: Provider com persistência (signature reusada em Sprint 2 pra ler/escrever real).
- [ ] **Step 3**: Test: provider lê default, set values, persist, recria provider, valida read.
- [ ] **Step 4**: UI fiel ao prototype: cada setting linha com label + control.
- [ ] **Step 5**: Wire route.
- [ ] **Step 6**: Commit: `feat(settings): p07 settings screen + provider riverpod com shared_preferences`.

#### F2. Gallery screen (P08) com vídeos mock

**Files**:
- Create: `apps/mobile/lib/features/gallery/presentation/gallery_screen.dart`
- Create: `apps/mobile/lib/features/gallery/presentation/widgets/video_thumbnail.dart`
- Create: `apps/mobile/lib/features/gallery/application/video_list_provider.dart` (signature Sprint 2 reusa)
- Create: `apps/mobile/lib/features/gallery/domain/video_entity.dart` (freezed)
- Create: `apps/mobile/assets/sample_videos/` (5 placeholders + 5 thumbnail PNGs)
- Modify: `apps/mobile/pubspec.yaml` (assets section)
- Create: `apps/mobile/test/features/gallery/gallery_screen_test.dart`

**DONE criteria**: 5-6 thumbnails em grid; tap navega pra `/preview/<id>`; filter pills (All / Today / This week / Raro Replay) filtram client-side mockados; widget test passa.

- [ ] **Step 1**: Entity:
  ```dart
  @freezed
  class VideoEntity with _$VideoEntity {
    const factory VideoEntity({
      required String id,
      required String name,
      required Duration length,
      required DateTime recordedAt,
      required bool isReplay,
      required String thumbnailAssetPath,
    }) = _VideoEntity;
  }
  ```
- [ ] **Step 2**: Provider Sprint 1 retorna lista hard-coded de 5-6 entidades; Sprint 2 substitui implementação pra ler de `path_provider`:
  ```dart
  @riverpod
  Future<List<VideoEntity>> videoList(VideoListRef ref) async {
    // Sprint 1: hard-coded
    return const [
      VideoEntity(id: '1', name: 'Pôr do sol', length: Duration(minutes: 2, seconds: 30), ...),
      // ...
    ];
    // Sprint 2 substituirá por: ref.read(vaultServiceProvider).list();
  }
  ```
- [ ] **Step 3**: Adicionar thumbnails PNGs em `assets/sample_videos/`. Atualizar `pubspec.yaml`.
- [ ] **Step 4**: UI grid + filter pills.
- [ ] **Step 5**: Wire route.
- [ ] **Step 6**: Commit: `feat(gallery): p08 grid mock com 5 videos + filter pills + video_list_provider`.

---

### Task G — Walking skeleton: Preview + Sub popup + Paywall + Checkout (S1.G)

#### G1. Preview screen (P09) com video_player

**Files**:
- Create: `apps/mobile/lib/features/preview/presentation/preview_screen.dart`
- Create: `apps/mobile/test/features/preview/preview_screen_test.dart`

**DONE criteria**: tela carrega video player com asset mock; scrubber funciona; metadata (size, length, codec) mockada visível; share/trash/info buttons presentes mas com toast "Coming Sprint 2".

- [ ] **PRÉ-REQUISITO BLOQUEANTE (audit 2026-05-29)**: `video_player` NÃO está em `apps/mobile/pubspec.yaml` NEM na stack pinada do Blueprint §2. Adicionar dep nova exige ADR (CLAUDE.md §3 "Atualizar dep = abrir ADR. Sem exceção."). Antes de implementar: (1) abrir micro-ADR `docs/decisions/0017-video-player-preview.md` OU adendo no Blueprint §2 registrando a escolha + versão pinada via Context7/pub.dev; (2) `cd apps/mobile && flutter pub add video_player` + `bun --filter @raro/mobile run pub:get`; (3) só então implementar a tela.
- [ ] Implementar usando `video_player` (após pré-requisito acima resolvido).
- [ ] Wire route `/preview/:id` puxando do videoListProvider.
- [ ] Commit: `feat(preview): p09 video player mock + scrubber + metadata mock`.

#### G2. Subscription popup (P06)

**Files**:
- Create: `apps/mobile/lib/features/paywall/presentation/widgets/subscription_popup.dart`
- Create: `apps/mobile/lib/features/paywall/application/subscription_status_provider.dart`
- Create: `apps/mobile/test/features/paywall/subscription_status_provider_test.dart`

**DONE criteria**: popup aparece em tela camera quando `isSubscribed=false`; CTA navega pra `/paywall`; estado persiste em shared_preferences.

- [ ] **Step 1**: Provider mock (Sprint 2 substituirá por RevenueCat):
  ```dart
  @riverpod
  class SubscriptionStatus extends _$SubscriptionStatus {
    static const _key = 'raro.subscribed';
    static const _trialKey = 'raro.trial.startedAt';

    @override
    Future<SubscriptionState> build() async {
      final prefs = await SharedPreferences.getInstance();
      final subscribed = prefs.getBool(_key) ?? false;
      final trialStart = prefs.getInt(_trialKey);
      // calcular trial restante a partir de DateTime.now() vs trialStart + 30 dias
      // ...
    }

    Future<void> markSubscribed() async { /* persist + state */ }
  }
  ```
- [ ] **Step 2**: Popup overlay no camera screen condicionalmente renderizado.
- [ ] **Step 3**: Commit: `feat(paywall): p06 subscription popup + provider mock com shared_preferences`.

#### G3. Paywall (P10) + Checkout (P11)

**Files**:
- Create: `apps/mobile/lib/features/paywall/presentation/paywall_screen.dart`
- Create: `apps/mobile/lib/features/paywall/presentation/widgets/plan_card.dart`
- Create: `apps/mobile/lib/features/checkout/presentation/checkout_screen.dart`
- Create: `apps/mobile/lib/features/checkout/application/checkout_provider.dart`
- Create: `apps/mobile/test/features/paywall/paywall_screen_test.dart`
- Create: `apps/mobile/test/features/checkout/checkout_provider_test.dart`

**DONE criteria**: Paywall mostra 2 cards (Mensal R$ 9.90 e Anual R$ 89.90 com "MELHOR OFERTA"), cards selecionáveis; Checkout mostra Apple Pay + Google Play picker; botão "Confirmar" marca subscribed=true via subscriptionStatusProvider e navega de volta pra `/camera`.

- [ ] **Step 1**: Plan card widget fiel ao prototype.
- [ ] **Step 2**: Hard-coded SKUs respeitando ADR-0010 (locked invariants):
  ```dart
  const monthlyPriceBRL = 9.90;
  const yearlyPriceBRL = 89.90;
  const yearlyMonthlyEquivalent = 89.90 / 12; // R$ 7.49/mês
  const freeTrialDays = 30;
  ```
- [ ] **Step 3**: Checkout mock: tap "Confirmar" → set trial start + subscribed=true.
- [ ] **Step 4**: Wire routes `/paywall` + `/checkout`.
- [ ] **Step 5**: Commit: `feat(paywall): p10/p11 cards + checkout mock + trial countdown via shared_preferences`.

---

### Task H — Validação Sprint 1 fim-a-fim

#### H1. Smoke test end-to-end manual

**Files**: nenhum (validação manual).

**DONE criteria**: usuário consegue executar fluxo completo no iPhone 12 sem crash.

- [ ] **Step 1**: Rodar app:
  ```bash
  bun --filter @raro/mobile run dev:ios -- -d <iphone-12-udid>
  ```
- [ ] **Step 2**: Fluxo de validação (cobrir todas 12 telas):
  - Splash (1.5s) → Onboarding 1 → Próximo → Onboarding 2 → Próximo → Permissions → Permitir → Camera (UI shell)
  - Em Camera: tap REC → timer roda → tap REC novamente → para
  - Tap settings shortcut → Settings → mudar quality + replay duration → voltar
  - Tap gallery shortcut → Gallery → tap thumbnail → Preview → voltar
  - Em Camera (modo não-subscribed): popup aparece → tap CTA → Paywall → selecionar plano → Checkout → Confirmar → voltar pra Camera
  - Validar contador de trial visível em algum lugar (Settings → About OU em Paywall mostrando "30 dias restantes")
- [ ] **Step 3**: Sem regressões em features camera nativa (focus, lens switch, format).

#### H2. Atualizar Blueprint §11 checkboxes

**Files**: `docs/Blueprint.md`

**DONE criteria**: todos checkboxes de Sprint 1 marcados ✅.

- [ ] Commit: `docs(blueprint): mark sprint 1 telas + cleanup checkboxes done`.

#### H3. Session log + INDEX update

**Files**: novo arquivo de sessão + INDEX.

- [ ] Criar `docs/sessions/<NNNN>-sprint1-closure.md` (número emerge — pode ser 0008+ dependendo de quantas sessões Sprint 1 levou).
- [ ] Atualizar INDEX.

---

## Riscos conhecidos (mitigação durante execução)

| Risco | Mitigação |
|---|---|
| Memória deletada errada por critério mal-aplicado | Backup em `memory-backup-2026-05-29/` antes de qualquer rm. Reverter via `cp -r`. |
| CLAUDE.md §11 corte agressivo demais perde guardrail | Critério objetivo aplicado linha-a-linha. Se dúvida, KEEP. Pode reverter no Sprint 2 se sentir falta. |
| Camera merge introduz conflito em develop | `develop` está em estado estável (`d91ccaa`). Merge não-FF preserva histórico de aprendizado. Se conflito surgir, abrir como spec dedicada e adiar Sprint 1.D. |
| Walking skeleton viola prototype design | Cada feature tem widget test cobrindo presença de elementos-chave. Visual fidelity é responsabilidade do `design-fidelity-checker` agent rodado por feature. |
| `permission_handler` mock em widget test não cobre runtime real | Smoke test manual em iPhone 12 (Task H1) é o gate real. Widget test cobre lógica de transição. |
| Riverpod codegen falha em build | Run `bun --filter @raro/mobile run codegen` após cada mudança em provider. Verificar `.g.dart` gerado. |
| `flutter analyze` falha por strict lints | Manter sempre `require_trailing_commas` + `prefer_const_constructors`. Rodar analyze após cada commit. |
| Branch deletada antes do merge confirmar OK | Step C4 só deleta APÓS step verifica `git log develop --oneline` mostra merge commit + push origin OK. |
| `SharedPreferences.getInstance()` é API legada em 2026 (nota audit 2026-05-29) | Aceitável no Sprint 1 (walking skeleton, mocks). Os exemplos D3/F/G2 usam o padrão legado de propósito. Sprint 2 migra pra `SharedPreferencesWithCache`/`SharedPreferencesAsync` ao trocar implementação mock por real. Não bloqueia Sprint 1. |

---

## Out of scope (vira backlog de Sprint 2 ou 3)

- ✗ Recording real (Sprint 2)
- ✗ Replay buffer real (Sprint 2)
- ✗ Wake word "Raro" real (Sprint 2)
- ✗ Volume button trigger real (Sprint 2)
- ✗ RevenueCat real (Sprint 2 — sandbox sandboxed)
- ✗ Vault encryption + share real (Sprint 2)
- ✗ Gallery filesystem real (Sprint 2)
- ✗ Android implementation (Sprint 3)
- ✗ TestFlight build (Sprint 3)
- ✗ Google Play setup (Sprint 3)
- ✗ i18n PT/ES/EN (Sprint 3)
- ✗ P12 Xiaomi modal (Sprint 3)
- ✗ P13 Bluetooth modal (Sprint 3)
- ✗ P14 Lock mode (Sprint 3)
- ✗ Performance/golden tests (Sprint 3)

Se durante execução surgir necessidade clara desses itens, **PARAR** e criar spec dedicada — não puxar pra Sprint 1.

---

## Audit checklist (rodar no início da próxima sessão antes de executar)

Cole esse prompt pra agente fresh no início da sessão de execução:

> Audite o arquivo `docs/superpowers/plans/sprint-1-foundation-walking-skeleton.md` contra o estado atual do codebase. Para cada Task (A-H), valide:
>
> 1. Os file paths citados existem ou são paths válidos pra criação?
> 2. Os comandos shell estão sintaticamente corretos pra macOS zsh + bun + flutter?
> 3. As dependências referenciadas (riverpod_annotation, freezed, permission_handler, video_player, shared_preferences) estão em `apps/mobile/pubspec.yaml`?
> 4. As specs/ADRs referenciadas (camera-task-19-closure-design, camera-native-bridge-design, ADR-0010, ADR-0015) existem?
> 5. Os goals G1-G6 são observáveis binários (não subjetivos)?
> 6. Tem alguma task com placeholder (TBD, TODO, "implement later", "similar to Task X" sem detalhe)?
> 7. Tem task que assume arquivos ou funções inexistentes?
>
> Reporte em ≤300 palavras: holes + sugestões de correção. Se 0 holes, dizer explicitamente "Audit clean, pode executar".

Se audit reporta ≥1 hole, **corrigir antes de executar Task A1**.

---

## Em palavras simples

**O que Sprint 1 entrega**: app instalado no seu iPhone 12 onde você consegue passar por todas as 12 telas do design (splash, 2 onboarding, permissões, câmera com botões funcionando visualmente, settings, galeria com vídeos exemplo, preview, paywall, checkout, popup de assinatura) — TUDO navegável e com aparência igual ao protótipo HTML. As funções "de verdade" (gravar vídeo de verdade, replay buffer, voz "Raro", paywall real) ficam pra Sprint 2.

**Como você acompanha**: cada Task A-H tem um commit dedicado. Você vê o progresso no `git log` e no Blueprint §11 (checkbox por tela).

**Quanto tempo**: depende. Pode ser 5-7 sessões pequenas (cada uma ~1h), pode ser menos se algumas telas saírem rápido. Não me cobre prazo — me cobre Task completo.

**Risco prático**: cleanup (Task A-B) tem risco zero, é tudo versionado. Walking skeleton (Task D-G) tem risco médio: posso te entregar uma tela que parece certa mas a navegação out-of-screen quebra. Por isso H1 (smoke test manual) é o gate final.

**O que NÃO acontece nesta Sprint**: gravação real, voz "Raro", Android, $99 da Apple, TestFlight. Tudo isso vira backlog de Sprint 2 e 3.

