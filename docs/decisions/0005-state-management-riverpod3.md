# 0005 — Riverpod 3 com codegen como state management

- **Data:** 2026-05-25
- **Status:** Accepted
- **Decisores:** Eduardo Rodrigues
- **Contexto:** Blueprint Seção 2.1

## Contexto

App tem vários estados compartilhados (assinatura ativa, configurações, estado da câmera, idioma). Precisa de solução madura, com compile-time safety, baixo boilerplate e independência de `BuildContext`.

## Opções consideradas

1. **Riverpod 3 com codegen (`@riverpod` + `*.g.dart`)**
2. **BLoC / flutter_bloc**
3. **Provider (legacy)**
4. **GetX**
5. **setState + InheritedWidget puro**

## Decisão

**Opção 1 — Riverpod 3 codegen.** Razões:

- Consenso de mercado 2026 para apps Flutter sérios
- Compile-time safety via codegen (`@riverpod` annotation)
- Sem dependência de `BuildContext`
- Boilerplate mínimo
- Manutenção ativa (Remi Rousselet) com versão 3.3.1 estável
- Lint rules dedicado (`riverpod_lint ^3.1.3`)

**Regras:**
- Todo provider via `@riverpod` annotation
- `part 'file.g.dart'` obrigatório
- Codegen via `bun --filter @raro/mobile run codegen` (alias para `dart run build_runner build --delete-conflicting-outputs`)
- Não misturar com `setState` na mesma tela

## Consequências

- **Positivas:**
  - Type-safe end-to-end
  - DI implícita
  - Testes triviais (override providers)
- **Negativas:**
  - Curva de aprendizado para devs vindos de BLoC ou Provider
  - Codegen adiciona passo de build (`build_runner`)
  - 14 packages têm versões incompatíveis com constraints (warning em `flutter pub outdated`)
- **Como reverter:** migração para BLoC exigiria reescrita de toda camada de state — alto custo

## Referências

- https://riverpod.dev
- Context7 ID: `/rrousselgit/riverpod`
- [03-CONVENTIONS.md](../03-CONVENTIONS.md)
