# 08-RELEASE — RARO

> Processo de release para App Store + Google Play. Todas as contas são do cliente; Elovision opera como colaboradora autorizada durante o desenvolvimento.

## Identidade nas lojas

| Campo | Valor |
|---|---|
| Nome exibido | Raro Camera |
| Bundle ID (iOS) | `com.rarocamera` |
| Application ID (Android) | `com.rarocamera` |
| Categoria | Foto e vídeo |
| Idiomas suportados | pt-BR (padrão), en, es |

## Versionamento

`MAJOR.MINOR.PATCH+BUILD` em [apps/mobile/pubspec.yaml](../apps/mobile/pubspec.yaml).

- v1.0.0 — release inicial v1.0 com todas as features do Blueprint
- Patch (1.0.x) — bugfixes
- Minor (1.x.0) — feature nova sem breaking change
- Major (x.0.0) — breaking change ou pivôt

## Builds

```bash
# iOS (.ipa)
bun run --filter '@raro/mobile' build:ios

# Android (.aab)
bun run --filter '@raro/mobile' build:android
```

> **ESTADO:** nenhuma release existe; `build:android` falha (Android não compila); signing iOS/Android e Firebase/RevenueCat pendentes — ver [PLANO-MESTRE Bloco 5](superpowers/plans/PLANO-MESTRE-finalizacao-entrega-cliente.md).

**Pré-requisitos:**
- Signing iOS: certificados + provisioning profiles do cliente em Apple Developer Portal
- Signing Android: keystore `apps/mobile/android/key.properties` + `keystore.jks` (NÃO commitar — `.gitignore`)
- Firebase: `apps/mobile/android/app/google-services.json` + `apps/mobile/ios/Runner/GoogleService-Info.plist` em nome do cliente (NÃO commitar)
- RevenueCat: API keys configuradas via env vars

## Processo

1. Bump `version` em `pubspec.yaml`
2. Atualizar [10-CHANGELOG.md](10-CHANGELOG.md) com entry datada
3. `bun run lint && bun run test` (gate)
4. Build release
5. Upload manual via Xcode (iOS) e Play Console (Android), ou via `fastlane` (a configurar)
6. Submissão para review
7. Após aprovação: publicação
8. Tag git: `git tag v1.0.0 && git push --tags`
9. Session log: registrar release em `docs/sessions/`

## Transferência ao cliente

Após quitação integral:
1. Transferir App Store Connect app para conta do cliente
2. Transferir Play Console app
3. Transferir Firebase project ownership
4. Transferir RevenueCat project
5. Transferir GitHub repo
6. Documentar em ADR final
