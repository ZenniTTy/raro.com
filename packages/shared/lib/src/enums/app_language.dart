enum AppLanguage {
  ptBr('pt', 'BR'),
  en('en', null),
  es('es', null);

  const AppLanguage(this.languageCode, this.countryCode);

  final String languageCode;
  final String? countryCode;

  String get tag => countryCode == null ? languageCode : '$languageCode-$countryCode';
}
