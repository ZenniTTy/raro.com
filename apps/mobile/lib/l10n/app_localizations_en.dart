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
  String get previewVideoTitle => 'Video';

  @override
  String get previewVideoNotFound => 'Video not found';

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
