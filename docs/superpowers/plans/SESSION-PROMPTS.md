# Session Prompts — Copy-paste para iniciar cada sessão

> **Uso**: cole o prompt apropriado no início de uma nova sessão Claude Code. Substitua placeholders entre colchetes `[ASSIM]`. Os prompts são curtos de propósito — toda a substância está nos MDs de Sprint.

---

## Como usar este arquivo

1. **Primeira sessão de um Sprint** → use o prompt "**X.0 — Kickoff**" (faz audit completo do MD antes de qualquer execução).
2. **Sessão seguinte dentro do mesmo Sprint** → use o prompt "**X — Sessão de execução**" substituindo `[TASK]` pela letra (A, B, C…) da próxima task.
3. **Sessão que algo quebrou** → use "**Recovery**" no final.
4. **Quando o Sprint terminar** → use "**X — Sessão de closure**".

Princípio: o prompt curto delega ao MD. O agente lê o MD, audita, executa, commita, fecha sessão. Você só corta drift e aprova steps destrutivos.

---

## Sprint 1 — Foundation + Walking Skeleton iOS

### 1.0 — Kickoff (primeira sessão Sprint 1)

```
Sessão de execução Sprint 1 — KICKOFF.

Setup:
1. Rode /prime
2. Leia docs/superpowers/plans/sprint-1-foundation-walking-skeleton.md INTEIRO
3. Audite o MD com agente Explore: validar que file paths citados existem ou são paths válidos pra criação, comandos shell são sintáticos pra macOS zsh + bun + flutter, deps referenciadas estão em apps/mobile/pubspec.yaml, specs/ADRs referenciados existem, goals G1-G6 são observáveis binários, não há placeholders TBD/TODO. Reporte em ≤300 palavras: holes ou "Audit clean".
4. Se holes: corrija o MD primeiro (commit `docs(docs): sprint 1 md audit fixes`). Se clean: prossiga.

Execução:
5. Execute Task A inteira (A1 backup → A2 auditar memórias → A3 deletar → A4 merges → A5 CLAUDE.md §8 → A6 commit 1). Para cada step destrutivo (rm, git push, git branch -d), peça minha confirmação ANTES.
6. Lefthook GREEN obrigatório. Se falhar: pare, diagnose, NÃO use --no-verify.

Closure:
7. Rode /session-end → registra entrada em docs/sessions/0008-sprint1-task-a-cleanup.md, define objetivo próxima sessão como "Sprint 1 Task B", commit chore(session): close 0008.

Guardrails vigentes:
- "FORA DE ESCOPO" pra qualquer drift mid-task
- 1 sessão = Task A fechado, NÃO avance pra Task B sem confirmação
- Sem --no-verify, sem branch destrutiva sem confirmação
```

### 1 — Sessão de execução (substitua `[TASK]`)

```
Sessão de execução Sprint 1, Task [TASK].

Setup:
1. /prime
2. Leia docs/superpowers/plans/sprint-1-foundation-walking-skeleton.md focando na seção "Task [TASK]" + "Audit checklist" no final do MD
3. Mini-audit: validar que Tasks anteriores (A até [TASK-1]) estão done em git log + Blueprint §11 checkboxes. Se Task anterior incompleta, parar e me avisar.

Execução:
4. Execute Task [TASK] step-by-step conforme MD. Para cada step destrutivo, confirme comigo antes.
5. analyze + test GREEN antes de commit. Sem --no-verify.

Closure:
6. /session-end → entrada em docs/sessions/, próximo objetivo "Sprint 1 Task [PRÓXIMA]".
7. Reporte: tasks done, commits, blueprint § atualizado.

Guardrails:
- "FORA DE ESCOPO" se surgir subject novo
- 1 sessão = Task [TASK] fechado
```

**Letras de Task válidas pra Sprint 1**: A (cleanup), B (workflow refactor), C (camera merge — exige validação perceptual no iPhone 12), D (splash + onboarding), E (permissions + camera UI shell), F (settings + gallery), G (preview + paywall + checkout), H (smoke test fim-a-fim + closure).

### 1 — Sessão de closure (Task H)

```
Sessão de closure Sprint 1.

Setup:
1. /prime
2. Verifique Blueprint §11 — todos checkboxes Sprint 1 ✅ exceto Task H?
3. Se algum aberto: nomeie, eu decido se vamos fechar nesta sessão ou se vira tech debt registrada.

Execução (Task H):
4. Smoke test fim-a-fim manual no iPhone 12: splash → onboarding 1 → onboarding 2 → permissions → camera UI shell → tap REC (timer roda) → settings (mudar quality) → gallery (mocks) → tap thumbnail → preview → camera com popup subscription → paywall → checkout → confirm subscribe → trial countdown visível. Sem crash. Sem regressão em camera nativa.
5. Marcar Blueprint §11 Sprint 1 checkboxes ✅.
6. Session log de closure: docs/sessions/<N>-sprint1-closure.md.
7. Commit final: docs(blueprint): mark sprint 1 telas + cleanup done.

Próxima sessão: kickoff Sprint 2 (apenas se Sprint 1 todos checkboxes verdes E você confirmar disponibilidade pra backend logic real).
```

---

## Sprint 2 — Backend/Lógica Real iOS

### 2.0 — Kickoff (primeira sessão Sprint 2)

```
Sessão de execução Sprint 2 — KICKOFF.

Pre-flight:
1. Rode /prime
2. Confirme Sprint 1 closed: git log develop --oneline | head -10 mostra merge feat/camera-native-bridge + telas walking skeleton; Blueprint §11 Sprint 1 todos ✅.
3. Pergunte-me: Apple Sandbox Tester account criada? (necessária pra Task E paywall). Se não, eu preciso criar antes de Task E rodar (mas Tasks A-D rodam sem ela).
4. Leia docs/superpowers/plans/sprint-2-backend-logic-ios.md INTEIRO.
5. Audite o MD com agente Explore: Pigeon API methods sintáticos? Swift APIs existem em iOS 15+? memórias raro-pattern-ios-wake-word-no-native-api / raro-pattern-revenuecat-trial-app-store-connect / raro-pattern-revenuecat-error-handling / raro-pattern-ios-volume-button-kvo-app-store-review / raro-pattern-ios-cvpixelbufferpool existem em memory/? ADRs 0003, 0010, 0011 existem? RevenueCat workaround Task E2 sem $99 ainda é factível em 2026? (validar via WebSearch). Reporte ≤400 palavras: holes ou "Audit clean".
6. Se holes: corrija o MD primeiro. Se clean: prossiga.

Execução:
7. Execute Task A inteira (A1 Pigeon recording API → A2 RecordingPipeline.swift + XCTest → A3 vault_service Dart → A4 wire integration). Confirme antes de cada step destrutivo.
8. analyze + test + contract tests + XCTest GREEN. Sem --no-verify.

Closure:
9. /session-end. Próximo objetivo: "Sprint 2 Task B (replay buffer)".

Guardrails:
- "FORA DE ESCOPO" pra drift
- 1 sessão = Task A fechado
```

### 2 — Sessão de execução

```
Sessão de execução Sprint 2, Task [TASK].

Setup:
1. /prime
2. Leia docs/superpowers/plans/sprint-2-backend-logic-ios.md seção "Task [TASK]" + "Audit checklist" final.
3. Mini-audit: Tasks anteriores done? (git log + Blueprint §11). Se Task E (paywall) — Apple Sandbox Tester criada? Se Task C (wake word) — iPhone 12 com mic permission grantada?
4. Memórias relevantes pra Task [TASK] foram relidas? (cada Task no MD nomeia quais).

Execução:
5. Execute step-by-step. Confirme destrutivos.
6. XCTest + integration test smoke no iPhone 12 antes de commit final. GREEN obrigatório.

Closure:
7. /session-end. Próximo: "Sprint 2 Task [PRÓXIMA]".
8. Reporte: tasks done, commits, smoke test result no device.

Guardrails idem Sprint 1.
```

**Letras válidas Sprint 2**: A (recording + vault), B (replay buffer), C (wake word "Raro"), D (volume button), E (RevenueCat sandbox — exige Apple Sandbox Tester), F (share + polish).

### 2 — Sessão de closure

```
Sessão de closure Sprint 2.

1. /prime
2. Smoke test fim-a-fim no iPhone 12:
   - Tap REC → grava 10s → tap REC → MP4 aparece em Gallery → tap thumbnail → reproduz
   - Replay buffer ligado → após 30s, tap "Salvar replay" → MP4 30s no Gallery
   - Dizer "Raro" → REC inicia
   - Pressionar volume up → REC inicia
   - Paywall → Subscribe sandbox → trial countdown rodando
   - Share via preview → system sheet abre
3. Marcar Blueprint §11 Sprint 2 ✅.
4. Session log closure.
5. Commit final: docs(blueprint): mark sprint 2 backend logic done.

Próxima sessão: kickoff Sprint 3 (apenas com confirmação de pagar Apple Dev $99 + Google Play $25).
```

---

## Sprint 3 — Android Parity + TestFlight + Cliente

### 3.0 — Kickoff (primeira sessão Sprint 3)

```
Sessão de execução Sprint 3 — KICKOFF.

Pre-flight CRÍTICO:
1. /prime
2. Confirme Sprint 2 closed: Blueprint §11 Sprint 2 todos ✅. Smoke test iPhone 12 passou.
3. Pergunte-me:
   - Apple Developer Program $99 pago? Se não: parar, Task A1 do Sprint 3 é signup → confirme intenção de pagar AGORA.
   - Google Play Console $25 pago? Se não: parar, Task F1 do Sprint 3 é signup.
   - Device Android disponível (preferência Xiaomi MIUI/HyperOS)? Conectado via USB?
4. Leia docs/superpowers/plans/sprint-3-android-parity-testflight-client.md INTEIRO.
5. Audit do MD com agente Explore: memórias Android (raro-pattern-android-camerax-ultra-wide-unreliable / raro-pattern-android-mediacodec-buffer-management / raro-pattern-android-13-media-permissions / raro-pattern-xiaomi-miui-hyperos-detection) existem? ADRs 0015, 0016 existem? CameraX 1.6.1 ainda é versão atual em 2026 (validar via WebSearch + Context7)? RevenueCat Android API atual? TestFlight requirements (privacy policy URL, screenshots 1024x1024 app icon) preparados? Pigeon CameraDebugHostApi (ADR-0016) spec'd? Reporte ≤500 palavras: holes ou "Audit clean".
6. Se holes: corrija o MD. Se clean: prossiga.

Execução:
7. Execute Task A (Apple Dev signup + bundle ID + provisioning + in-app products no App Store Connect). Steps Task A são parte CLI parte UI externa (App Store Connect, RevenueCat dashboard) — peça minha confirmação a cada step.

Closure:
8. /session-end. Próximo: "Sprint 3 Task B (Android camera bridge)".

Guardrails:
- "FORA DE ESCOPO" pra drift
- 1 sessão = Task A fechado
- Sem auto-rewrite de project.pbxproj (§13 terminal-first; se Xcode UI precisar abrir pra signing, fazer commit antes/depois e validar diff)
```

### 3 — Sessão de execução

```
Sessão de execução Sprint 3, Task [TASK].

Setup:
1. /prime
2. Leia docs/superpowers/plans/sprint-3-android-parity-testflight-client.md seção "Task [TASK]" + "Audit checklist" final.
3. Mini-audit: Tasks anteriores done? Para Task B+ (Android code): device Android conectado? Para Task J (TestFlight): build iOS release roda local sem signing errors? Para Task K (Play Store): build AAB roda local?
4. Memórias relevantes relidas?

Execução:
5. Execute step-by-step. Confirme destrutivos. Para upload TestFlight/Play Store: validar versão incrementada em pubspec.yaml.
6. Lefthook GREEN. androidTest GREEN se Tasks B-E. Smoke test em device Android.

Closure:
7. /session-end. Próximo: "Sprint 3 Task [PRÓXIMA]".
8. Reporte: tasks done, commits, smoke iOS + Android.
```

**Letras válidas Sprint 3**: A (Apple Dev signup), B (Android camera), C (Android recording + vault), D (Android replay buffer), E (Android wake word + volume), F (Android paywall + Google Play setup), G (i18n PT/ES/EN), H (modais P12/P13/P14 + Crashlytics + Analytics), I (golden tests + integration_test E2E), J (TestFlight build + cliente), K (Google Play Internal Testing + cliente), L (smoke test final cliente + retro).

### 3 — Sessão de closure (Task L)

```
Sessão de closure Sprint 3 — ENTREGA CLIENTE.

1. /prime
2. Verifique:
   - Cliente recebeu email TestFlight + instalou em iPhone real? Smoke test fim-a-fim cliente passou?
   - Cliente recebeu link Internal Testing + instalou em Android real? Smoke test fim-a-fim cliente passou?
   - Lista de bugs encontrados pelo cliente registrada (issues no repo ou documento)?
3. Marcar Blueprint §11 Sprint 3 todos ✅.
4. Session log closure descrevendo v1.0 candidata pra App Store + Play Store submission.
5. Commit final: docs(blueprint): v1.0 ready + cliente entregue em ambas plataformas.

Próxima fase (pós-Sprint 3, fora deste plano): polish + screenshots oficiais + privacy policy final + categoria + marketing → submission pra production.
```

---

## Templates auxiliares

### Audit-only (validar um Sprint MD sem executar)

Use se quer só validar o MD sem rodar nada.

```
Audit-only do MD docs/superpowers/plans/sprint-[N]-*.md.

Não execute Tasks. Apenas:
1. /prime
2. Leia o MD inteiro
3. Despache agente Explore pra rodar o "Audit checklist" do final do MD
4. Reporte holes em ≤500 palavras + sugestões de correção
5. Aguarde minha decisão de corrigir ou prosseguir.

NÃO commita nada, NÃO altera código.
```

### Recovery (algo quebrou)

Use se uma sessão anterior deixou estado inconsistente.

```
Recovery session.

Algo está estranho: [descreva o sintoma em 1-2 frases].

1. /prime
2. git status + git log --oneline -10
3. Identifique o último commit estável (lefthook GREEN, analyze 0, test PASS)
4. Reporte hipóteses do que quebrou + opções de recovery (revert vs fix forward)
5. NÃO faça reset destrutivo sem confirmação minha.

Se sintoma é "Firebase iOS 15 vs 13", aplique recovery flow da memória raro-pattern-flutter-ios-regen-xcconfig-spm-recovery:
  - quit Xcode → bun --filter @raro/mobile run pub:get → rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-* → reabrir Xcode → aguardar Package Resolution → build via terminal.
```

### Continuação (sessão anterior pausada mid-Task)

Use se uma sessão foi interrompida sem terminar o Task.

```
Continuação Sprint [N] Task [TASK].

Sessão anterior pausou mid-Task. Estado:
[última coisa que aconteceu]

1. /prime
2. git status + ler último commit (git log --oneline -5)
3. Releia docs/superpowers/plans/sprint-[N]-*.md seção "Task [TASK]" pra identificar próximo step não-concluído
4. Reporte: qual step faltava? Posso continuar de onde parou?
5. Aguarde meu OK antes de prosseguir.
```

---

## Lembretes universais (vale pra TODA sessão)

- **`/prime` SEMPRE** no início — re-injeta Blueprint + INDEX + invariants. Não confiar em contexto pré-existente.
- **Audit ANTES de executar** — agente Explore lê o MD fresh e reporta holes. Esses MDs foram escritos rápido por um agente com contexto inflado; alucinações são esperadas. Pegar holes em planning é 100x mais barato que em código.
- **"FORA DE ESCOPO"** pra qualquer drift mid-task. Backlog vira nova sessão.
- **Sem `--no-verify`** em nenhum commit. Lefthook falhar = diagnose causa-raiz.
- **Confirme destrutivos**: `rm`, `git reset --hard`, `git push --force`, `git branch -d`, `git checkout .`. Pergunte antes.
- **`/session-end`** ao final — registra sessão + define próximo objetivo. Sem isso, próxima sessão perde contexto.
- **Workflows multi-agent (`/audit` adversarial)** só se eu invocar explicitamente. Default é solo focado.

---

## Em palavras simples

Esse arquivo é teu cardápio de prompts. Cada vez que abrir uma sessão pra trabalhar em alguma Sprint, vem aqui, copia o prompt da Sprint+Task que você quer executar, cola no chat. Pronto.

A regra é: o prompt manda o agente LER o MD da Sprint primeiro, AUDITAR (porque pode ter alucinação minha lá), e só DEPOIS executar a Task específica. Você só interrompe se der drift ou se aparecer ação destrutiva (apagar arquivo, deletar branch).

Não precisa entender o conteúdo da Sprint — você acompanha pelo terminal e por mim te avisando o que tá fazendo. O MD é a receita; este arquivo é o cardápio.

