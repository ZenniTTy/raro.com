// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get settingsQualitySection => 'Calidad de grabación';

  @override
  String get settingsControlSection => 'Control de grabación';

  @override
  String get settingsLanguageSection => 'Idioma';

  @override
  String get settingsAboutSection => 'Acerca de';

  @override
  String get settingsResolutionLabel => 'Resolución';

  @override
  String get settingsResolutionFixedLensHint => 'lente fija';

  @override
  String get settingsFpsStandardHint => 'Standard';

  @override
  String get settingsFpsSmoothHint => 'Smooth';

  @override
  String get settingsStabilizationTitle => 'Estabilización nativa';

  @override
  String get settingsStabilizationSubtitle => 'Reduce el temblor con sensor';

  @override
  String get settingsStabilizationAlways => 'SIEMPRE ACTIVADA';

  @override
  String get settingsControlModeIntro =>
      'Elige el modo con el que quieres grabar. En el modo ';

  @override
  String get settingsControlModeVoicePart =>
      ' la grabación se controla por voz. En el modo ';

  @override
  String get settingsControlModeVolumePart =>
      ', la grabación se controla con los botones laterales de volumen del dispositivo.';

  @override
  String get settingsControlVolumeTitle => 'Volumen';

  @override
  String get settingsControlVolumeSubtitle => '+ o −';

  @override
  String get settingsControlVoiceTitle => 'Voz activa';

  @override
  String settingsControlVoiceSubtitle(String wakeWord) {
    return 'Di \"$wakeWord\"';
  }

  @override
  String get settingsComingSoonBadge => 'muy pronto';

  @override
  String settingsTrialBanner(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Período de prueba · quedan $days días',
      one: 'Período de prueba · queda 1 día',
    );
    return '$_temp0';
  }

  @override
  String get settingsSeePlans => 'Ver planes';

  @override
  String get settingsVersionLabel => 'Versión';

  @override
  String get termsOfUse => 'Términos de uso';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get replayBufferBadge => 'Búfer continuo';

  @override
  String replayBufferDescription(String wakeWord) {
    return 'Graba los 15 o 30 segundos previos al comando de voz \"$wakeWord\" o al botón de la pantalla principal.';
  }

  @override
  String get replayBufferDurationLabel => 'Duración del búfer';

  @override
  String voiceSayToRecord(String wakeWord) {
    return 'DI “$wakeWord” PARA GRABAR';
  }

  @override
  String get voicePaused => 'VOZ EN PAUSA';

  @override
  String get voiceEnableInSettings => 'ACTIVA LA VOZ EN AJUSTES';

  @override
  String galleryVideoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count videos',
      one: '1 video',
      zero: 'ningún video',
    );
    return '$_temp0';
  }
}
