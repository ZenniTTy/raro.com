# 02-ARCHITECTURE — RARO

> Visão de arquitetura de alto nível. Detalhes técnicos canônicos em [Blueprint.md Seção 3](Blueprint.md).

> **ESTADO:** paridade Android é ALVO, não estado — Android não compila ainda (PLANO-MESTRE Bloco 3). A topologia simétrica iOS/Android abaixo descreve o destino, não o que roda hoje.
> **Engine de voz vigente** = SFSpeech foreground (ADR-0022); ONNX/background = standby Sensory (0029).

## Topologia

```
┌─────────────────────────────────────────────┐
│  apps/mobile (Flutter)                      │
│  ┌─────────────────────────────────────┐    │
│  │  PRESENTATION (Riverpod + go_router)│    │
│  ├─────────────────────────────────────┤    │
│  │  DOMAIN (entities, use cases)       │    │
│  ├─────────────────────────────────────┤    │
│  │  DATA (RevenueCat, Firebase, prefs) │    │
│  ├─────────────────────────────────────┤    │
│  │  NATIVE BRIDGES (Method Channels)   │    │
│  └──────┬───────────────────┬──────────┘    │
│         │                   │               │
└─────────┼───────────────────┼───────────────┘
          ▼                   ▼
    ┌──────────┐         ┌──────────┐
    │ iOS      │         │ Android  │
    │ Swift    │         │ Kotlin   │
    │ AVFound. │         │ CameraX  │
    └──────────┘         └──────────┘

         packages/shared (Dart puro)
         constantes · enums · event names
```

## Decisões críticas (com ADR)

| # | Decisão | Por quê | ADR |
|---|---|---|---|
| 1 | Native bridges em vez do plugin `camera` oficial | Plugin oficial não alterna fisicamente entre lentes 0.5× e 1× (issues abertas no Flutter SDK) | 0002 |
| 2 | Replay Buffer 100% nativo, zero plugin Flutter | Nenhum plugin Flutter resolve buffer circular em RAM com qualidade de produção | 0003 |
| 3 | Client-only (sem backend próprio) | RevenueCat + Firebase + on-device speech cobrem todas necessidades | 0004 |
| 4 | Riverpod 3 com codegen | Consenso de mercado 2026, compile-time safety, baixo boilerplate | 0005 |
| 5 | Wake word `"Raro"` (não `"OkCamera"`) | Protótipo prevalece, alinha com branding "Raro Camera" | 0009 |
| 6 | Lock mode substitui perfil de bateria por fabricante | Cobre principal fonte de drenagem sem precisar testar 15+ devices | 0007 |

## Native bridges contratados

| Method Channel | Responsabilidade |
|---|---|
| `com.rarocamera/camera` | Discovery de lentes, alternância 0.5×/1×, resolução, FPS, captura |
| `com.rarocamera/replay_buffer` | Buffer circular em RAM (15s/30s), salvamento (concat buffer + stream) |
| `com.rarocamera/voice` | Inicialização do reconhecimento, detecção wake word `"Raro"`, callbacks (engine vigente = SFSpeech foreground / ADR-0022; ONNX background = standby Sensory / 0029) |
| `com.rarocamera/volume` | Captura de eventos de botões físicos de volume (modo "Volume OFF") |

Contrato JSON-serializável é documentado em `apps/mobile/lib/core/native_bridges/<bridge>_contract.md` antes da implementação. Cada bridge tem sua própria spec na Fase 5.

## Estrutura de pastas

Ver [Blueprint Seção 3.2](Blueprint.md).

## Restrições conhecidas

- **iOS:** captura contínua em background não permitida. Replay + voz operam só em foreground (tela pode estar escurecida via lock mode).
- **iOS Speech Framework** limita sessões a ~1 min → reinício automático.
- **Android Xiaomi/MIUI:** kill agressivo em background → onboarding Xiaomi obrigatório.
- **Hardware:** 4K 60fps só em iPhone 12+ e Android flagships; lente 0.5× depende de presença física.
