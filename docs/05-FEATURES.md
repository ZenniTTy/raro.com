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

> **⚠️ ESTADO REAL 2026-06-22 (auditoria de código):** este doc descreve o ESCOPO do Blueprint. Marcações `[ESTADO: ...]` abaixo indicam o que de fato está implementado. Roadmap vigente: `docs/superpowers/plans/PLANO-MESTRE-finalizacao-entrega-cliente.md`.

## M03 — Voz (wake word `"Raro"`)

- Detecção on-device via native bridge `com.rarocamera/voice`
- Wake word `"Raro"` toggle inicia/encerra gravação **[ESTADO: o app entrega DOIS comandos "raro gravar"/"raro parar" foreground via SFSpeech (ADR-0022, validado iPhone 12); o TOGGLE único (ADR-0024) dependia de ONNX que ficou em STANDBY. iOS FOREGROUND apenas. Background = standby Sensory (ONNX reprovado, sessão 0029). Android = NÃO implementado.]**
- iOS: reinício automático com token de ciclo + ring buffer (ADR-0022/0024, sessão 0024 — NÃO reciclar por erro 1110 benigno)
- Áudio nunca sai do device

## M04 — Controle por volume

- Captura de eventos via native bridge `com.rarocamera/volume` **[ESTADO: só stub Pigeon, NÃO implementado em iOS nem Android — PLANO-MESTRE Bloco 4.5]**
- `Volume +` inicia · `Volume −` finaliza
- Fones BT compatíveis (AirPods etc.) que reportam botões como volume funcionam → modal "Controle conectado"
- iOS: observer em `AVAudioSession.outputVolume` (workaround), restaura volume ao valor anterior

## M05 — Galeria e compartilhamento

- Salvamento no **vault interno do app** (não na galeria do sistema/Photos ainda) **[ESTADO: vault REAL; salvar-na-galeria-do-sistema não feito]**
- Listagem cronológica, filtros: Todos / Hoje / Esta semana / Raro Replay **[ESTADO: REAL, lê vault]**
- Preview com player nativo + scrubber **[ESTADO: REAL]**
- Share via OS Share Sheet (`share_plus`) **[ESTADO: NÃO implementado — botão mostra "Em breve" (`_comingSoon`); share_plus 0 usos — PLANO-MESTRE Bloco 4.1]**
- Delete com confirmação **[ESTADO: lógica `vault.delete` existe mas não conectada à UI — PLANO-MESTRE 4.2]**
- **Gate:** salvar requer assinatura ativa → popup M01 ao tentar parar gravação sem premium **[ESTADO: gating não aplicado — depende de RevenueCat real, Bloco 2]**

## M06 — Assinatura e paywall

- Mensal R$ 9,90/mês + Anual R$ 89,90/ano (badge "MELHOR OFERTA")
- Free trial **30 dias** ambos SKUs
- Restaurar compras
- Apple Pay / Google Play via RevenueCat **[ESTADO: RevenueCat = MOCK TOTAL — `subscribe()` só seta bool local em SharedPreferences; `purchases_flutter` 0 usos. SKUs definidos em raro_shared mas nada na loja. PLANO-MESTRE Bloco 2]**

## M07 — Lock mode

- Estado contínuo durante gravação
- Escurece tela (brilho mínimo)
- REC dot + timer mirror
- Double-tap pra voltar **[ESTADO: tela P05a Lock mode NÃO existe — PLANO-MESTRE 4.3]**

## M08 — Sistema, i18n, segurança

- Permissões: câmera + microfone **[ESTADO: REAL no iOS]**
- i18n: pt-BR (default), en, es **[ESTADO: NÃO implementado — 0 arquivos `.arb`, tudo hardcoded PT-BR. PLANO-MESTRE 4.6]**
- Onboarding Xiaomi automático em MIUI + botão manual em Settings **[ESTADO: modal M02 não existe]**
- Firebase Analytics + Crashlytics (sem PII) **[ESTADO: Firebase NUNCA inicializado (main.dart sem initializeApp); crasharia em release. Crashlytics 0 handlers. PLANO-MESTRE Bloco 1]**

## Itens explicitamente FORA do escopo v1.0

| Item | Motivo |
|---|---|
| Tradução automática / legendas em tempo real | Custo recorrente incompatível com R$ 9,90/mês |
| Controle Bluetooth customizado | iOS restringe; volume buttons cobrem o caso |
| Modo economia de bateria por fabricante | Substituído por Lock mode |
| Hub Dev em release | Apenas em build debug |
| Tela Wordmark | Easter egg do protótipo, não vai pro app |
