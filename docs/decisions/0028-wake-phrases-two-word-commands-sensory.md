# 0028 — Wake phrases de 2 palavras (`"raro gravar"` / `"raro parar"`) via Sensory, inclusive em background

- **Data:** 2026-07-17
- **Status:** Accepted
- **Decisores:** Eduardo Rodrigues, Vitor Lopes (dono do produto)
- **Estende:** ADR-0009 (wake word é `"Raro"`) — não o revoga; resolve sua "Negativa" documentada (falso-positivo médio de `"Raro"` sozinho) sem abandonar a marca
- **Relaciona:** ADR-0022 (SFSpeech contínuo, ciclo de reconhecimento), memórias `raro-competitor-sensory-voicehub-ios-sdk-gated`, `raro-pattern-sfspeech-continuous-no-recycle-per-error`, `raro-pattern-ios-wake-word-no-native-api`

## Contexto

O ADR-0009 fixou a wake word como `"Raro"` e já antecipou a fraqueza: `"Raro"` sozinho é curto, foneticamente pobre (o "R" brasileiro tem baixa energia acústica) e tem falso-positivo médio em fala comum. A via de reversão prevista ali era "novo ADR com wake word alternativa".

Dois fatos novos convergiram em 2026-07:

1. **A Sensory destravou comercialmente** (email de Jeff, 2026-07-17): taxa de licença de produção **adiada** até a comercialização do app; contrato a ser redigido. Isso reabre a wake word de **background** — antes em STANDBY porque o ONNX próprio foi reprovado (sessão 0029) e a Sensory estava gated por preço.

2. **A Sensory (e o Gemini, citado por Jeff) alertou que `"Raro"` é ruim como wake word** — curta, 2 sílabas, "R" fraco. A recomendação foi aumentar densidade fonética (3–4 sílabas, consoantes fortes) ou prefixar a marca.

Já existe, em **foreground** (SFSpeech, iOS), o padrão de **comandos de 2 palavras** `"raro gravar"` e `"raro parar"` (CLAUDE.md §2). Essas frases têm 4 sílabas e consoantes fortes (o "G" de *gravar*, o "P" de *parar*) — exatamente a densidade fonética que a crítica da Sensory pede. Ou seja, o problema apontado **já estava resolvido** pelas frases de comando; faltava formalizar e estendê-lo ao background.

## Decisão

1. **A unidade de detecção é a FRASE de 2 palavras, não a palavra `"Raro"` isolada.** Os alvos são `"raro gravar"` (inicia gravação) e `"raro parar"` (encerra gravação). `"Raro"` permanece como marca (ADR-0009 intacto), mas nunca é o alvo acústico sozinho.

2. **A Sensory detecta a frase inteira, inclusive em background** (Opção A, escolhida pelo dono 2026-07-17). Cada comando é uma **wake phrase** treinada na Sensory (2 modelos: `raro gravar`, `raro parar`). A alternativa (Sensory ouve só `"raro"` para acordar e o SFSpeech captura a ação) foi **rejeitada**: reintroduziria a fraqueza fonética de `"Raro"` sozinho justamente no cenário mais difícil (tela apagada), contra o alerta da própria Sensory.

3. **Foreground segue no SFSpeech** (iOS), sem mudança — o par SFSpeech-foreground + Sensory-background convive. O ciclo de reconhecimento contínuo do SFSpeech continua regido pelo ADR-0022 (não reciclar por erro `1110` benigno).

4. **A fonte de verdade dos comandos deve migrar para `packages/shared`.** Hoje `voice_config.dart` só declara `wakeWord = 'Raro'`; as frases `gravar`/`parar` estão implícitas no código nativo (Swift). Isso é lacuna de contrato: os alvos acústicos precisam viver em `raro_shared` (uma lista de wake phrases), consumidos por iOS/Android/Sensory, para não driftarem. **A implementação dessa migração é trabalho futuro** (não feita neste ADR — este ADR só a decide e a torna obrigatória antes do wiring da Sensory).

## Consequências

- **Positivas:** neutraliza a crítica fonética da Sensory sem trocar a marca; o comportamento de background passa a espelhar o de foreground (mesmas frases); `"Raro"` continua sendo o que o usuário associa ao app. O hook `block-forbidden-terms.sh` e o ADR-0009 seguem válidos (nada de `OkCamera`).
- **Negativas / custo:** treinar **2 modelos** na Sensory (um por frase) em vez de 1 wake word — custo de treino/manutenção maior. A prova de recall no device (gate CLAUDE.md §10) ainda é pendente: a Opção A só está *decidida*, não *provada* — precisa de log limpo de iPhone/Android com recall aceitável antes de declarar a wake word de background pronta.
- **Guarda / pendências:**
  - `voice_config.dart` precisa ganhar a lista de wake phrases antes do wiring da Sensory (decisão 4). Enquanto não migrar, os comandos seguem hardcoded no nativo — drift latente.
  - O bloqueio comercial da Sensory caiu, mas **o contrato ainda não foi assinado**; nenhuma dependência de produção na Sensory antes disso.
  - CLAUDE.md §2 e a memória `raro-competitor-sensory-voicehub-ios-sdk-gated` precisam refletir "comercial adiado, validação técnica ativa" (não mais "pendente preço").

## Alternativas consideradas

- **Trocar `"Raro"` por palavra mais longa** (`"Exclusivo"`, `"Precioso"`, `"Inovação"` — sugestões do Gemini via Jeff): rejeitado — muda a marca; decisão de produto que o dono não quis. As frases de 2 palavras já entregam a densidade fonética sem esse custo.
- **Prefixar com helper** (`"Alô Raro"`, `"Oi Raro"`): rejeitado em favor das frases de comando já existentes (`"raro gravar"`/`"raro parar"`), que além de resolver a fonética já carregam a ação — um único enunciado dispara e comanda, sem passo intermediário.
- **Opção B — Sensory acorda em `"raro"`, SFSpeech captura a ação:** rejeitado (ver Decisão 2).
