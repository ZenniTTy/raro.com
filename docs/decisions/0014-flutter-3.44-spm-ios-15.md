# 0014 — Flutter 3.44 + Swift Package Manager + iOS 15

- **Data:** 2026-05-26
- **Status:** Accepted
- **Spec:** docs/superpowers/specs/2026-05-26-flutter-3.44-spm-migration-design.md
- **Supersedes:** parcialmente ADR-0001 (Flutter version pin original `>=3.41.0`, agora `>=3.44.0`)

## Contexto

A spec `api-contract-shared` (entregue em 2026-05-26, session 0002) deixou um gate pendente: `flutter build ios --no-codesign --debug` não compilava Swift porque CocoaPods não estava instalado no Mac de desenvolvimento. Em vez de instalar CocoaPods (caminho tradicional mas em manutenção), pesquisa moderna em 2026-05-26 (Context7 + WebSearch + pub.dev API) revelou:

1. **CocoaPods está em manutenção** — registro CDN vira **read-only em 2026-12-02** (~6 meses).
2. **Firebase parou de publicar em CocoaPods em outubro/2026**. Atualizar Firebase no futuro **exige** SPM.
3. **Flutter 3.44.0** (released 2026-05-12) torna **Swift Package Manager o default oficial** para iOS/macOS.
4. **Build iOS fica 10-20% mais rápido** com SPM, sem dependência de Ruby/gem/pod.
5. **Apple endossa** SPM nativamente.

## Decisão

Migração tríplice integrada em uma única decisão (sempre vão juntas):

1. **Flutter 3.41.9 → 3.44.x** (latest stable). Dart 3.11 → 3.12. Constraint pubspec: `flutter: ">=3.44.0"`, `sdk: ">=3.12.0 <4.0.0"`.
2. **CocoaPods → Swift Package Manager**. Habilitado via `flutter config --enable-swift-package-manager`. SPM gerencia Firebase + RevenueCat (que suportam nativamente). `permission_handler_apple`, `share_plus`, `device_info_plus` ainda dependem de CocoaPods híbrido (Flutter auto-gera Podfile mínimo só para esses — aceito como tech-debt resiliente). Removidos `Podfile`/`Podfile.lock` originais; Podfile auto-gerado fica gitignored.
3. **iOS deployment target 13.0 → 15.0**. Apple SPM requirement. Atualizado em `apps/mobile/ios/Runner.xcodeproj/project.pbxproj` (3 ocorrências de `IPHONEOS_DEPLOYMENT_TARGET = 15.0`). **`apps/mobile/ios/Flutter/AppFrameworkInfo.plist` NÃO foi modificado** — Flutter 3.44 removeu intencionalmente a key `MinimumOSVersion` do template (issue [flutter/flutter#176313](https://github.com/flutter/flutter/issues/176313)). Agora é injetada dinamicamente em build time conforme `-miphoneos-version-min` do binário compilado. Adicionar manualmente quebraria App Store upload (issue [flutter/flutter#185039](https://github.com/flutter/flutter/issues/185039)). Fonte da verdade do deployment target = `project.pbxproj`.

## Consequências

**Positivas:**
- Build iOS ~10-20% mais rápido (validado por benchmarks comunidade Flutter)
- Eliminada dependência de Ruby 2.6 do sistema (deprecated) + `gem install cocoapods`
- Onboarding novo dev iOS reduzido (CocoaPods continua necessário enquanto houver plugin não-SPM, mas via `brew install cocoapods` sem sudo)
- Preparado para atualizações Firebase pós-outubro/2026 (Firebase só publica em SPM agora)
- Alinhamento com direção oficial Apple
- Eliminado risco de CocoaPods CDN read-only em dez/2026 para Firebase e RevenueCat
- Migração SPM validada: `pod install` (Flutter auto-roda) executa em ~5s, `Adding Swift Package Manager integration` em ~225s na primeira build, depois cacheado

**Negativas:**
- Perde suporte a iPhone 6s/7/8/SE 1ª geração (presos em iOS 14.x — ~5-8% iPhones ativos globalmente, maior no BR)
- `package:flutter/material.dart` agora emite deprecation warning futuramente (Material/Cupertino vão virar packages standalone `material_ui`/`cupertino_ui`)
- Podfile híbrido auto-gerado pelo Flutter para `permission_handler_apple` (PR #1440 não merged) — aceito como tech-debt resiliente, gitignored
- Pigeon mantido em `^26.3.2` (não voltou para `^26.3.4` como esperado) — `theme_tailor 3.1.3` E `riverpod_lint 3.1.3` ainda pinam `analyzer ^9.0.0`, conflito com pigeon 26.3.3+ que exige `analyzer >=10.0.0`. Dart 3.12 não resolveu. Reabrir em spec futura quando theme_tailor + riverpod_lint atualizarem.

**Neutras:**
- Renovate/dependabot fora de escopo desta ADR.

## Alternativas consideradas

- **Ficar em Flutter 3.41 + CocoaPods full** — rejeitado. CocoaPods read-only em dez/2026 + Firebase parou de publicar lá em out/2026. Manter seria tech-debt com data de validade conhecida.
- **Wait-and-see Flutter 3.44.2+ para amadurecer** — rejeitado. Projeto está em fase inicial (MVP, ~35 commits), branch isolada, sem usuários produção. Momento ideal para upgrades de plataforma.
- **Manter iOS 14 + SPM parcial** — rejeitado. SPM moderno (Flutter 3.44 default) exige iOS 15+. Não há benefício em meio-caminho.
- **Migrar para material_ui/cupertino_ui packages agora** — rejeitado. Esses packages ainda não foram publicados oficialmente em 2026-05-26. Esperar release.
- **Trocar permission_handler por alternativa SPM-native** — rejeitado. Sem alternativa madura ainda. PR #1440 do permission_handler está em rollout — esperar merge.

## Referências

- Spec: docs/superpowers/specs/2026-05-26-flutter-3.44-spm-migration-design.md
- Plan: docs/superpowers/plans/2026-05-26-flutter-3.44-spm-migration.md
- ADR predecessor: docs/decisions/0001-stack-decisions.md (parcialmente superseded)
- Flutter 3.44.0 release notes: https://docs.flutter.dev/release/release-notes/release-notes-3.44.0
- Flutter SPM for app developers: https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers
- Firebase CocoaPods deprecation: https://firebase.google.com/docs/ios/cocoapods-deprecation
- Page transition builders reorganization: https://docs.flutter.dev/release/breaking-changes/decouple-page-transition-builders
- Material/Cupertino frozen: https://github.com/flutter/flutter/issues/184093
- RevenueCat purchases-ios-spm: https://github.com/RevenueCat/purchases-ios-spm
- permission_handler SPM PR #1440: https://github.com/Baseflow/flutter-permission-handler/pull/1440
- plus_plugins SPM issue #3152: https://github.com/fluttercommunity/plus_plugins/issues/3152
