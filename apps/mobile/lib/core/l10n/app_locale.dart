import 'dart:ui';

import 'package:raro_shared/raro_shared.dart';

Locale? localeForLanguage(AppLanguage? language) {
  if (language == null) return null;
  final country = language.countryCode;
  return country == null
      ? Locale(language.languageCode)
      : Locale(language.languageCode, country);
}

AppLanguage languageForLocale(Locale locale) {
  for (final language in AppLanguage.values) {
    if (language.languageCode == locale.languageCode) return language;
  }
  return AppLanguage.ptBr;
}
