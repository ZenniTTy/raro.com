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
