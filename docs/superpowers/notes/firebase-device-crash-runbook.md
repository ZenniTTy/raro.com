# Device runbook — provar Firebase/Crashlytics/Analytics no iPhone 12 (gate §10)

Executar QUANDO o dono conectar o iPhone 12. Debug NÃO roda standalone (§13) → usar profile + devicectl.

## 0. Pré-flight
```bash
cd apps/mobile
export PATH="$PATH:$HOME/.pub-cache/bin"
xcrun devicectl list devices           # pegar o UDID do iPhone 12
```

## 1. Build profile + install (confirmar install ANTES de testar — feedback_verify_device_install_before_test)
```bash
GIT_CONFIG_COUNT=2 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all \
  GIT_CONFIG_KEY_1=protocol.file.allow GIT_CONFIG_VALUE_1=always \
  flutter build ios --profile
xcrun devicectl device install app --device <UDID> build/ios/iphoneos/Runner.app
# LER "App installed:" + container UUID novo ANTES de prosseguir
```

## 2. Analytics DebugView (evento real)
```bash
# ligar debug do Analytics no device:
xcrun devicectl device process launch --device <UDID> com.rarocamera --start-stopped
# (ou setar -FIRDebugEnabled via scheme; no profile: usar console web DebugView)
```
- Firebase Console → Analytics → DebugView → selecionar o device.
- Abrir a tela de câmera (P05) no app → deve aparecer **`camera_started`** com params lens/resolution/fps.
- Trocar de lente/resolução → `lens_switched` / `resolution_changed` etc.
- ISSO prova que o `cameraAnalyticsListener` (agora ligado na árvore) está disparando.

## 3. Crashlytics (crash real chega no painel)
- Crashlytics precisa: app abre 1x (registra) → crash → reabre (envia o relatório no próximo boot).
- Trigger temporário (NÃO commitar): adicionar um botão/gesto que chama
  `FirebaseCrashlytics.instance.crash()` OU um `throw` não-tratado, buildar, instalar.
  - `crash()` = crash nativo → prova a cadeia toda (melhor).
  - `throw` async não-tratado → prova o `PlatformDispatcher.onError` handler.
- Sequência: abrir app → acionar crash → app fecha → REABRIR app → esperar ~1-2 min →
  Firebase Console → Crashlytics → o evento aparece (com stack desofuscada por causa da
  build phase de dSYM upload que o flutterfire adicionou no pbxproj).
- Remover o trigger temporário depois. NÃO deixar no código.

## Critério de aprovação (o gate)
- [ ] `camera_started` visível no DebugView (Analytics liga)
- [ ] Crash de teste aparece no painel Crashlytics (Crashlytics liga, símbolos ok)
- Só então marcar Bloco 1.2/1.3 como "provado no device". "Configurei" ≠ "chegou no painel"
  (feedback_synthetic_eval_is_not_the_gate_device_is).

## Dependência do dono (não inferir)
- Se Crashlytics não estiver habilitado no console (raro-camera): habilitar no painel.
- A conta Firebase é do dono; qualquer falta de permissão = avisar, não contornar.
