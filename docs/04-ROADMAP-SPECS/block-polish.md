# Bloco Polish — specs 006, 012, 017 a 020

> 6 specs de acabamento. Quick e Medium. Dependem de quase todo o resto e fecham o produto v1.0.

## spec-006 — splash (P01)

| Campo | Valor |
|---|---|
| **Sizing** | Quick |
| **Dependências** | spec-004 (theme), spec-005 (fontes) |
| **Bloqueia** | nada (cosmetic) |
| **Telas** | P01 |
| **ADRs** | nenhum novo |

### Atomic micro-sprints

#### 6.1 — Splash widget + logo animation

`apps/mobile/lib/features/splash/presentation/splash_screen.dart`. Logo PNG do `assets/images/raro-logo.png` (copiar do prototype assets na primeira oportunidade) com `logoBreathe` animation 3.4s ease-in-out. Dots loader pulsando.

**Verification:**
- `design-fidelity-checker` aprova P01
- Animation roda smooth em simulator
- Auto-advance para P02 (onboarding) após 1.8s (matching protótipo)

**Commit:** `feat(splash): tela p01 com logo breathe + dots loader — spec-006 µ-sprint 6.1`

#### 6.2 — Asset copy + golden

Copia `docs/briefing/prototype/assets/raro-logo.png` para `apps/mobile/assets/images/raro-logo.png`. Golden de P01 idle. **Commit:** `chore(splash): copia raro-logo.png + golden p01 — spec-006 µ-sprint 6.2`

### Gates

- `design-fidelity-checker` aprova P01 (logoBreathe é microinteração crítica)

---

## spec-012 — i18n-scaffold

| Campo | Valor |
|---|---|
| **Sizing** | Quick |
| **Dependências** | spec-001 (AppLanguage enum) |
| **Bloqueia** | qualquer spec que adicione string UI (013, 014, 018, etc.) |
| **Telas** | nenhuma direto, habilita todas |
| **ADRs** | nenhum novo |

### Atomic micro-sprints

#### 12.1 — `flutter_localizations` setup

`apps/mobile/lib/l10n/app_pt.arb`, `app_en.arb`, `app_es.arb` (vazios com 1 key sentinel `helloWorld`). `apps/mobile/l10n.yaml` configurando geração. **Commit:** `feat(i18n): flutter_localizations setup com 3 arb files vazios — spec-012 µ-sprint 12.1`

#### 12.2 — Wire em `MaterialApp.router`

`localizationsDelegates: AppLocalizations.localizationsDelegates`, `supportedLocales`, fallback `pt-BR`. **Commit:** `feat(i18n): wire materialapp com localizationsdelegates — spec-012 µ-sprint 12.2`

#### 12.3 — Provider de language override

`@riverpod LanguageProvider` lê de `shared_preferences`, default = system locale, fallback `pt-BR`. **Commit:** `feat(i18n): language provider com override em shared_preferences — spec-012 µ-sprint 12.3`

#### 12.4 — Test e doc

Test que valida fallback. Doc `docs/setup/i18n-guide.md` mostrando como adicionar string nova (passos para `.arb` + `flutter gen-l10n`). **Commit:** `docs(i18n): guide e teste de fallback — spec-012 µ-sprint 12.4`

### Gates

- `flutter gen-l10n` roda sem erro
- App renderiza em `pt-BR` (default) e troca dinamicamente para `en`/`es`

---

## spec-017 — permissions

| Campo | Valor |
|---|---|
| **Sizing** | Quick |
| **Dependências** | spec-001 (AppPermission, PermissionState) |
| **Bloqueia** | spec-018 (onboarding mostra P04) |
| **Telas** | P04 |
| **ADRs** | nenhum novo |

### Atomic micro-sprints

#### 17.1 — `PermissionsService` wrapper `permission_handler`

`apps/mobile/lib/core/permissions/permissions_service.dart`. Métodos: `request(AppPermission)`, `status(AppPermission)`. Usa `permission_handler ^12.0.1`. **Commit:** `feat(permissions): service wrapper permission_handler — spec-017 µ-sprint 17.1`

#### 17.2 — Tela P04

Lista 2 cards (Câmera + Microfone) com ícone, título, descrição. CTA "Continuar" gradient → solicita permissões nativas → próxima tela. **Commit:** `feat(permissions): tela p04 com 2 cards e cta continuar — spec-017 µ-sprint 17.2`

#### 17.3 — Golden + validator

**Commit:** `docs(permissions): goldens p04 + session log spec-017 — spec-017 µ-sprint 17.3`

### Gates

- `design-fidelity-checker` aprova P04

---

## spec-018 — onboarding

| Campo | Valor |
|---|---|
| **Sizing** | Medium |
| **Dependências** | spec-017 (permissions), spec-012 (i18n se mergeada) |
| **Bloqueia** | spec-019 (xiaomi onboarding pode aparecer aqui) |
| **Telas** | P02 ("Grave sem tocar"), P03 ("Nunca perca o momento") |

### Atomic micro-sprints

#### 18.1 — Tela P02 "Grave sem tocar"

Mic icon com halos concêntricos, copy "Diga 'Raro' para iniciar ou encerrar". Paginação 1/2. Botão "Avançar" / "Pular". **Commit:** `feat(onboarding): tela p02 grave sem tocar — spec-018 µ-sprint 18.1`

#### 18.2 — Tela P03 "Nunca perca o momento"

Visual de buffer com waveform + copy "Raro Replay salva os últimos 15 ou 30s". Paginação 2/2. Botão "Avançar" gradient. **Commit:** `feat(onboarding): tela p03 nunca perca o momento — spec-018 µ-sprint 18.2`

#### 18.3 — Routing onboarding → P04 → P05

`OnboardingController` Riverpod com state `currentStep`. Flag em `shared_preferences` (`hasSeenOnboarding`) para skip em re-launches. **Commit:** `feat(onboarding): routing onboarding com flag em shared_prefs — spec-018 µ-sprint 18.3`

#### 18.4 — Goldens P02 + P03 + Validator

**Commit:** `docs(onboarding): goldens p02 p03 + session log spec-018 — spec-018 µ-sprint 18.4`

---

## spec-019 — xiaomi-onboarding

| Campo | Valor |
|---|---|
| **Sizing** | Quick |
| **Dependências** | spec-018 (onboarding base), spec-012 (i18n) |
| **Telas** | M02 (Xiaomi MIUI modal) |
| **ADRs** | 0012 (xiaomi híbrido) |

### Atomic micro-sprints

#### 19.1 — Detecção MIUI via `device_info_plus`

`MiuiDetector` em `apps/mobile/lib/core/permissions/miui_detector.dart`. Heurística: `manufacturer == 'Xiaomi'` OR `manufacturer == 'Redmi'` OR `ro.miui.ui.version.name` property exists. **Commit:** `feat(xiaomi): miui detector via device_info_plus — spec-019 µ-sprint 19.1`

#### 19.2 — Modal M02 com 4 cards numerados

`xiaomi_onboarding_modal.dart`. 4 cards (1. Abra Configurações, 2. Bateria & Performance, 3. Sem restrições, 4. Bloqueie nas recentes). CTAs "Mais tarde" / "OK, vou configurar". **Commit:** `feat(xiaomi): modal m02 com 4 passos miui — spec-019 µ-sprint 19.2`

#### 19.3 — Trigger automático na 1ª abertura em MIUI

Flag em `shared_preferences` (`xiaomiOnboardingShown`). Dispara após P03 e antes de P04 em devices MIUI. **Commit:** `feat(xiaomi): trigger automático em primeira abertura miui — spec-019 µ-sprint 19.3`

#### 19.4 — Goldens M02 + Validator

**Commit:** `docs(xiaomi): goldens m02 + session log spec-019 — spec-019 µ-sprint 19.4`

### Gates

- `design-fidelity-checker` aprova M02
- Manual test em device Xiaomi real (DoD Blueprint Seção 11)

---

## spec-020 — settings

| Campo | Valor |
|---|---|
| **Sizing** | Medium |
| **Dependências** | spec-007 (camera), 010 (volume), 011 (lock), 012 (i18n), 013 (paywall) — quase tudo |
| **Bloqueia** | nada (última do roadmap) |
| **Telas** | P06 |

### Atomic micro-sprints

#### 20.1 — Settings controller (Riverpod) que agrega todas configs

`settings_controller.dart` consumindo providers de Camera, ReplayBuffer, ControlMode, Language, etc. (todos já existentes das specs anteriores). **Commit:** `feat(settings): controller agregador de configs — spec-020 µ-sprint 20.1`

#### 20.2 — Tela P06 — sections

Seções: "Qualidade de Gravação" (resolução, fps, estabilização), "Raro Replay" (buffer 15/30s), "Controle de Gravação" (voice/volume toggle), "Idioma" (3 flags), "Ver Planos" (CTA), "Sobre" (versão, ToS, Privacy). **Commit:** `feat(settings): tela p06 com todas sections — spec-020 µ-sprint 20.2`

#### 20.3 — Flags do seletor de idioma

PT/ES/EN com flag SVG. Persiste em LanguageProvider de spec-012. **Commit:** `feat(settings): seletor de idioma com flags svg — spec-020 µ-sprint 20.3`

#### 20.4 — Item "Configuração MIUI" condicional

Mostra item em Settings → Sobre apenas em MIUI (via `MiuiDetector`). Tap abre M02 modal. **Commit:** `feat(settings): item config miui condicional em settings sobre — spec-020 µ-sprint 20.4`

#### 20.5 — Goldens P06 + Validator final

**Commit:** `docs(settings): goldens p06 + session log spec-020 — spec-020 µ-sprint 20.5`

### Gates

- `design-fidelity-checker` aprova P06 (tela mais densa do app)
- Validator final invocado: garantia que todas 20 specs estão mergeadas

---

## Validação cruzada FINAL do roadmap (após spec-020 mergeada)

Esta é a "release v1.0" gate, fechando o ciclo do bootstrap inteiro:

### Funcional

- [ ] **Fluxo end-to-end inteiro** roda em iPhone real e Pixel real:
  Boot → Splash (P01) → Onboarding (P02→P03) → Permissões (P04) → [Xiaomi modal M02 se MIUI] → Camera (P05) → Voice command "Raro" inicia gravação → "Raro" para → tenta salvar sem subscription → Popup M01 → Paywall (P09) → Checkout (P10 com Apple/Google) → Toast 30 dias grátis → volta P05 com Entitlement ativo → grava novamente → salva → Gallery (P07) → Preview (P08) → Share → Settings (P06) muda resolução/idioma/control mode → Lock mode (P05a) durante gravação → double-tap sai
- [ ] Volume buttons (físicos e BT AirPods) funcionam quando ControlMode==volume
- [ ] Wake word "Raro" detectado > 90% em ambiente silencioso
- [ ] Replay Buffer 30s/4K sem crashes em iPhone 15 Pro + Pixel 8 Pro
- [ ] Lock mode reduz bateria 50%+ vs tela acesa em 10min de gravação

### Técnico

- [ ] `bun run lint && typecheck && test` zero issues em todos os workspaces
- [ ] `flutter analyze` zero issues
- [ ] Coverage: use cases ≥ 80%, repos ≥ 70%, widgets críticos ≥ 60%
- [ ] Build release `.ipa` (signing iOS do cliente) + `.aab` (signing Android do cliente)
- [ ] App passa no review da App Store (sandbox test prévio)
- [ ] App passa no review do Google Play (test track)

### Processo

- [ ] 20 specs mergeadas (001-020) + 21 ADRs (0000-0020 incluindo 8 novos: 0013-0020)
- [ ] 20 session logs em `docs/sessions/` (um por spec)
- [ ] CHANGELOG bumpado para 1.0.0 com todas entries
- [ ] `docs-lint` zero issues no repo inteiro
- [ ] Todos goldens regerados e versionados
- [ ] Privacy Manifest iOS completo (speech, mic, camera, photo library)
- [ ] Tag git `v1.0.0` + push tags

### Transferência ao cliente (release-condicional)

- [ ] App Store Connect: transfer app ownership para conta do cliente
- [ ] Play Console: transfer ownership
- [ ] Firebase: transferir project para cliente
- [ ] RevenueCat: transferir project + API keys regeneradas
- [ ] GitHub: transferir repo para cliente
- [ ] ADR final documentando transferência

## DAG final de execução (recomendado)

```
Mês 1: Foundation
  Semana 1: spec-001 (API contract) → bloqueia tudo
  Semana 2: spec-002+003+004+005 em paralelo (infra)
  Semana 3: spec-007 (camera bridge) — início da espinha dorsal
  Semana 4: spec-008 (replay buffer)

Mês 2: Core do produto
  Semana 5: spec-009 (voice) + spec-010 (volume)
  Semana 6: spec-006 (splash) + spec-012 (i18n) em paralelo
  Semana 7: spec-013 (paywall) + spec-014 (checkout)
  Semana 8: spec-011 (lock mode) + spec-015 (gallery)

Mês 3: Acabamento e release
  Semana 9: spec-016 (preview) + spec-017 (permissions)
  Semana 10: spec-018 (onboarding) + spec-019 (xiaomi)
  Semana 11: spec-020 (settings) — última spec
  Semana 12: testes finais em devices, submissão lojas, transferência
```

Estimativas não são commitment — são pontos de referência. Velocidade real depende de incidentes nativos (xcode signing, gradle deps, MIUI quirks).
