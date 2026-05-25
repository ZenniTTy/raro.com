# 0011 — Controle por botões de volume (em vez de controle Bluetooth customizado)

- **Data:** 2026-05-25
- **Status:** Accepted
- **Decisores:** Eduardo Rodrigues, Vitor Lopes
- **Contexto:** Divergência #4 entre briefing e protótipo (Blueprint Seção 1)

## Contexto

O briefing original (Seção 5.6) descartou "controle Bluetooth" como fora de escopo. O protótipo, porém, traz:
- Settings → "Controle de Gravação" com modo "Volume OFF" (botões físicos `+`/`−` controlam gravação)
- Modal `btSheet` "Controle conectado · AirPods Pro · Pareado · Pressione o botão de volume do seu dispositivo Bluetooth para iniciar e parar a gravação"

Não é o mesmo que o briefing descartou. O briefing descartou **controle BT customizado** (pareamento próprio, captura de eventos arbitrários de hardware externo). O protótipo traz **captura de eventos de botões de volume**, que é diferente — esses eventos são padronizados em ambos sistemas.

## Decisão

**Implementar captura de botões físicos de volume.** Protótipo prevalece (Seção 3.2).

- Native bridge `com.rarocamera/volume`
- Modo "Volume OFF" em Settings habilita captura
- `Volume +` → inicia gravação
- `Volume −` → finaliza gravação
- Restauração do volume ao valor anterior para não afetar áudio do device

**Fones BT compatíveis** (AirPods, headsets que reportam botões como volume) funcionam automaticamente porque o iOS/Android os trata como volume events do device. Quando detectamos esse tipo de evento via BT, disparamos modal M03 "Controle conectado".

**Não implementamos:** controle BT com pareamento próprio, captura de eventos arbitrários de gamepads ou remotes, BLE custom — esses continuam fora de escopo.

## Consequências

- **Positivas:**
  - Cobre o caso de uso de hands-free com fones BT
  - APIs nativas padronizadas (`AVAudioSession.outputVolume` no iOS, `KEYCODE_VOLUME_UP/DOWN` no Android)
  - Sem complexidade de Bluetooth pairing
- **Negativas:**
  - iOS workaround com observer em `outputVolume` é frágil em mudanças de SDK
  - Captura de volume buttons pode interferir com volume real se mal implementada
- **Como reverter:** desabilitar modo "Volume OFF" no Settings (UI esconde a opção)

## Referências

- [Blueprint Seção 1 — Divergência #4](../Blueprint.md)
- [07-NATIVE-BRIDGES.md](../07-NATIVE-BRIDGES.md) — Method Channel `com.rarocamera/volume`
