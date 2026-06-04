# 0015 — Sprint 1 Task H (smoke test fim-a-fim no iPhone 12 + closure da Sprint 1)

- **Data:** 2026-06-03
- **Duração:** ~2h30
- **Participantes:** Eduardo Rodrigues + Claude Code (Opus 4.8)
- **Branch:** `feat/camera-native-bridge`
- **Commits:** `c2fba15`, `0bb6de9` (+ commit de closure docs)

## Objetivo

Fechar a Sprint 1: validar fisicamente no iPhone 12 o fluxo completo das 12 telas do walking skeleton (smoke test fim-a-fim), aplicar fixes de device se surgirem, marcar Blueprint §11 Sprint 1 ✅ e encerrar a sessão definindo Sprint 2 Kickoff como próximo objetivo. A validação em device era o único pendente declarado em todas as telas das Tasks F/G ("Device pendente p/ Task H").

## Contexto inicial

- Tasks A–G fechadas; 12 telas ✅ no código (Blueprint §11), suíte 200/200 GREEN ao fim da 0014, branch limpa no commit `4985a74`.
- Nenhuma tela validada fisicamente desde a Task E (sessão 0012).
- Decisão pendente escalada no início: o merge `feat/camera-native-bridge` → `develop` (Task C4) era uma Task do Sprint 1, mas foi **segurada** na sessão 0010 porque os gates de câmera nativa (G1/G7 perf + Android M54 + goldens) seguem abertos.

## O que foi feito

**Decisão de merge (escalada ao usuário):** confirmado que a Task H **não** exige merge, e que mergear agora puxaria a câmera nativa com gates abertos pra `develop` (contra a decisão da 0010). Usuário decidiu **fechar a Sprint SEM merge** — walking skeleton fica funcionalmente completo na branch; merge espera Sprint 2/3. Nenhuma operação destrutiva de git (checkout develop / merge / branch -d / push --delete) foi executada.

**Pré-validação determinística (workflow multi-agent):** analyze 0 issues + Flutter 200/200 + shared 39/39 + compilação iOS confirmada (a "falha" do build simulador é a condição pré-existente `SUPPORTED_PLATFORMS = iphoneos` documentada no CLAUDE.md §13, não erro de código).

**Build + install no iPhone 12:** build profile assinado (team `Y8772MU6JG`, bundle `com.rarocamera`, 46.5MB) via terminal com os 2 git overrides do SPM. Instalado/lançado via `devicectl`. Primeiro launch exigiu o usuário **confiar no perfil de desenvolvedor** no aparelho (free Apple ID — comportamento esperado, não bug).

**Smoke test fim-a-fim (12 telas, sem crash, sem regressão na câmera nativa):**
- Bloco 1 (splash auto-1.8s → onboarding 1 "Grave sem tocar" → onboarding 2 "Nunca perca o momento") ✅
- Bloco 2 (permissions — já concedidas de install anterior, confirmado em Ajustes; câmera UI shell) ✅. **Preview preto = comportamento esperado:** a tela P05 do walking skeleton renderiza fundo `bgDeep` de propósito (verificado no código: `_Viewport` não monta `UiKitView`); o `CameraPreviewWidget` nativo existe mas só é usado no harness. Preview ao vivo é Sprint 2 (out-of-scope explícito do plano).
- Bloco 3 (REC → timer → para; Settings → mudar quality + replay → voltar) ✅
- Bloco 4 (Gallery grid + filtros; Preview com **vídeo tocando + scrubber rainbow + seek** confirmados em device) ✅
- Bloco 5 (popup M01 auto na câmera não-assinante → Paywall 2 planos → Checkout Apple Pay → Confirmar → câmera; trial countdown "30 dias" em Settings) ✅

**Fix de device (commit `c2fba15`):** usuário pegou um vão vertical grande entre o label "Resolução" e os botões em Settings. Diagnóstico: `GridView.count(childAspectRatio: 3.4)` forçava células ~48px enquanto `SettingsChip` tem altura intrínseca ~33px → ~15px de vão. Fix: trocado por 2 `Row`s com `Expanded` (mesmo padrão do bloco FPS, já fiel). design-fidelity-checker 6/6 PASS (label 11px inkDim, gap 6px simétrico, sem aspect forçado, zero regressão), 19/19 testes settings GREEN. O detalhe de 2px FPS→Estabilização (16 vs 18) foi conscientemente deixado como polish opcional pelo usuário.

**Fix de infra (commit `0bb6de9`):** o rebuild com o fix da Resolução quebrou repetidamente com `Couldn't check out revision 'd10045c'` (SPM). Causa-raiz rastreada: **dois `Package.resolved` divergentes** — o do `.xcodeproj` pinava firebase **12.13.0** (stale, commitado errado) e o do `.xcworkspace` pinava **12.14.0** (correto). O xcodebuild lia o stale do `.xcodeproj`. Fix: remover o resolved stale → xcodebuild regenerou ambos em 12.14.0. NÃO era `safe.bareRepository` (overrides confirmados ativos via `git config --get-all`) nem cache global corrompido.

**Closure:** Blueprint §11 — 6 telas Task F/G atualizadas de "Device pendente" → "Validado no iPhone 12 (Task H, sessão 0015)"; item Task H ✅ adicionado; Status do Sprint 1 → "Walking skeleton completo" com a Task C segurada documentada.

## O que NÃO foi feito (e por quê)

- **Merge `feat/camera-native-bridge` → `develop`:** segurado de propósito por decisão do usuário (gates G1/G7 perf + Android M54 + goldens abertos). Única pendência declarada do Sprint 1. Reavaliar quando os gates fecharem (Sprint 2/3).
- **Preview ao vivo da câmera (UiKitView nativo na tela P05):** out-of-scope Sprint 1; o walking skeleton usa fundo preto + controles. Sprint 2 liga o `CameraPreviewWidget` na tela.
- **Detalhe 2px FPS→Estabilização em Settings:** imperceptível, não causado pelos fixes de hoje. Polish opcional Sprint 2/3.
- **Recording/replay/wake word/volume/RevenueCat reais:** todos Sprint 2 (out-of-scope do plano).

## Aprendizados / surpresas

- **`Package.resolved` divergente entre `.xcodeproj` e `.xcworkspace` quebra o build SPM silenciosamente.** O do `.xcodeproj` estava com um pin firebase stale (12.13.0) commitado, divergente do `.xcworkspace` (12.14.0). O xcodebuild lê o do `.xcodeproj` ao resolver, e o erro `Couldn't check out revision` engana — parece `safe.bareRepository` ou cache corrompido, mas não era. Diagnóstico correto: comparar a revision dos DOIS `Package.resolved` e ver qual dep diverge. Fix: remover o stale, deixar o xcodebuild regenerar. (Vira memória.)
- **Build em `run_in_background` retornou exit 0 enganoso com `.app` velho.** Um rebuild background "completou" (exit 0) mas o log estava com erro SPM e o `.app` era de um build anterior (timestamp). Lição: sempre confirmar o `✓ Built ... .app` no log + o timestamp do `.app`, não confiar só no exit code de build iOS background.
- **Recovery DerivedData é bloqueado pelo harness (rm -rf em `~/Library`).** O `rm -rf` do DerivedData do Runner (recovery documentado da memória SPM) é bloqueado pela política do sandbox mesmo com autorização verbal; o usuário precisa rodar manualmente. Já o `rm` de arquivo dentro do projeto (Package.resolved stale) passou.
- **Preview preto não é bug — é o escopo do walking skeleton.** Confirmar no código (`_Viewport` usa `ColoredBox(bgDeep)`, não `UiKitView`) antes de tratar como regressão. Evitou um falso-positivo de "câmera quebrada".

## Próximos passos

- **Sprint 2 Kickoff** (próxima sessão): audit do `sprint-2-backend-logic-ios.md` + recording real (MP4 → vault), replay buffer 15/30s nativo, wake word "Raro" (SFSpeechRecognizer), volume button (KVO), RevenueCat sandbox (swap do port `SubscriptionStore`), vault + share, gallery persistência real. Ligar `CameraPreviewWidget` (UiKitView) na tela P05.
- Reavaliar merge `feat/camera-native-bridge` → `develop` quando gates de câmera nativa fecharem.
- Dívidas técnicas herdadas: unificar `BufferDuration` duplicado (`raro_shared` vs `camera_shell_state.dart`, dívida da 0013); detalhe 2px Settings.

## Referências

- Plan: `docs/superpowers/plans/sprint-1-foundation-walking-skeleton.md` §"Task H"
- Protótipo: `docs/briefing/prototype/Prototipo-RARO.html` (Settings/Resolução ~linha 1010-1041)
- Blueprint §11 atualizado (12 telas validadas em device + Task H ✅ + Status Sprint 1)
- Commits: `c2fba15` (fix settings Resolução), `0bb6de9` (build deps Package.resolved firebase)
- Memória nova: Package.resolved divergente xcodeproj vs xcworkspace
