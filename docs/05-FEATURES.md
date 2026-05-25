# 05-FEATURES — RARO

> Mapa funcional v1.0. Cada bloco "M0X" abaixo corresponde a 1+ feature folder em `apps/mobile/lib/features/`. Detalhes técnicos em [Blueprint Seção 6](Blueprint.md) e visuais em [Prototipo-RARO.html](briefing/prototype/Prototipo-RARO.html).

## M01 — Câmera e gravação

- Captura via native bridge `com.rarocamera/camera`
- Resoluções: 720p, 1080p Full HD, 4K Ultra HD, 4K 60fps (este último gated pelo paywall)
- FPS: 30 / 60
- Lentes: 0.5× ultra-wide + 1× wide (alternância física, não zoom)
- Foco automático + tap-to-focus com focus ring animado
- Estabilização nativa sempre ativa
- Gravação contínua sem limite imposto pelo app
- Inicialização padrão: **1080p · 60fps · 1×**

## M02 — Raro Replay (Replay Buffer)

- Buffer circular em RAM via native bridge `com.rarocamera/replay_buffer`
- Duração: **15s ou 30s** (toggle no pill da câmera + chips em Settings)
- Sempre ativo durante a câmera (não há disable, só escolha de duração)
- Pré-roll ao iniciar gravação
- Consumo RAM estimado: 15s/1080p ≈ 70MB · 30s/4K ≈ 560MB → pool reutilizável

## M03 — Voz (wake word `"Raro"`)

- Detecção on-device via native bridge `com.rarocamera/voice`
- Wake word `"Raro"` toggle inicia/encerra gravação
- iOS: reinício automático a cada ~1min (limite SFSpeechRecognizer)
- Áudio nunca sai do device

## M04 — Controle por volume

- Captura de eventos via native bridge `com.rarocamera/volume`
- `Volume +` inicia · `Volume −` finaliza
- Fones BT compatíveis (AirPods etc.) que reportam botões como volume funcionam → modal "Controle conectado"
- iOS: observer em `AVAudioSession.outputVolume` (workaround), restaura volume ao valor anterior

## M05 — Galeria e compartilhamento

- Salvamento automático na galeria do sistema
- Listagem cronológica, filtros: Todos / Hoje / Esta semana / Raro Replay
- Preview com player nativo + scrubber
- Share via OS Share Sheet (`share_plus`)
- Delete com confirmação
- **Gate:** salvar requer assinatura ativa → popup M01 ao tentar parar gravação sem premium

## M06 — Assinatura e paywall

- Mensal R$ 9,90/mês + Anual R$ 89,90/ano (badge "MELHOR OFERTA")
- Free trial **30 dias** ambos SKUs
- Restaurar compras
- Apple Pay / Google Play via RevenueCat

## M07 — Lock mode

- Estado contínuo durante gravação
- Escurece tela (brilho mínimo)
- REC dot + timer mirror
- Double-tap pra voltar

## M08 — Sistema, i18n, segurança

- Permissões: câmera + microfone
- i18n: pt-BR (default), en, es
- Onboarding Xiaomi automático em MIUI + botão manual em Settings
- Firebase Analytics + Crashlytics (sem PII)

## Itens explicitamente FORA do escopo v1.0

| Item | Motivo |
|---|---|
| Tradução automática / legendas em tempo real | Custo recorrente incompatível com R$ 9,90/mês |
| Controle Bluetooth customizado | iOS restringe; volume buttons cobrem o caso |
| Modo economia de bateria por fabricante | Substituído por Lock mode |
| Hub Dev em release | Apenas em build debug |
| Tela Wordmark | Easter egg do protótipo, não vai pro app |
