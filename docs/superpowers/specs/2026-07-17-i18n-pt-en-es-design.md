# Spec — i18n PT/EN/ES (todas as telas) — Fatia 4/4 pré-APK

> Data: 2026-07-17 · Status: design aprovado pelo dono · Bloco 4.6 do PLANO-MESTRE antecipado
> Última fatia da rodada (depois de Gravação/Foco/Voz) para não conflitar com strings novas das outras fatias.

## 1. Estado atual (mapeado 2026-07-17)

- `flutter_localizations` + `intl ^0.20.2` + `generate: true` JÁ no pubspec — mas órfãos: **sem `l10n.yaml`, sem nenhum `.arb`, sem delegates/`supportedLocales` no `MaterialApp`** ([app.dart](../../../apps/mobile/lib/app.dart)).
- Seletor de idioma JÁ existe e é decorativo: `LanguageGrid` (Settings) com `AppLanguage.{ptBr,es,en}` do `raro_shared`.
- ~30 de 39 arquivos de `features/*/presentation` com strings hardcoded (todas as 11 features).

## 2. Design

1. **Infra:** `l10n.yaml` com `arb-dir: lib/l10n`, `template-arb-file: app_pt.arb`, `output-localization-file: app_localizations.dart` (chaves confirmadas via Context7/docs.flutter.dev, 2026-07-17). Arquivos: `app_pt.arb` (template, com `@` descriptions), `app_en.arb`, `app_es.arb`. ICU plural/select onde couber (ex.: segundos de buffer).
   - **A validar no plan (não confirmado pela doc nesta rodada):** `synthetic-package: false` para gerar em `lib/l10n/` navegável (memória `raro-pattern-flutter-i18n-synthetic-package-false`). Essa flag mudou de status entre versões do Flutter — o plan DEVE confirmar o comportamento na versão fixada (3.44) via `flutter gen-l10n --help` ou docs da versão antes de fixar na config. Se a flag estiver depreciada/removida na 3.44, usar o default vigente e ajustar a spec.
2. **MaterialApp:** `localizationsDelegates` (AppLocalizations + Global*) + `supportedLocales` `[pt_BR, en, es]` nos DOIS branches (harness e router).
3. **Locale = fonte única persistida:** `@riverpod` controller único (`localeControllerProvider`, NÃO autoDispose) mapeando `AppLanguage → Locale`, persistido via o mesmo mecanismo de settings existente. `MaterialApp.locale` escuta o controller. `LanguageGrid` passa a escrever nele — o seletor decorativo vira real. Default: locale do sistema se suportado, senão pt-BR.
4. **Migração:** externalizar as strings dos ~30 arquivos por feature (1 commit por feature: camera, gallery, settings, onboarding, paywall, checkout, permissions, preview, splash, voice). Chaves nomeadas por feature (`cameraRecFailed`, `paywallTrialCta`...). Strings de MARCA ("RARO", wordmark) NÃO são traduzíveis — ficam fora do .arb ou como chave sem tradução variante.
5. **Traduções EN/ES:** feitas pelo Claude na migração, marcadas para revisão do dono no PR (tabela PT→EN→ES no corpo do PR).
6. **Guard-rail:** teste `forbidden_ui_literals_test` (molde do teste de hex colors): falha se `Text('...')`/literal de UI aparecer em `features/*/presentation` fora de allowlist (marca, símbolos). Trava regressão futura.

## 3. Fora de escopo

- Tradução de docs, notificação do FGS de voz em runtime dinâmico (usa .arb normal), datas/números avançados além do que `intl` dá de graça.
- RTL, outros idiomas além dos 3 do seletor.
- Renomear chaves de analytics (eventos continuam em inglês técnico, `raro_shared`).

## 4. Erros / riscos

- Reformat em massa de 30 arquivos → conflito com fatias 1-3: mitigado por ser a ÚLTIMA fatia.
- Interpolações e plural mal migrados: teste de widget por feature crítica (paywall, camera) verificando a string renderizada em pt E en.
- `dart format` hook + codegen: rodar codegen após infra (`generate: true` gera `AppLocalizations` no build).

## 5. Validação (DoD)

1. Trocar idioma no `LanguageGrid` muda o app INTEIRO em runtime, sem restart, e persiste após kill+reopen (M54 e iPhone).
2. `grep` de literais em presentation limpo (guard-rail verde).
3. Goldens re-gerados onde a tela muda (copy é parte do golden) + diff visual aprovado.
4. `analyze` + suíte completa verdes nas 2 plataformas (build iOS compila).
5. Tabela de traduções revisada pelo dono no PR.
