// commitlint config — Conventional Commits 1.0.0
// Scope-enum derivado das features do Blueprint v1.0 (Seção 8.3).

module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      2,
      'always',
      [
        'feat',
        'fix',
        'refactor',
        'docs',
        'style',
        'test',
        'chore',
        'perf',
        'build',
        'ci',
        'revert',
      ],
    ],
    'scope-enum': [
      2,
      'always',
      [
        // Features (matching apps/mobile/lib/features/*)
        'splash',
        'onboarding',
        'permissions',
        'camera',
        'replay',
        'voice',
        'volume',
        'lock',
        'gallery',
        'preview',
        'subscription',
        'paywall',
        'checkout',
        'settings',
        'xiaomi',
        'i18n',
        // Cross-cutting
        'theme',
        'bridge',
        'analytics',
        'shared',
        // Infra
        'deps',
        'ci',
        'docs',
        'blueprint',
        'scaffold',
        'harness',
        'spec',
      ],
    ],
    'scope-empty': [2, 'never'],
    'subject-case': [2, 'always', 'lower-case'],
    'subject-full-stop': [2, 'never', '.'],
    'header-max-length': [2, 'always', 100],
    'body-max-line-length': [0],
  },
};
