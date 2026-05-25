# 04-ROADMAP — RARO

> Ordem sugerida das specs da Fase 5 (Spec-Driven). Não é commitment de prazo. Ordem orientada por risco técnico.

## Prioridade alta — validar arquitetura crítica cedo

| # | Spec | Por quê | Risco |
|---|---|---|---|
| 1 | `feat/camera-native-bridge` | Pipeline native bridge completo: discovery de lentes, captura básica, alternância 0.5×/1× | 🔴 alto |
| 2 | `feat/replay-buffer` | Buffer circular em RAM. Recurso mais arriscado tecnicamente, sem plugin Flutter resolvendo | 🔴 alto |
| 3 | `feat/voice-wake-word` | Detecção on-device do `"Raro"`. Bridge crítico para hands-free | 🔴 alto |

## Prioridade média — features de produto

| # | Spec | Notas |
|---|---|---|
| 4 | `feat/volume-control` | Captura de botões físicos via native bridge + modal "Controle conectado" |
| 5 | `feat/subscription-paywall` | RevenueCat, 2 SKUs (mensal + anual), free trial 30 dias, paywall UI |
| 6 | `feat/checkout` | Tela de finalização com Apple Pay / Google Play |
| 7 | `feat/gallery` | Listagem, filtros (Todos / Hoje / Esta semana / Raro Replay), thumbs |
| 8 | `feat/preview` | Player com scrubber, info, share |
| 9 | `feat/lock-mode` | Tela escurecida com double-tap pra sair |

## Prioridade baixa — acabamento

| # | Spec |
|---|---|
| 10 | `feat/i18n` (pt-BR, en, es) |
| 11 | `feat/xiaomi-onboarding` (modal MIUI híbrida) |
| 12 | `feat/settings` (tela completa com todas configurações) |
| 13 | `feat/onboarding` (P02 + P03 + permissões P04) |
| 14 | `feat/splash` (animação de boot) |

## Trilha lateral — infra

- `chore/firebase-init` — `firebase_core` + `firebase_analytics` + `firebase_crashlytics` configurados em ambas plataformas
- `chore/revenuecat-init` — `purchases_flutter` configurado com API key, entitlement `premium`, offerings sync
- `chore/theme-design-tokens` — extrair tokens do protótipo (cores, gradients, tipografia, espaçamentos) para `lib/core/theme/`
- `chore/native-fonts` — adicionar TTFs de Space Grotesk, Inter, JetBrains Mono em `assets/fonts/`
- `chore/i18n-scaffold` — `flutter_localizations` + `intl` + arb files vazios

## Definition of Done geral (release v1.0)

Ver [Blueprint Seção 10](Blueprint.md).
