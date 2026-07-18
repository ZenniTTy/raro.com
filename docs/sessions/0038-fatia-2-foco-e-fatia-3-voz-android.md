# 0038 — Fatia 2 (tap-to-focus Android) + Fatia 3 (voz Android Vosk, provada no M54)

- **Data:** 2026-07-18
- **Duração:** ~1 dia (sessão longa: 2 fatias, 4 rodadas de auditoria, debug no device)
- **Participantes:** Eduardo Rodrigues + Claude Code (Opus 4.8)
- **Branches:** `feat/fatia-2-tap-focus-android` (PR #7 MERGEADO) · `feat/fatia-3-voz-android` (PR #8 ABERTO)
- **Commits:** Fatia 2 `e3a2c1a`..`e9741bf` (PR #7, merge `e6ed065`); Fatia 3 `35bc2f5`..`c11d9a4` (PR #8)

## Objetivo

Continuar o pacote pré-APK (Gravação → **Foco** → **Voz** → i18n). Fechar a Fatia 2 (tap-to-focus Android) e a Fatia 3 (voz "raro gravar/parar" no Android), cada uma com validação/inspeção entre tasks (pedido do dono: gate de boas práticas + anti-drift/anti-bug-silencioso entre cada task, loop até o objetivo).

## O que foi feito

### Fatia 2 — tap-to-focus Android (PR #7 MERGEADO)

- **Toque captado no NATIVO** (`CameraPlatformView.kt`) via `GestureDetector.onSingleTapUp` (obrigatório: com `EagerGestureRecognizer` o Flutter pai nunca recebe o tap — memória `raro-pattern-flutter-platformview-tap-must-be-native`). `previewView.meteringPointFactory.createPoint` monta o MeteringPoint; `CameraManager.focusAtMeteringPoint` roda `startFocusAndMetering`.
- **Ring de foco nativo** (`FocusRingView`) espelhando o timing das câmeras stock (entra ~130ms, hold, fade ~220ms).
- **`onFocusChanged` honesto:** reporta o `FocusMeteringResult.isFocusSuccessful` REAL (antes mentia `true` imediato), tanto no tap nativo (via `onFocusResult` global, paridade iOS) quanto no caminho Pigeon.
- **Bug de device (ring some brusco):** o log do M54 provou `animator_duration_scale=0` (animações desligadas nas opções de dev) → `ValueAnimator`/`AnimatorSet` pulam pro fim. Fix: dirigir a animação por `Choreographer` (relógio real, imune à escala). Só o log do device revelou (2 tentativas de timing antes).
- **Auditoria adversarial 3-lentes (workflow):** 7 achados brutos → 3 confirmados corrigidos (tap não emitia onFocusChanged = drift do iOS; re-taps duplicavam o driver de animação; 1º frame patológico invisível) + higiene `stop()`/`onDetachedFromWindow`. Contrato Pigeon inalterado, zero `.swift`.
- **Prova M54:** ring visível no ponto tocado + foco muda; sem crash em re-taps. 331 testes verdes.

### Fatia 3 — voz Android (PR #8 ABERTO, provada no M54)

- **ADR-0029** (validado em fonte primária, researcher): `checkRecognitionSupport`=**API 33** (não 31 — a spec dizia errado), Vosk AAR **0.3.47** (0.3.50 é tag C++), FGS `microphone` **while-in-use** (não inicia com app em background). Correções materiais na spec + memória `raro-pattern-android-speechrecognizer-checkrecognitionsupport-api33`.
- **Spike-gate (bloqueante, 1º passo):** `SpeechRecognitionProbe.kt` provou `installed=[pt-BR]` on-device no M54 (API 36) via `checkRecognitionSupport` ANTES de construir a bridge.
- **Implementação task-a-task com gate entre cada:** dep Vosk + modelo 31MB em assets + permissões FGS; `VoiceCommandParser` (paridade Swift, 9 testes); depois a bridge. Cada task: implementar → inspecionar (boas práticas/drift/anti-pattern/bug silencioso) → commitar.
- **DECISÃO DE ARQUITETURA (motor único):** o design original tinha 2 motores (SpeechRecognizer nativo foreground + Vosk background) com handoff por ciclo de vida. **3 passadas de auditoria adversarial** provaram que coordenar 2 donos do microfone por tempo é estruturalmente frágil (double-mic, `inBackground` travado, FGS async). **Decisão do dono: Vosk motor único** foreground+background, um só `AudioRecord`, zero handoff — elimina a classe inteira de bug na raiz. `ForegroundVoiceRecognizer` (nativo) removido; fica viável como otimização futura via o spike-gate. ADR-0029 atualizado.
- **Debug no device (a voz não reconhecia nem com app aberto):** método sistemático + instrumentação por fronteira. O log do M54 revelou: o mic captava (maxAmp alto), o Vosk transcrevia — mas `parse=null` sempre. Causa real: o vosk-small em reconhecimento **livre** NÃO ouve a wake word "raro" e transcreve verbos por aproximação ("parar"→"para"). **Fix (lição do iOS — o motor está bom, o rígido era o nosso código):** (1) `Recognizer` com **gramática restrita** às frases-alvo → passa a transcrever "raro gravar"/"raro parar" fielmente; (2) parser casa por **radical** (grav/par, prefixo) com wake word opcional; (3) **debounce 2000ms + `recognizer.reset()`** após match (fim da detecção repetida do partial acumulado). Memória `raro-pattern-vosk-small-needs-restricted-grammar`.
- **Prova M54 (gate §10):** log `[raro gravar]→parse=START`, `[raro parar]→parse=STOP`; **dono confirmou na tela: a câmera gravou/parou por voz.** 331 Dart + 11 parser Kotlin verdes. Instrumentação de debug removida, **nunca loga transcript bruto** (privacidade — revisão de segurança do commit também pegou isso).

## O que NÃO foi feito (e por quê)

- **Fatia 3 não mergeada** — PR #8 aberto aguardando revisão (fluxo escolhido).
- **Prova de background (app minimizado / tela apagada)** — o foreground está provado; o FGS já roda o MESMO motor Vosk, então deve funcionar igual, mas não foi exercitado fisicamente. Follow-up no PR.
- **`POST_NOTIFICATIONS` no device do dono está `granted=false`** — o fix (pedir no fluxo de permissões Dart + 3 testes) foi implementado, mas o dono não reconcedeu; a notificação fixa do FGS microphone fica invisível até conceder. Voz funciona mesmo assim (não-fatal). Follow-up.
- **Calibração fina de falso positivo** em conversa longa (debounce/gramática/radical ajustáveis) — não estressado.
- **`SpeechRecognizer` nativo** como otimização de precisão — fatia futura dedicada (com handoff event-driven bem testado, OU só-foreground).
- **Fatia 4 (i18n)** — última do pacote, não iniciada.
- **Envio do APK ao cliente** (objetivo raiz) — segue pendente até a Fatia 4.

## Aprendizados / surpresas

- **Auditoria adversarial pagou MUITO (15 achados reais em 4 passadas):** os testes verdes não pegavam nada disso — races nativas, use-after-free do Vosk, FGS crash, falhas silenciosas de estado. A 2ª passada foi a mais valiosa: revelou que o problema era de ARQUITETURA (2 motores), não de detalhe → refactor para motor único apagou a classe toda.
- **O log do device resolve o que o teste não vê — 2× nesta sessão:** o ring que sumia (`animator_duration_scale=0`) e a voz que não reconhecia (vosk-small não ouve "raro", transcreve aproximado). Lição do iOS aplicada de novo: instrumentar e ler o log, não chutar. Memória `feedback_device_debug_use_real_logs_not_assumptions`.
- **O motor estava bom, o rígido era o nosso código** (voz): não trocar o Vosk — usar a API certa (`grammar`) + afrouxar o matching. Igual à causa-raiz do SFSpeech na 0024.
- **Simplicidade venceu (motor único):** 213 linhas removidas no refactor; menos código, sem a classe de bug de handoff. A melhor prática (um dono do mic) era mais simples que a "completa" (2 motores).
- **Privacidade de voz é gate:** a revisão de segurança do commit pegou transcript bruto no log; a instrumentação de debug também precisou ser removida antes de commitar. Nunca logar fala em produção.

## Próximos passos

- Revisar + mergear PR #8 (Fatia 3).
- Prova de background da voz no M54 (app minimizado, tela apagada) + reconceder POST_NOTIFICATIONS.
- **Fatia 4 (i18n PT/EN/ES)** — última fatia; depois o APK do cliente.
- Build APK: JBR 21 do Android Studio como `JAVA_HOME`.

## Referências

- ADRs: **ADR-0029** (voz Android Vosk motor único). ADR-0028 (Sensory) referenciado.
- Specs/Plans: `docs/superpowers/specs/2026-07-17-{tap-to-focus,voz-android-speechrecognizer-vosk}-*.md`, `docs/superpowers/plans/2026-07-18-voz-android-speechrecognizer-vosk.md`
- PRs: **#7 (MERGEADO)** tap-to-focus · **#8 (ABERTO)** voz Android
- Memórias novas: `raro-pattern-android-speechrecognizer-checkrecognitionsupport-api33`, `raro-pattern-vosk-small-needs-restricted-grammar`
