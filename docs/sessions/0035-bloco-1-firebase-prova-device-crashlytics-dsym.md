# 0035 — Bloco 1: prova no device (Crashlytics recebe crash + dSYM) — GATE §10 FECHADO

- **Data:** 2026-07-14
- **Duração:** ~1h (continuação da 0034 com o iPhone 12 conectado)
- **Participantes:** Eduardo Rodrigues + Claude Code (Opus 4.8) · device: iPhone 12 físico
- **Branch:** `feat/camera-native-bridge`
- **Commits:** docs-only (esta sessão não tocou código de produção — trigger de crash foi temporário e revertido)

## Objetivo

Fechar o gate §10 do Bloco 1 que a 0034 deixou explícito: **provar no iPhone 12** que o Firebase inicializa, o Crashlytics recebe um crash real, e a telemetria conecta. "Configurei" ≠ "chegou no painel" (memória `feedback_synthetic_eval_is_not_the_gate_device_is`).

## O que foi feito

**Trigger temporário de crash (revertido, NÃO commitado):**
- Adicionado um botão vermelho "CRASH TEST" no splash gated por `--dart-define=RARO_CRASH_TEST=true` chamando `FirebaseCrashlytics.instance.crash()`; nessa build o auto-avanço do splash foi desligado (senão a tela some em 1.8s e não dá pra tocar). 1ª tentativa foi long-press escondido — falhou porque o splash avançava rápido; corrigido para botão visível + splash parado.
- Após a prova, `git checkout` do splash → estado 100% original. `analyze` limpo + 323 testes verdes + working tree limpo.

**Build/install/launch no device (terminal-first, §13):**
- `flutter build ios --profile --dart-define=RARO_CRASH_TEST=true` → `✓ Runner.app` (82MB) assinado (Apple Development `eduardo@ianelli.tech`, team `Y8772MU6JG`).
- `xcrun devicectl device install` → confirmado "App installed" + container UUID novo ANTES de testar (memória `feedback_verify_device_install_before_test`). Dois bloqueios do dono resolvidos por ele: device locked (install exige desbloqueado) e trust do perfil dev (Ajustes → Gerenciamento de Dispositivo).

**Prova Crashlytics (o gate):**
- Dono tocou o botão → app fechou → reabriu. Painel Crashlytics saiu de "App detectado. Aguardando uma falha" para **"1 falha não processada"** — a doc oficial FlutterFire confirma: crash **recebido**, retido no backend aguardando dSYM. Gate de recebimento fechado.
- **dSYM:** o aviso "Ausente (obrigatório)" UUID `A3098D9F-1505-3180-B1EF-2A666D1FFF1F`. Subi os 3 dSYMs de `build/ios/Profile-iphoneos/` via `SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/upload-symbols -gsp <plist> -p ios <dSYM>` → "Successfully uploaded", UUID do Runner bateu exatamente com o obrigatório.

**Prova Analytics:** app conectou ao projeto Firebase (o mesmo `FirebaseAnalytics.instance` que o `cameraAnalyticsListener` usa). DebugView tentado com `-FIRDebugEnabled`; aceito provar via eventos automáticos (mesmo caminho do `camera_started`) em vez de rebuildar sem o flag de crash.

## O que NÃO foi feito (e por quê)

- **`idevicesyslog` não streou** no iOS 26 (tooling libimobiledevice) — abandonei essa via; os painéis cloud (Crashlytics/Analytics) são a prova autoritativa e não precisam de log de device. `pymobiledevice3` não está instalado. `timeout` não existe no shell (por isso 2 capturas iniciais vieram vazias — falha de comando, não do app).
- **Upload automático de dSYM em release/CI** — pendência herdada pro Bloco 5 (publicação): o script do flutterfire cobre SPM (aponta pro `firebase-ios-sdk/Crashlytics/run` quando não há Pods — verificado no pbxproj, minha suposição inicial de "aponta pra Pods inexistente" estava ERRADA), mas `flutter build` de linha de comando pode não disparar a build phase. Validar no pipeline de publicação.
- **Ver a stack simbolizada** confirmada no painel — depende do reprocessamento (1-3min após o upload dos dSYMs); o recebimento já estava provado independente disso.

## Aprendizados / surpresas

- **Verificar a suposição na fonte, não afirmar.** Eu ia dizer "o script do flutterfire aponta pra Pods que não existe no SPM"; ao ler o `shellScript` do pbxproj vi que ele TEM o branch SPM (`if [ ! -d "$PODS_ROOT/FirebaseCrashlytics" ]; then usa firebase-ios-sdk/Crashlytics/run`). A causa real do dSYM não subido é o `flutter build` CLI não rodar a phase, não um caminho errado. Consultar Context7 + ler o pbxproj antes de concluir evitou registrar um fato falso.
- **"1 falha não processada" É prova de sucesso**, não erro — a doc FlutterFire diz que a exceção fica retida aguardando dSYM. Fácil ler como falha.
- **Trigger de crash: botão visível + tela parada >> gesto escondido** — long-press num splash de 1.8s é uma janela pequena demais.
- **iOS 26 + libimobiledevice syslog não colam** — não insistir; ir direto pro painel cloud.

## Próximos passos

- **[BLOCO 2 — próximo código] Monetização RevenueCat** (mock hoje; depende conta RevenueCat + produtos + IAP Key do dono).
- **[BLOCO 5 — publicação] Validar upload automático de dSYM** no pipeline de release (pendência menor herdada daqui).
- **[Sensory — ação do dono]** wake-word background segue em validação (0033), fora de código.

## Referências

- Painel: Firebase Console `raro-camera` → Crashlytics (app `rarocamera-ios`)
- Sessão anterior: [0034](0034-bloco-1-firebase-crashlytics-analytics-codigo-e-build.md) (código + build)
- Memórias aplicadas: `feedback_verify_device_install_before_test`, `raro-pattern-ios-build-verify-iphoneos-not-simulator`, `raro-pattern-crashlytics-3-handlers`, `feedback_synthetic_eval_is_not_the_gate_device_is`
- Runbook: `docs/superpowers/notes/firebase-device-crash-runbook.md`
