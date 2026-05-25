# 0009 — Wake word é `"Raro"` (não `"OkCamera"`)

- **Data:** 2026-05-25
- **Status:** Accepted
- **Decisores:** Eduardo Rodrigues, Vitor Lopes
- **Contexto:** Divergência #1 entre briefing e protótipo (Blueprint Seção 1)

## Contexto

O briefing original (Seção 5.4) declarava wake word como `"OkCamera"`. O protótipo Claude Design, que é fonte de verdade visual e funcional pela Seção 3.2 do briefing, usa `"Raro"` em 3 lugares distintos:
- Onboarding 1: *"Diga 'Raro' para iniciar ou encerrar sua gravação"*
- Onboarding 2: *"Raro, começar a gravar"*
- Hint na câmera: *"DIGA 'RARO' PARA GRAVAR"*

## Decisão

**Wake word é `"Raro"`.** Protótipo prevalece (Seção 3.2 inegociável).

`"OkCamera"`, `"Ok Camera"` e variações **não devem aparecer** em:
- Código de produção
- Strings de UI (`.arb`)
- Constantes (`packages/shared`)
- Documentação técnica
- Mensagens de commit
- Outros ADRs

A única menção permitida é em contexto histórico/comparação (ex: "inspirado no app Ok Camera").

## Consequências

- **Positivas:**
  - Alinha com branding "Raro Camera"
  - Fonética simples e curta
  - Protótipo é fonte de verdade — consistência interna
- **Negativas:**
  - `"Raro"` tem taxa de falso positivo média em português comum (mais que `"Ok Camera"`)
  - Pode exigir ajuste de threshold de confidence no detector
- **Como reverter:** se taxa de falso positivo em produção for inaceitável, novo ADR com wake word alternativa (ex: "Hey Raro")

## Implementação

- `VoiceConfig.wakeWord = 'Raro'` em [packages/shared/lib/src/constants/voice.dart](../../packages/shared/lib/src/constants/voice.dart)
- Native bridge `com.rarocamera/voice` configura `SFSpeechRecognizer` (iOS) e `SpeechRecognizer` (Android) com este alvo
- Hard rule no [CLAUDE.md Seção 11](../../CLAUDE.md): PR que mude `wakeWord` é bloqueado

## Referências

- [Blueprint Seção 1 — Divergência #1](../Blueprint.md)
- [Protótipo HTML](../briefing/prototype/Prototipo-RARO.html) (busque por "Raro" em onboarding e camera)
