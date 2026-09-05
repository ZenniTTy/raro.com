abstract final class LegalUrls {
  static const String privacy = 'https://rarocamera.com.br/privacidade';
  static const String terms = 'https://rarocamera.com.br/termos';
  static const String contactEmail = 'rarocan1@gmail.com';

  static String privacyForLanguage(String languageCode) {
    return switch (languageCode) {
      'en' => 'https://rarocamera.com.br/en/privacy',
      'es' => 'https://rarocamera.com.br/es/privacidad',
      _ => privacy,
    };
  }

  static String termsForLanguage(String languageCode) {
    return switch (languageCode) {
      'en' => 'https://rarocamera.com.br/en/terms',
      'es' => 'https://rarocamera.com.br/es/terminos',
      _ => terms,
    };
  }
}
