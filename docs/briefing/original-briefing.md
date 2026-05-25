# RARO — Briefing Original

> **Documento imutável.** Briefing raw conforme padrão Karpathy 15 práticas (immutable sources). Não editar após aprovação. Alterações de escopo geram novos documentos em `docs/decisions/` (ADRs) ou specs em `docs/superpowers/specs/`.

> **Como ler este documento:** seções marcadas com `🔵 FATO` são informações confirmadas e validadas. Seções marcadas com `🟡 TODO` exigem leitura do protótipo Claude Design para preencher antes de iniciar Fase 1. Seções marcadas com `🟠 BASELINE → VALIDAR` contêm informação preliminar que **deve ser comparada com o protótipo** para detectar divergências.

---

## 0. Metadados · 🔵 FATO

| Campo | Valor |
|---|---|
| Projeto | RARO |
| Nome do produto nas lojas | Raro Camera |
| Bundle ID / Application ID | `com.rarocamera` |
| Versão deste briefing | 1.0 |
| Data | Maio 2026 |
| Autor | Eduardo Rodrigues — Elovision Digital |
| Status | Aprovado para Fase 1 (Blueprint), pendente de leitura do protótipo |

---

## 1. Contexto comercial e contratual · 🔵 FATO

### 1.1 Partes

- **Desenvolvedor (CONTRATADO):** Elovision Digital LTDA · CNPJ 48.505.584/0001-83 · Ribeirão Preto/SP. Atua exclusivamente como prestador de serviço de desenvolvimento.
- **Proprietário do produto (CONTRATANTE):** Vitor Autorino Lopes · CPF 431.093.678-40 · Imperatriz/MA · vitor_rasta@hotmail.com.

### 1.2 Modelo de relacionamento

Contrato de prestação de serviço já assinado. Após quitação integral, todos os direitos de propriedade intelectual (código-fonte, assets, configurações, credenciais) são transferidos ao cliente. **Elovision não retém titularidade de nenhum serviço vinculado ao produto.**

### 1.3 Titularidade das contas externas

Todas as contas de serviços de terceiros são criadas e mantidas em nome do cliente:

| Serviço | Titular |
|---|---|
| Apple App Store Connect | Vitor Autorino Lopes |
| Google Play Console | Vitor Autorino Lopes |
| Firebase | Vitor Autorino Lopes |
| RevenueCat | Vitor Autorino Lopes |
| GitHub (repositório) | Vitor Autorino Lopes |

**Operação temporária:** durante o desenvolvimento e publicação inicial, a Elovision pode operar as contas como colaboradora autorizada, com transferência de propriedade prevista ao final do projeto.

### 1.4 Cláusula de alterações de escopo

O contrato estabelece (Cláusula 11) que qualquer alteração, inclusão ou supressão de funcionalidades deve ser formalizada por escrito, com revisão de prazo e valor mediante aceite mútuo. Este briefing reflete o escopo aprovado após análise técnica conjunta — qualquer adição posterior segue o mesmo trâmite.

---

## 2. Visão do produto · 🔵 FATO

### 2.1 Conceito

**Raro Camera** é um aplicativo mobile (iOS + Android) para captura profissional de vídeo com operação **hands-free**. Permite gravar sem tocar no aparelho via comando de voz, e captura retroativamente os últimos segundos antes do comando (Replay Buffer).

### 2.2 Contexto de uso

Pesca, esportes, trilhas, aventuras, trabalho de campo, registro pessoal — situações em que o usuário precisa **manter as mãos livres** durante a captura.

### 2.3 Inspiração de referência

App **Ok Camera** (Felipe Augusto de Melo, disponível na App Store v1.3). O RARO replica o conceito funcional com base técnica moderna, identidade visual própria e correção das instabilidades observadas no app de referência.

### 2.4 Diferenciação técnica em relação ao Ok Camera

- Implementação robusta do Replay Buffer em código nativo (corrigindo as instabilidades observadas no app original)
- Identidade visual própria (ver Seção 4)
- Base técnica Flutter cross-platform (vs. nativo single-platform do Ok Camera)
- Internacionalização nativa (pt-BR · en · es) desde a v1.0

---

## 3. Fonte de verdade visual e funcional · 🔵 FATO

### 3.1 Protótipo Claude Design (autoritativo)

O **protótipo navegacional completo** está hospedado na Claude Design e é a **fonte de verdade absoluta** do escopo visual e funcional:

```
https://api.anthropic.com/v1/design/h/Y4C6H3yk7zl7OzzlLQbZYg?open_file=Prototipo+RARO.html
```

Arquivo principal a ser lido: `Prototipo RARO.html`.

### 3.2 Regra de escopo (inegociável)

**Todas as funcionalidades implementadas devem corresponder exatamente às do protótipo — nem mais, nem menos.**

- Não adicionar features que não estejam no protótipo
- Não remover features que estejam no protótipo
- Não reinterpretar comportamentos visuais ou de interação — replicar fielmente
- Qualquer dúvida de comportamento ou layout: consultar o protótipo, não inferir

### 3.3 Procedimento quando o protótipo for ambíguo

1. Documentar a ambiguidade em `docs/decisions/`
2. Solicitar esclarecimento ao cliente antes de implementar
3. Não inferir comportamentos por conta própria

### 3.4 Instruções para o Claude Code antes de iniciar Fase 1

**Pré-requisito obrigatório do Blueprint:** antes de executar qualquer fase do bootstrap, o Claude Code deve:

1. Fazer fetch do protótipo no link acima
2. Ler integralmente o conteúdo de `Prototipo RARO.html`
3. **Preencher** as seções marcadas como `🟡 TODO` deste documento com a informação extraída do protótipo
4. **Comparar** as seções marcadas como `🟠 BASELINE → VALIDAR` com o protótipo e **reportar divergências** antes de prosseguir

Sem essa leitura, o briefing está incompleto e a Fase 1 não pode iniciar. Não inferir conteúdo de seções TODO por conta própria.

---

## 4. Identidade visual · 🟡 TODO

> **Pendente de leitura do protótipo.** Esta seção deve ser preenchida pelo Claude Code após ler `Prototipo RARO.html`. Não preencher por inferência.

### 4.1 Sistema de cor · TODO

> Extrair do protótipo:
> - Todas as cores usadas como CSS custom properties (`--bg-*`, `--ink-*`, `--border-*`, etc.)
> - Hexcodes exatos de cada token
> - Mapeamento de cada token ao seu uso (background principal, elevado, card, texto principal, secundário, terciário, bordas, etc.)

### 4.2 Gradient signature · TODO

> Extrair do protótipo:
> - Tipo de gradient (linear, radial, angle)
> - Cores e suas posições percentuais exatas
> - Onde o gradient é aplicado (componentes, estados, decorações)
> - Onde o gradient **não** é aplicado (regras de exceção observadas no design)

### 4.3 Tipografia · TODO

> Extrair do protótipo:
> - Famílias usadas (web fonts importadas)
> - Funções de cada família (branding, UI, dados técnicos, etc.)
> - Pesos (weights) utilizados por contexto
> - Escala tipográfica (tamanhos por hierarquia)

### 4.4 Logo · TODO

> Extrair do protótipo:
> - Descrição do logo (formato, elementos visuais)
> - Variações (com wordmark, só símbolo, monocromático)
> - Linha decorativa associada (se houver)

### 4.5 Componentes visuais · TODO

> Extrair do protótipo:
> - Estados de botões (idle, hover, pressed, disabled, loading)
> - Estilo dos cards (border, shadow, padding, radius)
> - Estilo dos inputs e selectors (toggles, sliders, chips, dropdowns)
> - Microinterações observadas (transições, animações, feedback tátil visual)
> - Indicadores de estado (gravando, ouvindo voz, processando)

### 4.6 Grid e espaçamento · TODO

> Extrair do protótipo:
> - Unidade base de espaçamento
> - Padrão de padding e margin
> - Breakpoints (se houver — embora seja mobile-first)

---

## 5. Funcionalidades · 🟠 BASELINE → VALIDAR

> **Baseline preliminar.** Esta lista reflete o escopo discutido com o cliente. O Claude Code deve **comparar item por item com o protótipo** após o fetch e:
>
> 1. Marcar como ✅ os itens confirmados presentes no protótipo
> 2. Marcar como ❌ os itens listados aqui mas **ausentes** do protótipo (e questionar antes de remover)
> 3. Listar separadamente na Seção 5.7 quaisquer **funcionalidades presentes no protótipo mas ausentes desta baseline**
>
> A regra inegociável (Seção 3.2) prevalece: o protótipo é a fonte de verdade.

### 5.1 M01 — Câmera e gravação

- Gravação em 720p, 1080p Full HD e 4K Ultra HD
- Suporte a 30 e 60 FPS (condicionado ao hardware)
- Alternância entre lentes **0.5x (ultra-wide)** e **1x (wide)** — alternância física de lente, não zoom contínuo
- Foco automático
- Foco por toque (tap-to-focus com indicador visual)
- Estabilização nativa do dispositivo
- Gravação contínua sem limite de duração imposto pelo app
- Inicialização padrão em **1080p · 60 FPS**

### 5.2 M02 — Galeria e compartilhamento

- Salvamento automático na galeria do sistema
- Localização: DCIM/Raro Camera no Android, Photos no iOS
- Listagem cronológica das gravações
- Preview pós-gravação com player nativo
- Compartilhamento via OS Share Sheet (`share_plus`)

### 5.3 M03 — Assinatura e paywall

- Modelo: assinatura recorrente mensal
- Valor: **R$ 9,90/mês**
- Free trial: **30 dias** (configurável via dashboard RevenueCat)
- Bloqueio: salvar vídeo na galeria requer assinatura ativa
- Restauração de compras (botão visível no paywall)
- Integração: Apple Billing (StoreKit 2) + Google Play Billing via RevenueCat
- Sem anúncios, sem marca d'água em vídeos

### 5.4 M04 — Captura hands-free

- **Replay Buffer:** buffer circular em RAM de 15 ou 30 segundos (configurável). Implementação native bridge custom (ver Seção 7.3).
- **Comando de voz:** wake word "OkCamera" para iniciar e encerrar gravação. Reconhecimento on-device (sem envio de áudio a servidores).
- **Lock de gravação:** modo de tela escurecida que mantém o app ativo em foreground com brilho mínimo. Double-tap para sair.
- **Execução com tela escurecida:** estado contínuo que reduz drenagem de bateria durante gravações longas.

### 5.5 M05 — Sistema e segurança

- Permissões nativas: câmera, microfone, armazenamento, galeria
- Tela de Termos de Uso
- Tela de Política de Privacidade
- Tratamento de erros com fallback UI
- Firebase Analytics para eventos de uso
- Firebase Crashlytics para relatórios de crash
- Onboarding específico para dispositivos Xiaomi (orientação sobre exceções de bateria, autostart, lock de tarefas recentes)
- Internacionalização: pt-BR, en, es
- Seletor manual de idioma em Configurações

### 5.6 Itens explicitamente FORA do escopo

Funcionalidades discutidas mas **descartadas** após análise técnica e comercial. Não devem ser adicionadas sem nova negociação de escopo (Cláusula 11). Se aparecerem no protótipo, **questionar antes de implementar**:

| Item | Motivo do descarte |
|---|---|
| Controle Bluetooth | Ausente no Ok Camera. iOS restringe captura de eventos de hardware externo. Comando de voz cobre o mesmo caso de uso. |
| Tradução automática de áudio/legendas via API externa | Custo operacional recorrente alto (USD 10–60/milhão de chars). Incompatível com modelo de assinatura única R$ 9,90/mês. |
| Modo de economia de bateria com perfis por fabricante | Exige testes em 15–20 dispositivos físicos distintos. Substituído pelo modo de tela escurecida (cobre principal fonte de drenagem). |

> **Nota:** internacionalização (i18n) da interface ESTÁ no escopo (Seção 5.5). Não confundir com tradução automática via API.

### 5.7 Funcionalidades presentes no protótipo mas ausentes desta baseline · 🟡 TODO

> **Preencher após leitura do protótipo.** Se o Claude Code identificar funcionalidades, telas, fluxos ou comportamentos presentes no protótipo que não estão listados nas Seções 5.1–5.5, listar aqui e **pausar para confirmação** antes de incluí-los no Blueprint.

### 5.8 Mapeamento de telas do protótipo · 🟡 TODO

> **Preencher após leitura do protótipo.** Listar todas as telas do protótipo com:
>
> - Identificador (P01, P02, etc.)
> - Nome da tela
> - Função/contexto
> - Componentes principais
> - Estados possíveis (loading, empty, error, success)
> - Transições para outras telas

---

## 6. Stack tecnológica decidida · 🔵 FATO

Decisões validadas via Context7 e web search em maio/2026 contra documentação oficial e análises de mercado recentes. Cada item tem justificativa explícita.

### 6.1 Core

| Categoria | Tecnologia | Justificativa |
|---|---|---|
| Framework mobile | **Flutter 3.x** (versão a ser fixada via Context7 no Blueprint) | Cross-platform, performance próxima ao nativo, base única para iOS e Android. |
| Linguagem | **Dart 3.5+** | Incluído com Flutter. |
| State management | **Riverpod 3.x com codegen** (`@riverpod` annotation + `part '*.g.dart'`) | Consenso de mercado 2026. Compile-time safety, sem dependência de BuildContext, baixo boilerplate. |
| Arquitetura | **Clean Architecture + Native Bridges (Method Channels)** | Camadas Presentation / Domain / Data + bridges nativas para Replay Buffer, comando de voz e controle físico de lentes. |
| Routing | **go_router** | Padrão moderno declarativo. Versão a ser fixada via Context7. |

### 6.2 Câmera e mídia

> **Decisão técnica crítica:** o plugin oficial `camera` do Flutter Team **não suporta alternância física entre lentes 0.5x e 1x** (issues flutter#91247 e flutter#173406, abertas e sem solução em maio/2026). Apenas zoom contínuo via `setZoomLevel()`, que clampa em 1.0x no iOS.

**Solução adotada:** captura via **native bridges custom** em vez do plugin oficial.

| Plataforma | Implementação | Responsabilidade |
|---|---|---|
| iOS | **AVFoundation** nativo (Swift) | `AVCaptureDevice.DiscoverySession` com `builtInUltraWideCamera` e `builtInWideAngleCamera`. `AVCaptureSession` + `AVAssetWriter` para o pipeline de captura e Replay Buffer. |
| Android | **CameraX** nativo (Kotlin) | `CameraSelector.Builder().addCameraFilter(...)` com filtro por `LENS_INFO_AVAILABLE_FOCAL_LENGTHS`. `MediaCodec` + `MediaMuxer` para encoding e Replay Buffer. |

**Alternativa considerada e rejeitada:** `iris_camera` v1.0.5 (pub.dev, dez/2025). Resolveria alternância de lentes via API Dart, mas tem ~5 meses de idade, baixa adoção e risco de abandono. **Rejected:** preferimos controle total via native bridge próprio, já que o projeto exige nativo para Replay Buffer de qualquer forma.

### 6.3 Reconhecimento de voz (wake word)

| Plataforma | Tecnologia |
|---|---|
| iOS | **Speech Framework** (Apple) — `SFSpeechRecognizer` configurado para reconhecimento on-device |
| Android | **SpeechRecognizer** (`android.speech`) — em API 31+ (Android 12+), `EXTRA_PREFER_OFFLINE` força on-device |

**Privacidade:** processamento exclusivamente local. Nenhum áudio enviado a servidores externos. Declarado no Privacy Manifest do iOS.

### 6.4 Assinaturas e billing

| Item | Decisão |
|---|---|
| Plataforma de gestão | **RevenueCat** (SDK `purchases_flutter` 9.x — versão a ser fixada via Context7) |
| iOS Billing | StoreKit 2 (intermediado pelo RevenueCat) |
| Android Billing | Google Play Billing (intermediado pelo RevenueCat) |
| Validação de receipts | Server-side via RevenueCat (sem backend próprio) |
| Webhooks | RevenueCat → Firebase Analytics (opcional, via webhook integration) |

### 6.5 Backend e infraestrutura

**Decisão:** **client-only.** O RARO não tem backend próprio na v1.0.

**Justificativa:** todas as integrações necessárias são gerenciadas via SDKs:
- Assinaturas → RevenueCat (servidor próprio do RevenueCat)
- Analytics → Firebase
- Reconhecimento de voz → on-device
- Captura → nativo no dispositivo
- Vídeos → permanecem no dispositivo (não há upload)

**Implicação no monorepo:** ao rodar `/bootstrap-mobile-flutter`, **omitir** `apps/api`, `packages/prisma` e Docker Compose com Postgres. Estrutura final do monorepo:

```
raro/
├── apps/
│   └── mobile/          # app Flutter
├── packages/
│   └── shared/          # tipos compartilhados (eventos, constantes, enums)
└── (sem apps/api, sem packages/prisma)
```

Esta decisão deve ser comunicada à skill no início da Fase 1 (Blueprint).

### 6.6 Analytics, crash reporting e observabilidade

| Categoria | Tecnologia |
|---|---|
| Analytics | **Firebase Analytics** (eventos de uso) |
| Crash reporting | **Firebase Crashlytics** (stacktraces simbolicados) |
| Logs estruturados | `logger` package no Flutter (output local + envio condicional ao Crashlytics em erros) |

### 6.7 Persistência local

| Categoria | Tecnologia |
|---|---|
| Preferências (key-value) | `shared_preferences` |
| Paths de sistema | `path_provider` |
| Vídeos gravados | Galeria do sistema (sem persistência interna ao app) |

### 6.8 Permissões e compartilhamento

| Categoria | Tecnologia |
|---|---|
| Permissões nativas | `permission_handler` 11.x |
| Compartilhamento | `share_plus` 10.x |

### 6.9 Internacionalização

| Categoria | Tecnologia |
|---|---|
| Framework | `flutter_localizations` (SDK oficial) + `intl` |
| Formato de arquivos | `.arb` (Application Resource Bundle) |
| Geração de classes Dart tipadas | `flutter gen-l10n` |
| Idiomas suportados na v1.0 | pt-BR (padrão), en, es |
| Detecção inicial | `Locale` do sistema |
| Override manual | Configurações → Idioma (persiste em `SharedPreferences`) |

### 6.10 Tooling e qualidade

| Categoria | Tecnologia |
|---|---|
| Package manager (monorepo) | **Bun** ≥ 1.3 (workspaces) |
| Task runner | **Turborepo** |
| Git hooks | **Lefthook** |
| Commit linting | **commitlint** com Conventional Commits |
| Code formatting | `dart format` + `biome` (para JSON/MD) |
| Static analysis | `flutter analyze` com strict lints |
| Versionamento | Git + GitHub (repositório privado em nome do cliente) |

### 6.11 Padrão de commits

Conventional Commits 1.0.0:

```
<type>(<scope>): <description>
```

Tipos permitidos: `feat`, `fix`, `refactor`, `docs`, `style`, `test`, `chore`, `perf`, `build`, `ci`.

Scopes derivados das features (`camera`, `gallery`, `subscription`, `voice`, `replay`, `lock`, `settings`, `i18n`).

---

## 7. Arquitetura técnica · 🔵 FATO

### 7.1 Camadas

```
┌────────────────────────────────────────────────────────┐
│  PRESENTATION                                          │
│  Widgets Flutter · Telas · Riverpod providers          │
│  Sem regra de negócio. Observa estado, dispara intents │
└────────────────────────────────────────────────────────┘
                          ↓
┌────────────────────────────────────────────────────────┐
│  DOMAIN                                                │
│  Entidades · Use Cases · Interfaces de repositório     │
│  Pura, sem dependência de framework. Testável isolada  │
└────────────────────────────────────────────────────────┘
                          ↓
┌────────────────────────────────────────────────────────┐
│  DATA                                                  │
│  Implementações concretas · Native Bridges · SDKs      │
│  RevenueCat, Firebase, SharedPreferences, file system  │
└────────────────────────────────────────────────────────┘
                          ↓
┌────────────────────────────────────────────────────────┐
│  NATIVE BRIDGES                                        │
│  Method Channels: Dart ↔ Swift (iOS) / Kotlin (Android)│
│  Camera, Replay Buffer, Voice wake word                │
└────────────────────────────────────────────────────────┘
```

### 7.2 Estrutura de pastas (alvo)

> Estrutura de pastas das features pode ser ajustada conforme telas reais do protótipo (ver Seção 5.8). A árvore abaixo é o esqueleto baseado nas funcionalidades baseline (Seção 5).

```
apps/mobile/
├── lib/
│   ├── core/
│   │   ├── theme/             # cores, tipografia, design tokens
│   │   ├── constants/         # constantes globais
│   │   ├── permissions/       # wrappers de permission_handler
│   │   ├── native_bridges/    # Method Channels (camera, replay, voice)
│   │   └── utils/             # funções utilitárias
│   ├── features/
│   │   ├── camera/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── gallery/
│   │   ├── subscription/
│   │   ├── voice/
│   │   ├── replay_buffer/
│   │   ├── lock_mode/
│   │   ├── settings/
│   │   └── onboarding/
│   ├── l10n/
│   │   ├── app_pt.arb
│   │   ├── app_en.arb
│   │   └── app_es.arb
│   ├── app.dart
│   ├── main.dart
│   └── main_dev.dart
├── ios/Runner/Native/
│   ├── CameraManager.swift
│   ├── ReplayBufferManager.swift
│   └── VoiceWakeWordDetector.swift
└── android/app/src/main/kotlin/com/rarocamera/
    ├── CameraManager.kt
    ├── ReplayBufferManager.kt
    └── VoiceWakeWordDetector.kt
```

### 7.3 Native Bridges — contratos críticos

**Pré-requisito da Fase 5 (Spec-Driven):** cada Method Channel terá sua própria spec antes da implementação. O briefing aqui apenas declara que existem e qual sua responsabilidade.

| Method Channel | Responsabilidade |
|---|---|
| `com.rarocamera/camera` | Discovery de lentes físicas (ultra-wide, wide), troca de lente, configuração de resolução e FPS, controles de captura |
| `com.rarocamera/replay_buffer` | Buffer circular em RAM, configuração de duração (15s/30s), comando de salvamento (concatena buffer + stream contínuo) |
| `com.rarocamera/voice` | Inicialização do reconhecimento, detecção do wake word "OkCamera", callbacks de início/encerramento |

### 7.4 Decisão crítica: Replay Buffer

**Nenhum plugin Flutter existente resolve Replay Buffer.** Pesquisa em maio/2026 não retornou nenhum pacote pronto. A implementação é **100% nativa**, em ambas as plataformas.

**iOS:** `AVCaptureSession` com `AVCaptureMovieFileOutput` em modo segmentado. Buffer mantido em `CMSampleBuffer` array circular. Salvamento via `AVAssetWriter` concatenando segmentos.

**Android:** `CameraX VideoCapture` com `FileDescriptorOutputOptions`. Buffer em `MediaCodec` com encoding H.264, frames em `ByteBuffer` circular. Concatenação via `MediaMuxer`.

**Consumo de RAM estimado:**
- 15s em 1080p: ~70 MB
- 30s em 1080p: ~140 MB
- 15s em 4K: ~280 MB
- 30s em 4K: ~560 MB

Pool de buffers reutilizável para minimizar GC pressure.

### 7.5 Restrições conhecidas de plataforma

**iOS:**
- Captura contínua em background não é permitida pela Apple para apps de terceiros
- Replay Buffer e voz operam **apenas em foreground** (a tela pode estar escurecida pelo modo lock, mas o app permanece como processo ativo)
- Speech Framework tem limite de duração por sessão (~1 minuto) — reinício automático é necessário

**Android:**
- Fabricantes com camadas customizadas (Xiaomi/MIUI, Samsung/OneUI, Oppo/ColorOS) aplicam gerenciamento agressivo de background
- App exibirá onboarding específico para Xiaomi orientando o usuário a configurar exceções

**Hardware:**
- 4K 60 FPS disponível apenas em iPhone 12+ e Android flagships
- Lente 0.5x (ultra-wide) condicionada à existência física no dispositivo (não está em todos os modelos)

---

## 8. Compatibilidade · 🔵 FATO

### 8.1 Versões mínimas

| Plataforma | Versão mínima |
|---|---|
| iOS | 14.0+ (iPhone 6s em diante) |
| Android | API 24+ (Android 7.0+) |
| Xiaomi/MIUI | MIUI 12+ ou HyperOS (com configuração manual de exceções) |

### 8.2 Idiomas (i18n)

| Código | Idioma | Status |
|---|---|---|
| `pt-BR` | Português (Brasil) | Padrão |
| `en` | English | Suportado |
| `es` | Español | Suportado |

Fallback: `pt-BR` quando o idioma do sistema não estiver disponível.

---

## 9. Publicação nas lojas · 🔵 FATO

### 9.1 Identidade nas lojas

| Campo | Valor |
|---|---|
| Nome exibido | Raro Camera |
| Bundle ID (iOS) | `com.rarocamera` |
| Application ID (Android) | `com.rarocamera` |
| Categoria | Foto e vídeo |

### 9.2 Processo

1. Builds gerados pela Elovision com signing em nome do produto (sem referência à Elovision no keystore ou certificados)
2. Upload para App Store Connect e Google Play Console (contas do cliente)
3. Submissão para review
4. Após aprovação: publicação
5. Transferência das contas e credenciais para o cliente conforme cronograma do contrato

---

## 10. Roadmap inicial sugerido (Fase 5 — Spec-Driven) · 🟠 BASELINE → VALIDAR

> **Baseline preliminar.** A ordem final das specs depende das telas e fluxos do protótipo. Comparar com Seção 5.8 após preenchida.

**Prioridade alta (validar arquitetura crítica cedo):**

1. `feat/camera-native-bridge` — discovery de lentes, captura básica, alternância 0.5x/1x. Valida o pipeline native bridge completo.
2. `feat/replay-buffer` — buffer circular em RAM. Recurso mais arriscado tecnicamente, deve ser validado cedo para evitar surpresas.
3. `feat/voice-wake-word` — detecção do "OkCamera". Outra integração nativa crítica.

**Prioridade média (features de produto):**

4. `feat/subscription-paywall` — integração RevenueCat, paywall, free trial de 30 dias.
5. `feat/gallery` — listagem, preview, compartilhamento.
6. `feat/lock-mode` — modo de tela escurecida.

**Prioridade baixa (acabamento):**

7. `feat/i18n` — internacionalização pt-BR / en / es.
8. `feat/xiaomi-onboarding` — instruções específicas para MIUI.
9. `feat/settings` — tela de configurações com seletor de idioma, resolução padrão, duração do buffer.
10. `feat/onboarding` — fluxo de primeiro uso, permissões.

---

## 11. Critérios de pronto (Definition of Done) · 🔵 FATO

Para considerar o produto pronto para release v1.0:

- [ ] 100% das funcionalidades do protótipo Claude Design implementadas (verificado contra Seção 5.8)
- [ ] Nenhuma funcionalidade adicional não prevista no protótipo
- [ ] `flutter analyze` sem warnings
- [ ] Cobertura de testes: use cases ≥ 80%, repositórios ≥ 70%, widgets críticos ≥ 60%
- [ ] Replay Buffer funcional e estável em iOS e Android (sem perda de frames, sem crashes)
- [ ] Comando de voz funcional com taxa de detecção do wake word > 90% em ambiente silencioso
- [ ] Modo lock reduz consumo de bateria mensurável vs. tela acesa em 50%+
- [ ] App testado em pelo menos 1 dispositivo Xiaomi/MIUI real
- [ ] i18n completa nos 3 idiomas (pt-BR, en, es)
- [ ] Builds release (ipa, aab) gerados com signing correto
- [ ] App aprovado e publicado em App Store e Google Play
- [ ] Documentação técnica atualizada (`docs/01-PROJECT.md` até `10-CHANGELOG.md`)
- [ ] ADRs registrados para todas as decisões arquiteturais (ver Seção 12)

---

## 12. Decisões arquiteturais que serão registradas como ADRs · 🔵 FATO

Lista de decisões que devem virar ADRs na pasta `docs/decisions/` durante a Fase 3 (Foundation):

| Decisão | ADR sugerido |
|---|---|
| Stack inicial completa | `0001-stack-decisions.md` |
| Native bridge custom em vez de plugin `camera` oficial | `0002-camera-native-bridge.md` |
| Replay Buffer 100% nativo (sem plugin) | `0003-replay-buffer-native.md` |
| Client-only (sem backend próprio) | `0004-client-only-architecture.md` |
| Riverpod 3 + codegen como state management | `0005-state-management-riverpod3.md` |
| Conventional Commits + Lefthook + commitlint | `0006-commit-conventions.md` |
| Modo lock substituindo perfil de economia de bateria por fabricante | `0007-lock-mode-vs-battery-profile.md` |
| Itens descartados de escopo (Bluetooth, tradução automática, economia por fabricante) | `0008-scope-exclusions.md` |

---

## 13. Como esta documentação evolui · 🔵 FATO

Este arquivo (`docs/briefing/original-briefing.md`) é **imutável** após aprovação. Qualquer mudança subsequente deve seguir o protocolo:

| Tipo de mudança | Onde registrar |
|---|---|
| Decisão arquitetural nova | `docs/decisions/NNNN-<nome>.md` |
| Nova feature ou alteração de feature existente | `docs/superpowers/specs/<data>-<feature>.md` |
| Mudança de versão de dependência | `docs/10-CHANGELOG.md` + commit semântico |
| Esclarecimento sobre comportamento do protótipo | `docs/decisions/` (ADR de interpretação) |
| Alteração contratual de escopo (Cláusula 11) | Novo briefing v2.0 com data e referência ao contrato aditivo |

---

## 14. Checklist de pré-condições antes de iniciar Fase 1 · 🔵 FATO

| Item | Status |
|---|---|
| Cliente aprovou escopo refinado | ✅ |
| Stack validada via Context7 e web search | ✅ |
| Protótipo finalizado e disponível na Claude Design | ✅ |
| Bundle ID e nome do app definidos | ✅ |
| Titularidade das contas alinhada | ✅ |
| Itens fora do escopo documentados | ✅ |
| **Claude Code leu o protótipo** | ⬜ pendente |
| **Seção 4 (identidade visual) preenchida a partir do protótipo** | ⬜ pendente |
| **Seção 5.7 (funcionalidades extras do protótipo) preenchida** | ⬜ pendente |
| **Seção 5.8 (mapa de telas) preenchida** | ⬜ pendente |
| **Divergências entre baseline (Seção 5.1–5.5) e protótipo reportadas** | ⬜ pendente |

**Próximo passo:** rodar `/bootstrap-mobile-flutter` no Claude Code. A skill deve, antes de qualquer fase, fazer fetch do protótipo na Claude Design e completar as seções marcadas como TODO neste documento.

---

> **Fim do briefing original.** Documento imutável. Para alterações, ver Seção 13.
