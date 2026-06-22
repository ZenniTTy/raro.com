# 06-SCREENS — RARO

> ⚠️ ESTADO REAL 2026-06-22: telas P05a (Lock mode), P11 (Termos), P12 (Privacidade) NÃO implementadas (0 arquivos Dart). Modais M02 (Xiaomi) e M03 (Bluetooth) NÃO existem. Implementadas e validadas iPhone 12: P01-P10 + modal M01. Roadmap: PLANO-MESTRE Bloco 4.3/4.4.

> Mapa de telas v1.0. Espelho de [Blueprint Seção 5](Blueprint.md). Fonte visual: [Prototipo-RARO.html](briefing/prototype/Prototipo-RARO.html).

## Telas navegáveis

| ID | Nome | Função | Transições |
|---|---|---|---|
| P01 | Splash | Logo animada + dots loader. Auto-advance 1.8s. | → P02 |
| P02 | Onboarding 1 | "Grave sem tocar" — explica wake word `"Raro"` | Avançar → P03 / Pular → P04 |
| P03 | Onboarding 2 | "Nunca perca o momento" — explica Raro Replay 15/30s | Avançar → P04 |
| P04 | Permissões | Pede câmera + microfone | Continuar → P05 |
| P05 | Câmera | Tela principal: HUD, REC, lens 0.5×/1×, buffer pill, galeria, settings | close → P04 / galeria → P07 / settings → P06 / record → recording state |
| P05a | Lock mode **[NÃO IMPLEMENTADA]** | Tela escurecida durante gravação. REC dot + timer mirror. | double-tap → P05 |
| P06 | Configurações | Resolução, FPS, Raro Replay buffer, Controle (Voz/Volume), Idioma, Ver Planos, Sobre | back → P05 / Ver Planos → P09 |
| P07 | Galeria | Grid 3 colunas com thumbs, filtros (Todos / Hoje / Esta semana / Raro Replay) | back → P05 / thumb → P08 |
| P08 | Preview | Player com scrubber, info, share/trash/info | back → P07 / share → OS sheet |
| P09 | Paywall | 2 cards de plano (Mensal + Anual "MELHOR OFERTA"), 30 dias grátis | close → P05 / Assinar → P10 |
| P10 | Checkout | Order summary + tiles Apple Pay / Google Play | back → P09 / confirmar → RevenueCat → P05 |
| P11 | Termos de Uso **[NÃO IMPLEMENTADA]** | Texto legal scrollável | back → origem |
| P12 | Política de Privacidade **[NÃO IMPLEMENTADA]** | Texto legal scrollável | back → origem |

> P11 e P12 não estão no protótipo HTML mas são referenciadas em Settings → Sobre. Conteúdo fornecido pelo cliente.

## Modais / overlays

| ID | Nome | Trigger |
|---|---|---|
| M01 | Popup Assinatura | Auto: usuário sem assinatura entra em P05 (delay 450ms) |
| M02 | Onboarding Xiaomi MIUI **[NÃO IMPLEMENTADA]** | Auto: 1ª abertura em device MIUI / Manual: Settings → Sobre |
| M03 | Controle Bluetooth conectado **[NÃO IMPLEMENTADA]** | Auto: detecção de fone BT que reporta como volume button |

## Dev-only (build debug)

| ID | Nome | Notas |
|---|---|---|
| D01 | Hub Dev | Grid de todas as telas. **Não vai pra release.** |
| D02 | Wordmark | Easter egg do protótipo. **Não implementar.** |

## Theme tokens (do protótipo)

Cores, gradientes, tipografia e componentes em [Blueprint Seção 4](Blueprint.md). Implementação em `apps/mobile/lib/core/theme/` (spec na Fase 5).
