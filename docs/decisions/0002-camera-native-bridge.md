# 0002 — Native bridge custom para câmera (em vez do plugin `camera` oficial)

- **Data:** 2026-05-25
- **Status:** Accepted
- **Decisores:** Eduardo Rodrigues, Vitor Lopes
- **Contexto:** Briefing Seção 6.2, Blueprint Seção 2.2

## Contexto

O Raro Camera precisa alternar fisicamente entre lentes 0.5× (ultra-wide) e 1× (wide). O plugin `camera` oficial do Flutter Team **não suporta alternância física entre lentes** — apenas `setZoomLevel()`, que clampa em 1.0× no iOS. Issues `flutter#91247` e `flutter#173406` abertas e sem solução em maio/2026.

## Opções consideradas

1. **Plugin `camera` oficial + workaround com pinch zoom**
   - Prós: zero código nativo, manutenção mínima.
   - Contras: não atende ao requisito do briefing (alternância física), UX inferior.
2. **`iris_camera` v1.0.5** (plugin de terceiros)
   - Prós: API Dart, resolve alternância.
   - Contras: ~5 meses de idade, baixa adoção, risco de abandono.
3. **Native bridge custom (Method Channels Dart ↔ Swift/Kotlin)**
   - Prós: controle total, performance nativa, alinhado com requisito de Replay Buffer (que também precisa de nativo).
   - Contras: mais código a manter, exige conhecimento iOS/Android.

## Decisão

**Opção 3.** O projeto já precisa de nativo para o Replay Buffer (ADR 0003), então o overhead marginal de fazer a câmera também via bridge é baixo.

Method Channel: `com.rarocamera/camera`. Contrato em [07-NATIVE-BRIDGES.md](../07-NATIVE-BRIDGES.md).

## Consequências

- **Positivas:**
  - Alternância física 0.5×/1× funciona
  - Pipeline unificado com Replay Buffer (mesmo `AVCaptureSession` / `CameraX`)
  - Sem dependência de plugin de terceiros instável
- **Negativas:**
  - Manutenção em 2 stacks nativas (Swift + Kotlin)
  - Testes exigem device físico
- **Como reverter:** se o plugin oficial passar a suportar alternância física (issues fecharem), abrir novo ADR para migração

## Referências

- Issue Flutter SDK: https://github.com/flutter/flutter/issues/91247
- [07-NATIVE-BRIDGES.md](../07-NATIVE-BRIDGES.md)
- [0003-replay-buffer-native.md](0003-replay-buffer-native.md)
