# 0001 — Stack tecnológica inicial

- **Data:** 2026-05-25
- **Status:** Accepted
- **Decisores:** Eduardo Rodrigues (Elovision), Vitor Lopes (cliente)
- **Contexto:** Bootstrap Fase 1, Blueprint Seção 2

## Contexto

Antes do primeiro código, precisamos fixar todas as libs externas que vão sustentar o app. Sem isso, cada PR pode trazer versão diferente, drift entre devs/devices, ou bug introduzido por update inesperado.

## Decisão

Fixar as seguintes versões validadas via Context7 + pub.dev em 2026-05-25:

| Camada | Lib | Versão |
|---|---|---|
| Framework | Flutter | `>=3.41.0 <4.0.0` |
| State | flutter_riverpod | `^3.3.1` (+ riverpod_annotation `^4.0.2` + riverpod_generator `^4.0.3`) |
| Routing | go_router | `^17.2.3` |
| Subscription | purchases_flutter (RevenueCat) | `^10.1.1` |
| Firebase | firebase_core / analytics / crashlytics | `^4.9.0` / `^12.4.1` / `^5.2.2` |
| Persistência | shared_preferences / path_provider | `^2.5.5` / `^2.1.5` |
| Permissões | permission_handler | `^12.0.1` |
| Compartilhamento | share_plus | `^13.1.0` |
| Device info | device_info_plus | `^13.1.0` |
| i18n | intl | `^0.20.2` |
| Logging | logger | `^2.7.0` |
| Goldens | alchemist | `^0.14.0` |
| Mocks | mocktail | `^1.0.5` |
| Lints | flutter_lints / riverpod_lint | `^6.0.0` / `^3.1.3` |
| Codegen | build_runner | `^2.15.0` |

Monorepo: Bun `>=1.3.13`, Turborepo `^2.x`, Biome `^1.9.4`, lefthook `^1.13`, commitlint `^19.x`.

## Consequências

- **Positivas:**
  - Reprodutibilidade entre máquinas
  - Bisect determinístico
  - Atualizações são decisões deliberadas (via ADR), não silenciosas
- **Negativas:**
  - Manutenção exige re-Context7 quando atualizar
  - `pubspec.lock` commitado adiciona ruído em PRs
- **Como reverter:** novo ADR substituindo este

## Ajustes vs. Blueprint inicial

- `flutter_lints` foi documentado no Blueprint como `^7.0.0` mas a versão real publicada em 2026-05-25 é `^6.0.0` (validado via `pub.dev` API). Blueprint Seção 2.10 deve refletir essa correção em revisão futura.
- `custom_lint` foi removido — `riverpod_lint ^3.1.3` é standalone agora, usa `analysis_server_plugin` diretamente em vez de `custom_lint`.

## Referências

- [Blueprint Seção 2](../Blueprint.md)
- Context7 query histórica: `/websites/flutter_dev`, `/rrousselgit/riverpod`, `/websites/pub_dev_packages_go_router`
