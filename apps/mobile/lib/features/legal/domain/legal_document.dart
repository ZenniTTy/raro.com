import 'package:flutter/widgets.dart';
import 'package:raro_shared/raro_shared.dart';

enum LegalDocument {
  terms,
  privacy;

  String assetPath(Locale locale) {
    final lang = switch (locale.languageCode) {
      'en' => 'en',
      'es' => 'es',
      _ => 'pt',
    };
    final file = this == LegalDocument.terms ? 'terms' : 'privacy';
    return 'assets/legal/${file}_$lang.md';
  }

  String canonicalUrl(Locale locale) {
    return this == LegalDocument.terms
        ? LegalUrls.termsForLanguage(locale.languageCode)
        : LegalUrls.privacyForLanguage(locale.languageCode);
  }
}
