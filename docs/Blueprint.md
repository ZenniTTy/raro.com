# RARO — Blueprint Arquitetural

> **Fase 1 do bootstrap-mobile-flutter.** Documento de decisão. Após aprovação, vira fonte de verdade técnica do projeto. Mudanças subsequentes via ADRs em `docs/decisions/`.

| Campo | Valor |
|---|---|
| Projeto | RARO |
| Nome nas lojas | Raro Camera |
| Bundle ID / Application ID | `com.rarocamera` |
| Versão do Blueprint | 1.0 |
| Data | 2026-05-25 |
| Status | **Approved — 2026-05-25** |
| Briefing fonte | [docs/briefing/original-briefing.md](briefing/original-briefing.md) |
| Protótipo fonte | [docs/briefing/prototype/Prototipo-RARO.html](briefing/prototype/Prototipo-RARO.html) |

---

## 1. Resolução de divergências briefing × protótipo

A Seção 3.2 do briefing define o protótipo como fonte de verdade inegociável. Onde briefing e protótipo divergiram, registramos a decisão explícita com justificativa abaixo.

| # | Tópico | Briefing | Protótipo | **Decisão** | Justificativa |
|---|---|---|---|---|---|
| 1 | Wake word | `"OkCamera"` | `"Raro"` | **`"Raro"`** | Protótipo prevalece (Seção 3.2). Mais alinhado com branding "Raro Camera". "Ok Camera" **não aparece** em código, docs, ADRs ou copy do app. |
| 2 | Free trial | 30 dias | 15 dias | **30 dias** | Decisão executiva do cliente. Atualizar copy do popup, paywall (mensal + anual), checkout e qualquer string. Configurado no RevenueCat dashboard. |
| 3 | Planos | Só mensal R$ 9,90 | Mensal R$ 9,90 + Anual R$ 89,90 | **Ambos** | Protótipo prevalece (Seção 3.2). Card anual carrega badge "MELHOR OFERTA". Equivalente mensal R$ 7,49. 2 SKUs no RevenueCat. |
| 4 | Controle por volume / BT | Fora de escopo | Modo "Volume OFF" + modal "Controle conectado · AirPods Pro" | **Implementar** | Protótipo prevalece. Botões físicos de volume capturados via APIs nativas (não controle BT customizado). Fones BT que reportam como volume funcionam automaticamente. |
| 5 | Tradução em tempo real | Fora de escopo | Código `screenTranslation()` existe mas não está em `registerScreens()` nem no Hub Dev | **Fora de escopo (v1.0)** | Briefing prevalece. Protótipo tem código morto não navegável. Custo recorrente (Whisper/API) incompatível com R$ 9,90/mês. |
| 6 | Onboarding Xiaomi | Onboarding inicial | Modal sob demanda (`xmSheet`) só visível via Hub Dev | **Híbrido: modal automática na 1ª abertura em device MIUI + botão manual em Settings** | Combinação que respeita o conteúdo do protótipo (mesmas 4 etapas) e atende a intenção do briefing (orientação ativa). |

**Termos descartados que não devem aparecer em lugar nenhum:** `Ok Camera`, `OkCamera`, `"hey OkCamera"`, qualquer variação.

---

## 2. Stack tecnológica (versões fixadas via Context7 + pub.dev em 2026-05-25)

### 2.1 Core

| Categoria | Tecnologia | Versão fixada | Context7 ID |
|---|---|---|---|
| Framework | **Flutter** | `>=3.44.0 <4.0.0` (canal stable, ADR-0014) | `/websites/flutter_dev` |
| Linguagem | **Dart** | `^3.12.0` | (incluso no Flutter SDK) |
| State management | **Riverpod 3** com codegen | `flutter_riverpod: ^3.3.1` + `riverpod_annotation: ^4.0.2` + `riverpod_generator: ^4.0.3` | `/rrousselgit/riverpod` |
| Routing | **go_router** | `^17.2.3` | `/websites/pub_dev_packages_go_router` |
| Build runner (codegen) | `build_runner` | `^2.15.0` | — |
| Lints | `riverpod_lint` + `custom_lint` + `flutter_lints` | `^3.1.3` / `^0.8.1` / `^7.0.0` | — |

### 2.2 Câmera e mídia — native bridges custom (decisão crítica)

**Justificativa registrada no briefing Seção 6.2:** o plugin `camera` oficial do Flutter Team não suporta alternância física entre lentes 0.5x e 1x (issues `flutter#91247` e `flutter#173406`, abertas em maio/2026). Replay Buffer também não tem plugin pronto. Implementação 100% nativa.

| Plataforma | Stack nativa | Responsabilidade |
|---|---|---|
| iOS | **AVFoundation** (Swift) | `AVCaptureDevice.DiscoverySession` com `builtInUltraWideCamera` + `builtInWideAngleCamera`. `AVCaptureSession` + `AVAssetWriter` para pipeline e Replay Buffer. |
| Android | **CameraX** (Kotlin) | `CameraSelector.Builder().addCameraFilter()` com filtro por `LENS_INFO_AVAILABLE_FOCAL_LENGTHS`. `MediaCodec` + `MediaMuxer` para encoding + buffer. |

**Method Channels (Dart ↔ Swift/Kotlin):**

| Channel | Responsabilidade |
|---|---|
| `com.rarocamera/camera` | Discovery de lentes, alternância 0.5×/1×, resolução, FPS, captura |
| `com.rarocamera/replay_buffer` | Buffer circular em RAM (15s/30s), salvamento (concatenação buffer + stream) |
| `com.rarocamera/voice` | Inicialização do reconhecimento, detecção wake word `"Raro"`, callbacks |
| `com.rarocamera/volume` | Captura de eventos de botões físicos de volume `+`/`−` (modo "Volume OFF") |

> **Atualização 2026-05-26 (ADR-0013):** Os 4 channels acima são gerados via **Pigeon ^26.3.2** a partir de schemas Dart únicos em `apps/mobile/pigeons/{camera,replay_buffer,voice,volume}_api.dart`. Strings de namespace nunca são digitadas em Swift ou Kotlin; codegen sincroniza Dart + iOS + Android. Cada bridge usa **sub-package Kotlin distinto** (`com.rarocamera.raro_mobile.generated.{camera,replay_buffer,voice,volume}`) para evitar redeclaration de `FlutterError` (Pigeon gera essa classe em cada `.g.kt`; pacote comum causa colisão). Ver ADR-0013 e spec `api-contract-shared`.

### 2.3 Reconhecimento de voz (wake word `"Raro"`)

| Plataforma | Tecnologia | Notas |
|---|---|---|
| iOS | **Speech Framework** — `SFSpeechRecognizer` | On-device. Limite ~1 min/sessão, reinício automático. |
| Android | **SpeechRecognizer** (`android.speech`) | API 31+ com `EXTRA_PREFER_OFFLINE` força on-device. |

**Privacidade:** áudio processado exclusivamente local. Declarado em `Info.plist` (`NSSpeechRecognitionUsageDescription`) e Privacy Manifest iOS.

### 2.4 Assinaturas e billing

| Item | Decisão |
|---|---|
| Plataforma | **RevenueCat** — `purchases_flutter: ^10.1.1` |
| iOS Billing | StoreKit (RevenueCat decide entre v1/v2 automaticamente; manter default) |
| Android Billing | Google Play Billing (gerenciado pelo RevenueCat) |
| Validação receipts | Server-side via RevenueCat |
| SKUs configurados | `raro_premium_monthly_BRL_9_90` + `raro_premium_yearly_BRL_89_90` |
| Free trial | **30 dias** em ambos SKUs |
| Entitlement | `premium` (binário ativo/inativo) |
| Webhooks | RevenueCat → Firebase Analytics (opcional, via webhook integration) |

### 2.5 Backend e infraestrutura

**Decisão:** **client-only.** Sem `apps/api`, sem `packages/prisma`, sem Docker Compose com Postgres.

**Justificativa (briefing 6.5):** RevenueCat gerencia assinaturas server-side, Firebase gerencia analytics/crashes, voz é on-device, captura é nativa no dispositivo, vídeos permanecem no device.

**Estrutura monorepo:**
```
raro/
├── apps/
│   └── mobile/          # Flutter app
└── packages/
    └── shared/          # constantes, enums, eventos (Dart puro)
```

### 2.6 Analytics e crash reporting

| Categoria | Lib | Versão |
|---|---|---|
| Firebase Core | `firebase_core` | `^4.9.0` |
| Analytics | `firebase_analytics` | `^12.4.1` |
| Crash reporting | `firebase_crashlytics` | `^5.2.2` |
| Logging Dart | `logger` | `^2.7.0` |

### 2.7 Persistência, permissões, compartilhamento, device info

| Categoria | Lib | Versão |
|---|---|---|
| Key-value | `shared_preferences` | `^2.5.5` |
| Paths | `path_provider` | `^2.1.5` |
| Permissões | `permission_handler` | `^12.0.1` |
| Compartilhamento | `share_plus` | `^13.1.0` |
| Device info (detecção MIUI) | `device_info_plus` | `^13.1.0` |

### 2.8 i18n

| Categoria | Decisão |
|---|---|
| Framework | `flutter_localizations` (SDK) + `intl: ^0.20.2` |
| Arquivos | `.arb` (Application Resource Bundle) |
| Geração | `flutter gen-l10n` |
| Idiomas v1.0 | `pt-BR` (default), `en`, `es` |
| Detecção inicial | `Locale` do sistema |
| Override manual | Settings → Idioma → persiste em `shared_preferences` |
| Fallback | `pt-BR` |

### 2.9 Testes

| Categoria | Lib | Versão |
|---|---|---|
| Goldens | `alchemist` | `^0.14.0` |
| Mocks | `mocktail` | `^1.0.5` |
| Test runner | `flutter_test` (SDK) | — |
| Integration | `integration_test` (SDK) | — |

### 2.10 Monorepo tooling

| Categoria | Tecnologia | Versão |
|---|---|---|
| Package manager root | **Bun** | `>=1.3.13` |
| Task runner | **Turborepo** | `^2.x` (latest) |
| Git hooks | **lefthook** | latest |
| Commit linting | `@commitlint/cli` + `@commitlint/config-conventional` | `^19.x` |
| JSON/MD formatter | **Biome** | `^1.x` |
| Native bridges codegen | `pigeon` | `^26.3.2` |
| Theme tokens codegen | `theme_tailor` + `theme_tailor_annotation` | `^3.1.3` |
| XML parse (parity tests) | `xml` | `^6.5.0` |
| Dart formatter | `dart format` (SDK) | — |

### 2.11 Assets e fontes (regra de ADR)

| Família | Arquivos | Origem |
|---|---|---|
| Display | **Space Grotesk** (VF, eixo `wght`) | Google Fonts — SIL OFL |
| UI default | **Inter** (VF, eixo `wght`) | Google Fonts — SIL OFL |
| Mono / dados técnicos | **JetBrains Mono** (VF, eixo `wght`) | Google Fonts — SIL OFL |
| Logo | `raro_logo.png` | protótipo (`assets/logo/`) |

Bundlados em `apps/mobile/assets/{fonts,logo}/` e registrados em `pubspec.yaml` (`fonts:`/`assets:`). Variable fonts: 1 arquivo por família; `FontWeight.w400..w700` ajusta o eixo `wght` automaticamente (Flutter 3.44 breaking change `font-weight-variation`).

**Regra de ADR (resolve drift detectado na sessão 0011):** **bundlar assets (fontes, imagens, ícones) e registrá-los no `pubspec.yaml` NÃO exige ADR.** ADR é obrigatório apenas para **dependências/packages** (CLAUDE.md §3 "atualizar dep = abrir ADR"). O hook `warn-adr-drift` avisa em qualquer toque no `pubspec.yaml` — esse aviso é informativo para mudanças de asset; bloqueante de fato só para mudança de `dependencies:`/`dev_dependencies:`.

---

## 3. Arquitetura técnica

### 3.1 Camadas (Clean Architecture)

```
┌──────────────────────────────────────────────────────────┐
│  PRESENTATION                                            │
│  Widgets Flutter · Telas · Riverpod providers (codegen)  │
│  Sem regra de negócio. Observa estado, dispara intents.  │
└──────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────┐
│  DOMAIN                                                  │
│  Entidades · Use Cases · Interfaces de repositório       │
│  Dart puro, sem framework. Testável isolada.             │
└──────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────┐
│  DATA                                                    │
│  Implementações concretas · SDKs · Method Channels       │
│  RevenueCat, Firebase, shared_preferences, file system   │
└──────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────┐
│  NATIVE BRIDGES                                          │
│  Dart ↔ Swift (iOS) / Kotlin (Android)                   │
│  Camera, Replay Buffer, Voice, Volume                    │
└──────────────────────────────────────────────────────────┘
```

### 3.2 Estrutura de pastas alvo

```
apps/mobile/
├── lib/
│   ├── core/
│   │   ├── theme/             # design tokens do protótipo (cores, gradientes, tipografia)
│   │   ├── constants/         # constantes globais (bundle IDs, wake word, SKUs)
│   │   ├── permissions/       # wrappers permission_handler
│   │   ├── native_bridges/    # Dart side dos Method Channels
│   │   └── utils/
│   ├── features/
│   │   ├── splash/
│   │   ├── onboarding/        # onb1, onb2
│   │   ├── permissions/
│   │   ├── camera/            # tela principal + HUD + record control
│   │   ├── replay_buffer/
│   │   ├── voice/
│   │   ├── volume_control/    # captura botões físicos de volume
│   │   ├── lock_mode/
│   │   ├── gallery/
│   │   ├── preview/
│   │   ├── subscription/      # paywall + checkout + popup
│   │   ├── settings/
│   │   └── xiaomi_guide/      # modal MIUI
│   ├── l10n/
│   │   ├── app_pt.arb         # default
│   │   ├── app_en.arb
│   │   └── app_es.arb
│   ├── app.dart
│   ├── main.dart
│   └── main_dev.dart
├── ios/Runner/Native/
│   ├── CameraManager.swift
│   ├── ReplayBufferManager.swift
│   ├── VoiceWakeWordDetector.swift
│   └── VolumeButtonObserver.swift
└── android/app/src/main/kotlin/com/rarocamera/
    ├── CameraManager.kt
    ├── ReplayBufferManager.kt
    ├── VoiceWakeWordDetector.kt
    └── VolumeButtonObserver.kt
```

### 3.3 Restrições de plataforma conhecidas

**iOS:**
- Captura contínua em background não é permitida. Replay Buffer e voz operam apenas em foreground (tela pode estar escurecida via modo lock).
- `SFSpeechRecognizer` tem limite ~1 min/sessão → reinício automático.
- Botões de volume capturáveis via `AVAudioSession` + observer no `outputVolume`; não há API direta para volume buttons.

**Android:**
- Fabricantes com camadas (Xiaomi/MIUI, Samsung/OneUI, Oppo/ColorOS) aplicam kill agressivo em background → onboarding Xiaomi obrigatório.
- Volume buttons via `dispatchKeyEvent` ou `MediaSession` callback.

**Hardware:**
- 4K 60 FPS apenas em iPhone 12+ e Android flagships → fallback automático para menor resolução.
- Lente 0.5× condicionada à presença física no device → se não houver, esconde botão `0.5×` no HUD.

---

## 4. Design system (extraído do protótipo)

### 4.1 Tokens de cor (do `:root` do protótipo)

| Token | Hex | Uso |
|---|---|---|
| `--bg-deep` | `#000000` | Background principal do app |
| `--bg-elev` | `#0a0a0a` | Surfaces elevadas (cards, sheets, settings) |
| `--bg-card` | `#141414` | Cards densos (chips inativos) |
| `--ink` | `#ffffff` | Texto principal |
| `--ink-dim` | `#a3a3a3` | Texto secundário |
| `--ink-faint` | `#525252` | Texto terciário / meta info |
| `--border` | `#1f1f1f` | Bordas padrão |
| `--border-bright` | `#2e2e2e` | Bordas ativas / hover |
| `--raro-red` | `#ff2d55` | Acento principal (REC, alerta) |

### 4.2 Gradientes (signature visual do RARO)

**Gradiente linear arco-íris (`--raro-gradient`)** — usado em CTAs primárias, underline da logo, indicadores ativos:
```
linear-gradient(90deg,
  #ff2d55 0%,    /* red */
  #ff6b35 16%,   /* orange */
  #ffcc00 33%,   /* yellow */
  #34c759 50%,   /* green */
  #00c7be 66%,   /* teal */
  #007aff 83%,   /* blue */
  #af52de 100%   /* purple */
)
```

**Gradiente radial (`--raro-radial`)** — usado em logos animadas, halos:
```
radial-gradient(circle,
  #ffcc00 0%, #ff6b35 25%, #ff2d55 50%, #af52de 75%, #007aff 100%
)
```

**Gradiente radial vermelho (`--raro-red-radial`)** — toggle ON, slider thumb, check ícone:
```
radial-gradient(circle, #ff5470 0%, #ff2d55 60%, #c8002a 100%)
```

**Regras de aplicação:**
- CTAs primárias (Avançar, Continuar, Assinar agora, Confirmar assinatura): fundo `--raro-gradient`, texto preto.
- Botões secundários: fundo `--bg-elev`, borda `--border-bright`, texto branco.
- Card border animada (`grad-border`) com `background-size: 200%` e shift 5s linear infinite.
- Plan card selecionado: conic-gradient amarelo→laranja→vermelho na borda.

### 4.3 Tipografia

| Família | Pesos | Função no app |
|---|---|---|
| **Space Grotesk** | 400, 500, 600, 700 | Display / wordmark RARO / títulos de tela |
| **Inter** | 400, 500, 600, 700 | UI default (body, labels, botões) |
| **JetBrains Mono** | 400, 500, 700 | Dados técnicos (FPS, resolução, timers, section labels com letterspacing) |

Escala observada no protótipo (mobile 393×852):

| Hierarquia | Tamanho | Família | Peso | Letter-spacing |
|---|---|---|---|---|
| Display H1 (wordmark) | 88px | Space Grotesk | 700 | `.04em` |
| Display H2 (paywall) | 30px | Space Grotesk | 700 | `-0.02em` |
| Display H3 (onboarding/settings) | 22–28px | Space Grotesk | 700 | `-0.02em` |
| Section label | 10–11px | JetBrains Mono | uppercase | `.15–.18em` |
| Body | 13–15px | Inter | 400/500 | normal |
| Mono data | 10–14px | JetBrains Mono | 400–600 | `.05–.1em` |

### 4.4 Logo

**Asset:** [docs/briefing/prototype/assets/raro-logo.png](briefing/prototype/assets/raro-logo.png)

Composição: ícone quadrado app-icon com R angular branco, ponto luminoso colorido (gradient radial arco-íris), wordmark "RARO", linha decorativa arco-íris inferior. Filtro `drop-shadow` arco-íris animado (`logoBreathe` keyframes, 3.4s ease-in-out infinite).

Linha decorativa associada (`grad-line`): height 1.5px, fundo `--raro-gradient`. Usada como divisor abaixo da logo e em bottoms de telas.

### 4.5 Componentes visuais (do protótipo)

**Botões:**
- Primário: `bg: --raro-gradient; color: #000; py-3.5 rounded-2xl text-[15px] font-bold`
- Secundário: `bg: --bg-elev; border: --border-bright; color: #fff`
- Texto: `color: --ink-dim`
- Touch animation: `transition: transform .12s ease; :active scale(.97)` (classe `.btn-touch`)

**Record button:**
- Idle: 72×72 círculo, `bg: #ff2d55`, anel duplo (preto + branco translúcido), glow vermelho
- Recording: bg preto, anel branco 3px, miolo quadrado 28×28 com `recPulse` 1.2s

**Pills/Chips:**
- Pill (inactive): `border: --border-bright; bg: rgba(10,10,10,.6); padding: 6px 12px; rounded-full; color: --ink-dim`
- Pill (active): `bg: #fff; color: #000`
- Chip (settings): `bg: --bg-card; border: --border-bright; padding: 8px 14px; rounded-[10px]; color: --ink-dim`
- Chip (active): `bg: #1a1a1a; color: #fff; border-color: #fff`

**Cards:** `bg: --bg-elev; border: --border; rounded-[16px]; padding: 16px`

**Toggle:** 42×24, knob 20×20, off `bg: #1f1f1f knob: #737373`, on `bg: #0a0a0a knob: --raro-red-radial + glow vermelho`

**Slider:** track 3px `bg: #1f1f1f`, thumb 18×18 `bg: --raro-red-radial` com ring preto 2px

**Sheet (modal bottom):** `bg: --bg-elev; rounded-top-24; border-top: --border-bright; slide-in cubic-bezier(.4,0,.2,1) .35s`

**Backdrop:** `bg: rgba(0,0,0,.6); backdrop-blur(8px)`

### 4.6 Microinterações observadas

- **Logo breathe:** drop-shadow arco-íris pulsa 3.4s
- **Buffer fill:** barra `linear-gradient` arco-íris preenche 15s e reseta (`bufferFill` animation)
- **Voice listening glow:** anel arco-íris 2s pulsando (não confirmado se está em uso no fluxo final)
- **Record pulse:** miolo do record button pulsa opacidade 1↔0.55 a 1.2s
- **Focus ring (tap-to-focus):** quadrado 64×64 branco, scale 1.4→1, fade 1.2s
- **Lens switch:** viewport blur 4px + scale 1.02 por 220ms
- **Gradient border animated:** `gradShift` background-position 0%→200% em 5s linear
- **Plan card hue spin:** conic-gradient gira `--a` 0→360° em 6s linear (CSS `@property`)
- **Dot loader (splash):** 3 dots pulsam com cores diferentes em sequência

### 4.7 Grid e espaçamento

- Unidade base: **4px** (Tailwind scale: 0.5, 1, 2, 3, 4, 5, 6, 7, 10, 12 = 2/4/8/12/16/20/24/28/40/48 px)
- Paddings comuns de tela: `px-5` (20px) ou `px-6` (24px)
- Border radius: cards `16px`, botões CTA `2xl = 16px`, pills `999px`, chip `10px`, sheet top `24px`, phone screen `50px`
- Phone target: **393×852** (iPhone 15 Pro lógico)

---

## 5. Mapa de telas (Seção 5.8 do briefing — preenchida)

13 telas navegáveis + 3 modais + 2 dev-only.

### Telas navegáveis (v1.0)

| ID | Nome | Função | Componentes principais | Estados | Transições |
|---|---|---|---|---|---|
| P01 | Splash | Logo animada (breathe), dots loader, tagline "CAPTURE · UNSCRIPTED" | Logo PNG, dot-loader, meta-tagline | idle (1.8s) | → P02 (auto) |
| P02 | Onboarding 1 — "Grave sem tocar" | Explica wake word `"Raro"` | Mic icon com halos concêntricos, copy, paginação (1/2), botão "Avançar" + "Pular" | static | "Avançar" → P03 / "Pular" → P04 |
| P03 | Onboarding 2 — "Nunca perca o momento" | Explica Raro Replay 15/30s | Visual de buffer com waveform, copy, paginação (2/2), botão "Avançar" (gradient) | static | "Avançar" → P04 |
| P04 | Permissões essenciais | Lista permissões necessárias | 2 cards (Câmera + Microfone) com ícone, título, descrição. CTA "Continuar" gradient | static (pedido nativo OS é fora do app) | "Continuar" → P05 |
| P05 | Câmera (home) | Viewport com rule of thirds, HUD, controles | Top bar (close, "RARO"), viewport (rule-thirds, focus ring, buffer bar quando recording), Raro Replay pill (15s/30s), REC indicator (00:00:00) quando recording, hint central "DIGA 'RARO' PARA GRAVAR", lens chips 0.5×/1×, record button central, galeria left, settings right, grad-line bottom | idle / recording / lock (P05a) | close → P04 / galeria → P07 / settings → P06 / record button → recording state |
| P05a | Lock mode | Tela escurecida durante gravação | REC dot + timer mirror, hint "Toque duas vezes para sair" | recording (sempre) | double-tap → P05 |
| P06 | Configurações | Resolução, FPS, Raro Replay buffer, Controle, Idioma, Ver Planos, Sobre | Header (back, "Configurações"), cards por seção, "Ver Planos" CTA gradient, footer wordmark | scroll | back → P05 / Ver Planos → P09 |
| P07 | Galeria | Grid 3 colunas com thumbs, filtros | Header (back, "Galeria", contador), pills filtro (Todos / Hoje / Esta semana / Raro Replay), grid 3 cols com `aspect-square` thumbs, play icon, duration label, dot indicator em alguns thumbs (Raro Replay) | empty / populated | back → P05 / thumb → P08 |
| P08 | Preview | Player do vídeo + ações | Header (back, título "Vídeo · DD/MM HH:MM", share), video viewport com play button central, scrubber + tempos, info card (256MB / 02:30 / H.265), bottom actions (Compartilhar + delete + info) | paused / playing | back → P07 / share → OS share sheet / delete → confirma → P07 |
| P09 | Paywall | Escolha de plano | Wordmark "RARO" watermark sutil (opacity .05), ambient glow, título "Escolha seu plano", subtítulo com "30 dias grátis", 2 plan cards lado a lado (mensal selecionado por padrão, anual com badge "MELHOR OFERTA"), feature list (4K 60fps, Buffer estendido, Sem anúncios), links Termos+Privacidade, CTA "Assinar agora" gradient, "Restaurar compras", "Voltar", disclaimer renovação | mensal-selected / yearly-selected | close → P05 / Assinar → P10 / Restaurar → fluxo RevenueCat |
| P10 | Checkout | Confirmação + método de pagamento | Header (back, "Finalizar assinatura"), order summary card (logo + plano + período teste 30 dias + cobrança a partir de DD/MM), 2 tiles pagamento (Apple Pay com FaceID hint / Google Play), disclaimer segurança, CTA "Confirmar assinatura" (disabled até escolher método) + hint dinâmico | nenhum-selecionado / apple-selecionado / google-selecionado / processing | back → P09 / confirmar → trigger RevenueCat → toast "Assinatura ativa" → P05 |
| P11 | Termos de Uso | Texto legal | Header (back, "Termos"), conteúdo scrollável | static | back → origem |
| P12 | Política de Privacidade | Texto legal | Header (back, "Política"), conteúdo scrollável | static | back → origem |

> **Telas P11 e P12 não estão no protótipo HTML** mas estão referenciadas em Settings → Sobre como targets de navegação. Conteúdo será fornecido pelo cliente.

### Modais / overlays

| ID | Nome | Trigger | Conteúdo |
|---|---|---|---|
| M01 | Popup Assinatura | Auto: usuário sem assinatura entra em P05 (delay 450ms). Manual: trigger não declarado | Section-label "ASSINATURA", título "Assinatura necessária", explicação, CTA "Assinar agora" gradient → P09, CTA "Talvez depois" close |
| M02 | Onboarding Xiaomi MIUI | Auto: 1ª abertura do app em device MIUI (detecção via `device_info_plus`). Manual: Settings → Sobre → "Configuração MIUI" (a adicionar) | Section-label "Configuração MIUI", título "Otimização de bateria", 4 cards numerados (1: Configurações, 2: Economia de bateria do app, 3: Sem restrições, 4: Bloqueie nas recentes), CTAs "Mais tarde" + "OK, vou configurar" |
| M03 | Controle Bluetooth conectado | Auto: detecção de fone BT que reporta como volume button | Ícone bluetooth radial, título "Controle conectado", subtítulo "AirPods Pro · Pareado", card de instrução "Pressione o botão de volume...", CTA "OK, entendi" |

### Dev-only (não vão para release)

| ID | Nome | Notas |
|---|---|---|
| D01 | Hub Dev | Grid de todas as 13 telas + modais. **Não é parte do app de produção.** Pode existir como `debug` flavor durante dev. |
| D02 | Wordmark | Easter egg do protótipo. **Não implementar** no app. |

---

## 6. Funcionalidades v1.0 (mapeadas em features Flutter)

### M01 — Câmera e gravação
- Captura via native bridge (`com.rarocamera/camera`)
- Resoluções: 720p, 1080p Full HD, 4K Ultra HD, 4K 60fps (este último gated pelo paywall)
- FPS: 30 / 60
- Lentes: 0.5× ultra-wide + 1× wide (alternância física)
- Foco automático + tap-to-focus com focus ring animado
- Estabilização nativa (sempre ativa)
- Gravação contínua sem limite imposto pelo app
- Inicialização padrão: **1080p · 60fps · 1×**

### M02 — Raro Replay (Replay Buffer)
- Buffer circular em RAM via native bridge (`com.rarocamera/replay_buffer`)
- Duração configurável: **15s ou 30s** (toggle no pill da câmera + chips em Settings)
- Sempre ativo durante a câmera (não há disable, só escolha de duração)
- Pré-roll: ao iniciar gravação, prepend dos últimos N segundos do buffer
- Consumo RAM estimado: 15s/1080p ≈ 70MB · 30s/4K ≈ 560MB → pool reutilizável para minimizar GC
- Visual: pill top-right `Raro Replay 15s` com dot vermelho pulsante quando ativo + buffer bar fill 15s loop

### M03 — Voz (wake word `"Raro"`)
- Detecção on-device via native bridge (`com.rarocamera/voice`)
- Comando único: dizer `"Raro"` inicia OU encerra gravação (toggle)
- Modo ON (default em Settings → Controle de Gravação → "Voz ativa")
- iOS: reinício automático a cada ~1min (limite SFSpeechRecognizer)
- Privacy manifest: declarado uso de speech, processamento local

### M04 — Controle por volume (modo "Volume OFF")
- Captura de eventos via native bridge (`com.rarocamera/volume`)
- `Volume +` → inicia gravação · `Volume −` → finaliza
- Fones BT compatíveis (AirPods, etc.) que reportam botões como volume → modal M03 ao detectar
- iOS: observer em `AVAudioSession.outputVolume` (workaround), restaura volume ao valor anterior para não alterar áudio do dispositivo
- Android: `dispatchKeyEvent` em `KEYCODE_VOLUME_UP`/`DOWN` + `MediaSession`

### M05 — Galeria e compartilhamento
- Salvamento automático na galeria do sistema (DCIM/Raro Camera no Android, Photos no iOS)
- Listagem cronológica, filtros: Todos / Hoje / Esta semana / Raro Replay (tag de origem)
- Preview com player nativo + scrubber + info (size/duração/codec)
- Share via OS Share Sheet (`share_plus`)
- Delete (com confirmação)
- **Gate de assinatura:** salvar vídeo na galeria exige assinatura ativa. Sem assinatura → popup M01 ao tentar parar gravação

### M06 — Assinatura e paywall
- Modelo: assinatura recorrente (Mensal R$ 9,90/mês + Anual R$ 89,90/ano)
- Free trial: **30 dias** (ambos os SKUs, configurado RevenueCat)
- Bloqueio: salvar vídeo requer entitlement `premium` ativo
- Restaurar compras (botão no paywall)
- Métodos: Apple Pay (StoreKit) / Google Play Billing — ambos via RevenueCat

### M07 — Lock mode
- Estado contínuo durante gravação que escurece tela (brilho mínimo)
- Mostra REC dot + timer mirror
- Double-tap → volta para P05
- Reduz drenagem de bateria em gravações longas

### M08 — Sistema, i18n e segurança
- Permissões nativas: câmera + microfone (apenas estas duas no protótipo)
- i18n: pt-BR (default), en, es — seletor manual em Settings com flags SVG
- Onboarding Xiaomi automático em MIUI + botão manual em Settings
- Firebase Analytics: eventos de uso (recording_started, recording_ended, plan_selected, etc.)
- Firebase Crashlytics: stacktraces simbolicados, sem PII

### Itens explicitamente FORA do escopo v1.0

| Item | Motivo |
|---|---|
| Tradução automática / legendas em tempo real | Briefing 5.6 + protótipo tem código não-navegável; custo recorrente incompatível |
| Controle Bluetooth customizado (pareamento próprio) | Briefing 5.6; iOS restringe captura de hardware externo. Volume buttons cobrem o caso (M04) |
| Modo de economia de bateria por fabricante | Briefing 5.6; substituído por Lock mode (M07) |
| Hub Dev em release | Apenas em build debug |
| Tela Wordmark | Easter egg do protótipo, não vai pro app |

---

## 7. Compatibilidade

| Plataforma | Mínimo |
|---|---|
| iOS | **15.0+** (iPhone 6s/7/8/SE 1ª geração NÃO suportados — ADR-0014, requisito SPM moderno) |
| Android | **API 24+** (Android 7.0+) |
| Xiaomi/MIUI | MIUI 12+ ou HyperOS (com configuração manual via M02) |

Bundle ID / Application ID: `com.rarocamera`.

---

## 8. Padrões de código

### 8.1 Dart / Flutter
- **Riverpod 3 com codegen:** `@riverpod` annotation + `part '<file>.g.dart'`. Não usar `Provider/ChangeNotifier` legados.
- **Snake_case** em filenames Dart (`record_button.dart`, `camera_controller.dart`).
- **Strict lints** em `analysis_options.yaml`: include `package:flutter_lints/flutter.yaml` + `riverpod_lint` + `custom_lint`. Habilitar `strict-casts`, `strict-inference`, `require_trailing_commas`, `prefer_const_constructors`, `avoid_relative_lib_imports`.
- **Sem comentários** em production code (Karpathy Surgical Changes). Nomes explicam WHAT; ADRs/docs explicam WHY.
- **Feature folder layout:** `lib/features/<feature>/{application,data,domain,presentation}/`.
- **Imports absolutos** via `package:raro_mobile/...`.

### 8.2 Native (Swift + Kotlin)
- Swift: SwiftLint com `.swiftlint.yml` padrão, line length 120
- Kotlin: ktlint default
- Method Channels: nome com namespace `com.rarocamera/<feature>`
- Contratos JSON-serializáveis documentados em `apps/mobile/lib/core/native_bridges/<bridge>_contract.md` antes da implementação (Fase 5 spec por bridge)

### 8.3 Commits — Conventional Commits 1.0.0
- Format: `<type>(<scope>): <description>`
- Types: `feat`, `fix`, `refactor`, `docs`, `style`, `test`, `chore`, `perf`, `build`, `ci`
- Scope-enum (derivado das features): `camera`, `replay`, `voice`, `volume`, `lock`, `gallery`, `preview`, `subscription`, `paywall`, `checkout`, `settings`, `xiaomi`, `i18n`, `onboarding`, `permissions`, `theme`, `bridge`, `deps`, `ci`, `docs`
- Lowercase subject, ≤72 chars, sem ponto final
- One logical change per commit
- Hooks enforced via lefthook + commitlint. **Nunca** `--no-verify`.

---

## 9. ADRs previstos (serão criados na Fase 3)

| # | Título | Origem |
|---|---|---|
| 0001 | Stack inicial completa | este Blueprint |
| 0002 | Native bridge custom em vez de plugin `camera` oficial | Briefing 6.2 |
| 0003 | Replay Buffer 100% nativo (sem plugin) | Briefing 6.2 |
| 0004 | Client-only (sem backend próprio) | Briefing 6.5 |
| 0005 | Riverpod 3 + codegen como state management | Briefing 6.1 |
| 0006 | Conventional Commits + lefthook + commitlint | este Blueprint |
| 0007 | Lock mode substituindo perfil de economia de bateria por fabricante | Briefing 5.6 |
| 0008 | Itens descartados de escopo (Bluetooth custom, tradução automática, economia por fabricante) | Briefing 5.6 |
| 0009 | Wake word `"Raro"` (não "OkCamera") | Divergência #1 desta seção 1 |
| 0010 | Modelo de assinatura dual (mensal + anual) | Divergência #3 |
| 0011 | Controle por volume buttons como substituto de controle BT customizado | Divergência #4 |
| 0012 | Onboarding Xiaomi híbrido (automático em MIUI + manual em Settings) | Divergência #6 |
| 0013 | Pigeon + Theme Tailor + gates anti-drift | spec api-contract-shared |
| 0014 | Flutter 3.44 + SPM + iOS 15 | spec flutter-3.44-spm-migration |

---

## 10. Definition of Done (v1.0 release)

- [ ] 100% das 13 telas + 3 modais implementadas e navegáveis
- [ ] Nenhuma feature não prevista neste Blueprint adicionada
- [ ] `flutter analyze` sem warnings
- [ ] Cobertura de testes: use cases ≥ 80%, repositórios ≥ 70%, widgets críticos ≥ 60%
- [ ] Replay Buffer estável em iOS + Android (sem perda de frames, sem crashes)
- [ ] Wake word `"Raro"` com taxa de detecção > 90% em ambiente silencioso
- [ ] Lock mode reduz consumo de bateria medido em ≥ 50% vs tela acesa
- [ ] App testado em ≥ 1 device Xiaomi/MIUI real
- [ ] i18n completa em pt-BR / en / es (todas as strings no `.arb`)
- [ ] Builds release `.ipa` + `.aab` com signing correto
- [ ] App aprovado e publicado em App Store + Google Play
- [ ] ADRs 0001–0012 registrados em `docs/decisions/`
- [ ] `docs/01-PROJECT.md` até `10-CHANGELOG.md` preenchidos

---

## 11. Roadmap (3 Sprints — vigente a partir de 2026-05-29)

> Cada Sprint tem MD detalhado em `docs/superpowers/plans/sprint-N-*.md`.

### Sprint 1 — Foundation + Walking Skeleton iOS
Status: ⏳ Em execução

Cleanup:
- [x] Sprint 0: master plan v2 + 3 sprint MDs criados
- [x] Task A: memórias auditadas — 6 renomeadas (índice consertado), 33 mantidas com justificativa (meta ≤25 reinterpretada; ver sessão 0008)
- [x] Task B: CLAUDE.md aligned (§8 9 hooks, §11 cortada 29→11 por critério, §6 simplificado) + Blueprint §11 roadmap
- [ ] Task C: branch `feat/camera-native-bridge` merged em `develop` — merge **segurado** (Sprint 1.C 2026-06-01); G4 focus ring iOS validado em device (3 bugs corrigidos + tap re-arquitetado pro nativo), mas gates G1/G7 perf + Android M54 + goldens seguem abertos (Sprint 2/3). Ver spec `2026-05-28-camera-task-19-closure-design.md` §progresso

Telas (12 Walking Skeleton):
- [x] P01 Splash — logo breathe (drop-shadow) + dot loader + tagline; validado no iPhone 12 (Task D, sessão 0011)
- [x] P02 Onboarding 1 ("Grave sem tocar") — mic+halos, wake word "Raro", provider Riverpod keepAlive; validado no iPhone 12
- [x] P03 Onboarding 2 ("Nunca perca o momento") — buffer waveform viz; validado no iPhone 12
- [x] P04 Permissions (camera + mic via permission_handler, gateway port mockável) — TDD + design-fidelity PASS + **validado no iPhone 12** (Task E, sessão 0012)
- [x] P05 Camera UI shell (HUD res/fps/lens, REC mock + timer fake, buffer pill, lens switcher local) — TDD + design-fidelity + **validado no iPhone 12**: 2 fixes design-fidelity (hud lens ascii x, buffer pill active) + 3 fixes device (rec glow sutil, grad-line topo, ícone câmera). Preview é mock (UiKitView nativo só Sprint 2)
- [ ] P06 Subscription popup
- [x] P07 Settings (= `AppScreen.p06Settings`) — persistência via `SharedPreferencesAsync` (API moderna 2026, port `SettingsStore` mockável swap-able Sprint 2); entity `RecordingSettings` freezed com enums canônicos do `raro_shared`; estabilização = status fixo "SEMPRE ATIVADA" (não-editável, conforme protótipo); idioma só persiste preferência (i18n real Sprint 3); TDD + design-fidelity 13/13 PASS (Task F, sessão 0013). Device pendente p/ Task H
- [x] P08 Gallery (= `AppScreen.p07Gallery`) — grid 3-col com 6 `VideoEntity` mock; thumbnails por gradiente HSL (sem assets PNG, conforme protótipo); filtros client-side Todos/Hoje/Esta semana/Raro Replay com lógica pura testável; TDD + design-fidelity PASS (Task F, sessão 0013). Device pendente p/ Task H
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

---

> **Status:** Approved em 2026-05-25. Roadmap 3-Sprint vigente desde 2026-05-29 (ver §11) — Sprint 1 em execução.
