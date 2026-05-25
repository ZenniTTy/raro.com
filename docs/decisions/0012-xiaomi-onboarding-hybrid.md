# 0012 — Onboarding Xiaomi/MIUI híbrido (automático em MIUI + manual em Settings)

- **Data:** 2026-05-25
- **Status:** Accepted
- **Decisores:** Eduardo Rodrigues, Vitor Lopes
- **Contexto:** Divergência #6 entre briefing e protótipo (Blueprint Seção 1)

## Contexto

O briefing (Seção 5.5) declara "Onboarding específico para dispositivos Xiaomi" como tela de onboarding inicial. O protótipo, por outro lado, tem o conteúdo como **modal bottom-sheet** (`xmSheet`) acessível apenas via Hub Dev — não há trigger automático no fluxo navegável.

Razão da divergência: nem briefing nem protótipo definem o trigger automático. O protótipo deixa em aberto para implementação.

## Decisão

**Híbrido com 2 vias de acesso:**

### 1. Disparo automático na 1ª abertura em MIUI

- Detecção via `device_info_plus` no boot do app
- Verifica `manufacturer == 'Xiaomi'` ou `manufacturer == 'Redmi'` ou presença de propriedade `ro.miui.ui.version.name`
- Se for MIUI **e** primeira abertura (flag em `shared_preferences`), mostra a modal M02 após `P01 → P02` (mas antes de `P04`)
- Marca flag como `shown=true` em `shared_preferences`

### 2. Acesso manual em Settings → Sobre

- Item "Configuração MIUI" em Settings → Sobre (visível só em MIUI, mas pode aparecer em build debug pra qualquer device)
- Abre a mesma modal M02
- Sem efeitos colaterais na flag

## Consequências

- **Positivas:**
  - Usuário MIUI é orientado proativamente (não fica preso no kill em background)
  - Não polui experiência de usuários iOS/Android puro
  - Acesso manual permite revisitar a instrução depois
- **Negativas:**
  - Detecção MIUI é heurística (manufacturer ou property), pode falhar em ROMs custom
  - Adiciona 1 ponto de instrumentação no fluxo de onboarding
- **Como reverter:** remover trigger automático e deixar só manual via Settings

## Conteúdo da modal

4 cards numerados (do protótipo):
1. Abra Configurações → Bateria & Performance
2. Toque em "Economia de bateria do app" → encontre RARO
3. Selecione "Sem restrições"
4. Bloqueie nas recentes (ícone de cadeado)

CTAs: "Mais tarde" / "OK, vou configurar"

## Referências

- [Blueprint Seção 1 — Divergência #6](../Blueprint.md)
- [Protótipo HTML](../briefing/prototype/Prototipo-RARO.html) — `xmSheet` (linhas 529–548)
