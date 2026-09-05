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
  String legalCanonicalHint(String url) {
    return 'También en $url';
  }

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
  String get onboardingNext => 'Avanzar';

  @override
  String get onboardingSkip => 'Omitir';

  @override
  String get onboarding1Title => 'Graba sin tocar';

  @override
  String get onboarding1Say => 'Di ';

  @override
  String get onboarding1SayTail => ' para iniciar o detener tu grabación.';

  @override
  String onboarding1Tagline(String brand) {
    return '— $brand escucha.';
  }

  @override
  String get onboarding2Title => 'Nunca pierdas el momento';

  @override
  String get onboarding2Intro => '';

  @override
  String get onboarding2SavesLast => ' guarda automáticamente los últimos ';

  @override
  String get onboarding2Seconds => '15 o 30 segundos';

  @override
  String get onboarding2Middle =>
      '. ¿Pasó algo importante? Solo pulsa el botón ';

  @override
  String get onboarding2OrSay => ' o di: ';

  @override
  String onboarding2WakePhrase(String wakeWord) {
    return '\"$wakeWord, empezar a grabar.\"';
  }

  @override
  String get bufferVisualizationLabel => 'BÚFER · 15s';

  @override
  String get bufferVisualizationNow => 'AHORA';

  @override
  String get bufferVisualizationCaption =>
      'Los 15s anteriores quedan guardados';

  @override
  String get permissionsStep => 'PASO 1 DE 1';

  @override
  String get permissionsTitle => 'Permisos esenciales';

  @override
  String permissionsDescription(String brand) {
    return '$brand necesita acceso para funcionar plenamente. Puedes revocarlo en cualquier momento.';
  }

  @override
  String get permissionsCameraTitle => 'Cámara';

  @override
  String get permissionsCameraDescription =>
      'Necesario para grabar video en 4K con lentes 0.5x y 1x.';

  @override
  String get permissionsMicTitle => 'Micrófono';

  @override
  String permissionsMicDescription(String wakeWord) {
    return 'Para el audio del video y para escuchar el comando “$wakeWord”.';
  }

  @override
  String get permissionsContinue => 'Continuar';

  @override
  String get cameraRecordFailed => 'Error al grabar';

  @override
  String get cameraReplayThermal =>
      'Replay en pausa: el dispositivo está caliente.';

  @override
  String get cameraReplaySaveFailed => 'No se pudo guardar el replay.';

  @override
  String get cameraLensUnavailable4k60 => 'no disponible en 4K60';

  @override
  String cameraPrerollIncluded(int seconds) {
    return 'últimos ${seconds}s incluidos';
  }

  @override
  String get cameraSessionInterrupted =>
      'Cámara interrumpida. Inténtalo de nuevo.';

  @override
  String get cameraFormatUnsupported =>
      'Resolución no disponible en este dispositivo.';

  @override
  String get planPerMonth => '/mes';

  @override
  String get planPerYear => '/año';

  @override
  String get galleryFilterAll => 'Todos';

  @override
  String get galleryFilterToday => 'Hoy';

  @override
  String get galleryFilterThisWeek => 'Esta semana';

  @override
  String get checkoutAppleSubtitle =>
      'App Store · Toca para autorizar con Face ID';

  @override
  String get checkoutGoogleSubtitle =>
      'Play Store · Cargo en tu cuenta de Google';

  @override
  String get checkoutAppleConfirmHint => 'AUTORIZA CON FACE ID · APP STORE';

  @override
  String get checkoutGoogleConfirmHint =>
      'AUTORIZA CON TU CUENTA DE GOOGLE · PLAY STORE';

  @override
  String get galleryTitle => 'Galería';

  @override
  String get previewInfoSection => 'INFO';

  @override
  String get previewSizeLabel => 'TAMAÑO';

  @override
  String get previewDurationLabel => 'DURACIÓN';

  @override
  String get previewCodecLabel => 'CÓDEC';

  @override
  String get previewShare => 'Compartir';

  @override
  String get previewSave => 'Guardar';

  @override
  String get previewSaveFailed =>
      'No se pudo guardar el video. Inténtalo de nuevo.';

  @override
  String get previewShareFailed => 'No se pudo compartir el video.';

  @override
  String get previewEntitlementUnavailable =>
      'No se pudo verificar tu suscripción. Inténtalo de nuevo.';

  @override
  String get previewVideoTitle => 'Video';

  @override
  String get previewVideoNotFound => 'Video no encontrado';

  @override
  String get previewDeleteTitle => '¿Borrar este video?';

  @override
  String get previewDeleteBody =>
      'El video se quita solo de RARO. Una copia ya guardada en la app de Fotos del celular permanece.';

  @override
  String get previewDeleteConfirm => 'Borrar';

  @override
  String get previewDeleteCancel => 'Cancelar';

  @override
  String get previewDeleteFailed =>
      'No se pudo borrar el video. Inténtalo de nuevo.';

  @override
  String get previewDetailsTitle => 'Detalles';

  @override
  String get previewDetailsName => 'Nombre';

  @override
  String get previewDetailsDuration => 'Duración';

  @override
  String get previewDetailsRecordedAt => 'Fecha';

  @override
  String get previewDetailsResolution => 'Resolución';

  @override
  String get previewDetailsFps => 'FPS';

  @override
  String get previewDetailsLens => 'Lente';

  @override
  String get previewDetailsSize => 'Tamaño';

  @override
  String get previewDetailsReplay => 'Replay';

  @override
  String get previewDetailsReplayYes => 'Sí';

  @override
  String get previewDetailsReplayNo => 'No';

  @override
  String get previewDetailsUnavailable => '—';

  @override
  String get paywallTitle => 'Elige tu plan';

  @override
  String paywallSubtitle(String brand, int days) {
    return 'Desbloquea todo el potencial de $brand. $days días gratis, cancela cuando quieras.';
  }

  @override
  String paywallSubtitleSave(String brand, int days) {
    return 'Suscríbete para guardar este video en la galería. $days días gratis en $brand, cancela cuando quieras.';
  }

  @override
  String paywallSubtitleShare(String brand, int days) {
    return 'Suscríbete para compartir este video. $days días gratis en $brand, cancela cuando quieras.';
  }

  @override
  String paywallMonthlyEquivalent(String price) {
    return 'R\$ $price / mes';
  }

  @override
  String get paywallBestOffer => 'MEJOR OFERTA';

  @override
  String get paywallSubscribeNow => 'Suscribirse ahora';

  @override
  String get paywallRestorePurchases => 'Restaurar compras';

  @override
  String get paywallBack => 'Volver';

  @override
  String get paywallPeriodMonthly => 'mensual';

  @override
  String get paywallPeriodYearly => 'anual';

  @override
  String paywallLegal(String period, int days) {
    return 'Suscripción $period con renovación automática. Incluye $days días gratis. Cancela en cualquier momento en la configuración de la App Store o de Google Play. Desinstalar la app no cancela la suscripción.';
  }

  @override
  String get planPremium => 'Premium';

  @override
  String get planUnlockPotential => 'Desbloquea todo el potencial';

  @override
  String get planFeature4k => 'Grabación en 4K 60fps';

  @override
  String get planFeatureBuffer => 'Búfer extendido';

  @override
  String get planFeatureNoAds => 'Sin anuncios';

  @override
  String planFreeDays(int days) {
    return '$days DÍAS GRATIS';
  }

  @override
  String get planCancelAnytime => 'Cancela cuando quieras';

  @override
  String get planSelected => 'SELECCIONADO';

  @override
  String get popupEyebrow => 'SUSCRIPCIÓN';

  @override
  String get popupTitle => 'Suscripción necesaria';

  @override
  String get popupBody1 => 'Puedes usar la app con normalidad, pero para ';

  @override
  String get popupBodyBold => 'guardar videos';

  @override
  String get popupBody2 => ' necesitas activar la suscripción.';

  @override
  String get popupTrial1 => 'La suscripción incluye ';

  @override
  String popupTrialBold(int days) {
    return '$days días gratis';
  }

  @override
  String popupTrial2(int days) {
    return '. Puedes cancelar antes de completar los $days días y no se te cobrará nada.';
  }

  @override
  String get popupMaybeLater => 'Quizás después';

  @override
  String get checkoutTitle => 'Finalizar suscripción';

  @override
  String get checkoutPaymentMethod => 'Método de pago';

  @override
  String get checkoutOrderSummary => 'RESUMEN DEL PEDIDO';

  @override
  String checkoutSubscription(String period) {
    return 'Suscripción $period';
  }

  @override
  String checkoutTrialPeriod(int days) {
    return 'Período de prueba ($days días)';
  }

  @override
  String get checkoutAfterTrial => 'Después de la prueba';

  @override
  String checkoutProcessedBy(String brand) {
    return 'Pago procesado por la App Store o Google Play. $brand no almacena los datos de tu tarjeta.';
  }

  @override
  String get checkoutSelectMethod => 'SELECCIONA UN MÉTODO ARRIBA';

  @override
  String get checkoutConfirm => 'Confirmar suscripción';

  @override
  String get checkoutStoreHint => 'LA TIENDA ABRE LA HOJA DE PAGO';

  @override
  String get paywallPurchaseFailed =>
      'No se pudo completar la compra. Inténtalo de nuevo.';

  @override
  String get paywallRestoreEmpty =>
      'No hay compras para restaurar en este dispositivo.';

  @override
  String get paywallRestoreFailed =>
      'No se pudieron restaurar las compras. Inténtalo de nuevo.';

  @override
  String get comingSoon => 'Muy pronto';

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
