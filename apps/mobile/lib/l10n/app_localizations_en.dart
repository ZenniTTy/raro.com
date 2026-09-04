// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsQualitySection => 'Recording Quality';

  @override
  String get settingsControlSection => 'Recording Control';

  @override
  String get settingsLanguageSection => 'Language';

  @override
  String get settingsAboutSection => 'About';

  @override
  String get settingsResolutionLabel => 'Resolution';

  @override
  String get settingsResolutionFixedLensHint => 'fixed lens';

  @override
  String get settingsFpsStandardHint => 'Standard';

  @override
  String get settingsFpsSmoothHint => 'Smooth';

  @override
  String get settingsStabilizationTitle => 'Native stabilization';

  @override
  String get settingsStabilizationSubtitle => 'Sensor-based shake reduction';

  @override
  String get settingsStabilizationAlways => 'ALWAYS ON';

  @override
  String get settingsControlModeIntro =>
      'Choose the mode you want to record with. In ';

  @override
  String get settingsControlModeVoicePart =>
      ' mode, recording is controlled by voice. In ';

  @override
  String get settingsControlModeVolumePart =>
      ' mode, recording is controlled by the side volume buttons of your device.';

  @override
  String get settingsControlVolumeTitle => 'Volume';

  @override
  String get settingsControlVolumeSubtitle => '+ or −';

  @override
  String get settingsControlVoiceTitle => 'Voice on';

  @override
  String settingsControlVoiceSubtitle(String wakeWord) {
    return 'Say \"$wakeWord\"';
  }

  @override
  String get settingsComingSoonBadge => 'coming soon';

  @override
  String settingsTrialBanner(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Trial period · $days days left',
      one: 'Trial period · 1 day left',
    );
    return '$_temp0';
  }

  @override
  String get settingsSeePlans => 'See Plans';

  @override
  String get settingsVersionLabel => 'Version';

  @override
  String get termsOfUse => 'Terms of Use';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get replayBufferBadge => 'Rolling buffer';

  @override
  String replayBufferDescription(String wakeWord) {
    return 'Records the 15 or 30 seconds before the \"$wakeWord\" voice command or the home screen button.';
  }

  @override
  String get replayBufferDurationLabel => 'Buffer duration';

  @override
  String voiceSayToRecord(String wakeWord) {
    return 'SAY “$wakeWord” TO RECORD';
  }

  @override
  String get voicePaused => 'VOICE PAUSED';

  @override
  String get voiceEnableInSettings => 'ENABLE VOICE IN SETTINGS';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboarding1Title => 'Record without touching';

  @override
  String get onboarding1Say => 'Say ';

  @override
  String get onboarding1SayTail => ' to start or stop your recording.';

  @override
  String onboarding1Tagline(String brand) {
    return '— $brand is listening.';
  }

  @override
  String get onboarding2Title => 'Never miss the moment';

  @override
  String get onboarding2Intro => '';

  @override
  String get onboarding2SavesLast => ' automatically saves the last ';

  @override
  String get onboarding2Seconds => '15 or 30 seconds';

  @override
  String get onboarding2Middle =>
      '. Did something important happen? Just press the ';

  @override
  String get onboarding2OrSay => ' button or say: ';

  @override
  String onboarding2WakePhrase(String wakeWord) {
    return '\"$wakeWord, start recording.\"';
  }

  @override
  String get bufferVisualizationLabel => 'BUFFER · 15s';

  @override
  String get bufferVisualizationNow => 'NOW';

  @override
  String get bufferVisualizationCaption => 'The previous 15s stay saved';

  @override
  String get permissionsStep => 'STEP 1 OF 1';

  @override
  String get permissionsTitle => 'Essential permissions';

  @override
  String permissionsDescription(String brand) {
    return '$brand needs access to work fully. You can revoke it at any time.';
  }

  @override
  String get permissionsCameraTitle => 'Camera';

  @override
  String get permissionsCameraDescription =>
      'Required to record 4K video with 0.5x and 1x lenses.';

  @override
  String get permissionsMicTitle => 'Microphone';

  @override
  String permissionsMicDescription(String wakeWord) {
    return 'For video audio and to listen for the “$wakeWord” command.';
  }

  @override
  String get permissionsContinue => 'Continue';

  @override
  String get cameraRecordFailed => 'Recording failed';

  @override
  String get cameraReplayThermal => 'Replay paused: the device is overheating.';

  @override
  String get cameraReplaySaveFailed => 'Could not save the replay.';

  @override
  String get cameraLensUnavailable4k60 => 'unavailable in 4K60';

  @override
  String cameraPrerollIncluded(int seconds) {
    return 'last ${seconds}s included';
  }

  @override
  String get cameraSessionInterrupted => 'Camera interrupted. Try again.';

  @override
  String get cameraFormatUnsupported =>
      'Resolution unavailable on this device.';

  @override
  String get planPerMonth => '/month';

  @override
  String get planPerYear => '/year';

  @override
  String get galleryFilterAll => 'All';

  @override
  String get galleryFilterToday => 'Today';

  @override
  String get galleryFilterThisWeek => 'This week';

  @override
  String get checkoutAppleSubtitle =>
      'App Store · Tap to authorize with Face ID';

  @override
  String get checkoutGoogleSubtitle =>
      'Play Store · Billed to your Google account';

  @override
  String get checkoutAppleConfirmHint => 'AUTHORIZE WITH FACE ID · APP STORE';

  @override
  String get checkoutGoogleConfirmHint =>
      'AUTHORIZE WITH YOUR GOOGLE ACCOUNT · PLAY STORE';

  @override
  String get galleryTitle => 'Gallery';

  @override
  String get previewInfoSection => 'INFO';

  @override
  String get previewSizeLabel => 'SIZE';

  @override
  String get previewDurationLabel => 'DURATION';

  @override
  String get previewCodecLabel => 'CODEC';

  @override
  String get previewShare => 'Share';

  @override
  String get previewSave => 'Save';

  @override
  String get previewSaveFailed => 'Couldn\'t save the video. Try again.';

  @override
  String get previewShareFailed => 'Couldn\'t share the video.';

  @override
  String get previewVideoTitle => 'Video';

  @override
  String get previewVideoNotFound => 'Video not found';

  @override
  String get paywallTitle => 'Choose your plan';

  @override
  String paywallSubtitle(String brand, int days) {
    return 'Unlock the full potential of $brand. $days days free, cancel anytime.';
  }

  @override
  String paywallSubtitleSave(String brand, int days) {
    return 'Subscribe to save this video to your gallery. $days days free with $brand, cancel anytime.';
  }

  @override
  String paywallSubtitleShare(String brand, int days) {
    return 'Subscribe to share this video. $days days free with $brand, cancel anytime.';
  }

  @override
  String paywallMonthlyEquivalent(String price) {
    return 'R\$ $price / month';
  }

  @override
  String get paywallBestOffer => 'BEST OFFER';

  @override
  String get paywallSubscribeNow => 'Subscribe now';

  @override
  String get paywallRestorePurchases => 'Restore purchases';

  @override
  String get paywallBack => 'Back';

  @override
  String get paywallPeriodMonthly => 'monthly';

  @override
  String get paywallPeriodYearly => 'yearly';

  @override
  String paywallLegal(String period) {
    return '$period subscription with automatic renewal. Cancel anytime in your App Store settings.';
  }

  @override
  String get planPremium => 'Premium';

  @override
  String get planUnlockPotential => 'Unlock the full potential';

  @override
  String get planFeature4k => '4K 60fps recording';

  @override
  String get planFeatureBuffer => 'Extended buffer';

  @override
  String get planFeatureNoAds => 'No ads';

  @override
  String planFreeDays(int days) {
    return '$days DAYS FREE';
  }

  @override
  String get planCancelAnytime => 'Cancel anytime';

  @override
  String get planSelected => 'SELECTED';

  @override
  String get popupEyebrow => 'SUBSCRIPTION';

  @override
  String get popupTitle => 'Subscription required';

  @override
  String get popupBody1 => 'You can use the app normally, but to ';

  @override
  String get popupBodyBold => 'save videos';

  @override
  String get popupBody2 => ' you need an active subscription.';

  @override
  String get popupTrial1 => 'The subscription includes ';

  @override
  String popupTrialBold(int days) {
    return '$days days free';
  }

  @override
  String popupTrial2(int days) {
    return '. You can cancel before the $days days are over and you won\'t be charged anything.';
  }

  @override
  String get popupMaybeLater => 'Maybe later';

  @override
  String get checkoutTitle => 'Complete subscription';

  @override
  String get checkoutPaymentMethod => 'Payment method';

  @override
  String get checkoutOrderSummary => 'ORDER SUMMARY';

  @override
  String checkoutSubscription(String period) {
    return '$period subscription';
  }

  @override
  String checkoutTrialPeriod(int days) {
    return 'Trial period ($days days)';
  }

  @override
  String get checkoutAfterTrial => 'After the trial';

  @override
  String checkoutProcessedBy(String brand) {
    return 'Payment processed by the App Store or Google Play. $brand never stores your card details.';
  }

  @override
  String get checkoutSelectMethod => 'SELECT A METHOD ABOVE';

  @override
  String get checkoutConfirm => 'Confirm subscription';

  @override
  String get checkoutStoreHint => 'THE STORE OPENS THE PAYMENT SHEET';

  @override
  String get paywallPurchaseFailed =>
      'Couldn\'t complete the purchase. Try again.';

  @override
  String get paywallRestoreEmpty => 'No purchases to restore on this device.';

  @override
  String get paywallRestoreFailed => 'Couldn\'t restore purchases. Try again.';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String galleryVideoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count videos',
      one: '1 video',
      zero: 'no videos',
    );
    return '$_temp0';
  }
}
