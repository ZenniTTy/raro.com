// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get settingsQualitySection => 'Qualidade de Gravação';

  @override
  String get settingsControlSection => 'Controle de Gravação';

  @override
  String get settingsLanguageSection => 'Idioma';

  @override
  String get settingsAboutSection => 'Sobre';

  @override
  String get settingsResolutionLabel => 'Resolução';

  @override
  String get settingsResolutionFixedLensHint => 'lente fixa';

  @override
  String get settingsFpsStandardHint => 'Standard';

  @override
  String get settingsFpsSmoothHint => 'Smooth';

  @override
  String get settingsStabilizationTitle => 'Estabilização nativa';

  @override
  String get settingsStabilizationSubtitle => 'Reduz tremor com sensor';

  @override
  String get settingsStabilizationAlways => 'SEMPRE ATIVADA';

  @override
  String get settingsControlModeIntro =>
      'Escolha o modo que você deseja gravar. No modo ';

  @override
  String get settingsControlModeVoicePart =>
      ' a gravação é controlada pela voz. No modo ';

  @override
  String get settingsControlModeVolumePart =>
      ', a gravação é controlada pelos botões laterais de volume do aparelho.';

  @override
  String get settingsControlVolumeTitle => 'Volume';

  @override
  String get settingsControlVolumeSubtitle => '+ ou −';

  @override
  String get settingsControlVoiceTitle => 'Voz ativa';

  @override
  String settingsControlVoiceSubtitle(String wakeWord) {
    return 'Diga \"$wakeWord\"';
  }

  @override
  String get settingsComingSoonBadge => 'em breve';

  @override
  String settingsTrialBanner(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Período de teste · $days dias restantes',
      one: 'Período de teste · 1 dia restante',
    );
    return '$_temp0';
  }

  @override
  String get settingsSeePlans => 'Ver Planos';

  @override
  String get settingsVersionLabel => 'Versão';

  @override
  String get termsOfUse => 'Termos de Uso';

  @override
  String get privacyPolicy => 'Política de Privacidade';

  @override
  String get replayBufferBadge => 'Buffer rotativo';

  @override
  String replayBufferDescription(String wakeWord) {
    return 'Grava 15 ou 30 segundos antes do comando de voz \"$wakeWord\" ou do botão na tela inicial.';
  }

  @override
  String get replayBufferDurationLabel => 'Duração do buffer';

  @override
  String voiceSayToRecord(String wakeWord) {
    return 'DIGA “$wakeWord” PARA GRAVAR';
  }

  @override
  String get voicePaused => 'VOZ PAUSADA';

  @override
  String get voiceEnableInSettings => 'ATIVAR VOZ NAS CONFIGURAÇÕES';

  @override
  String get cameraRecordFailed => 'Falha ao gravar';

  @override
  String get cameraReplayThermal => 'Replay pausado: o aparelho está aquecido.';

  @override
  String get cameraReplaySaveFailed => 'Não foi possível salvar o replay.';

  @override
  String get cameraLensUnavailable4k60 => 'indisponível em 4K60';

  @override
  String cameraPrerollIncluded(int seconds) {
    return 'últimos ${seconds}s incluídos';
  }

  @override
  String get galleryTitle => 'Galeria';

  @override
  String get previewInfoSection => 'INFO';

  @override
  String get previewSizeLabel => 'TAMANHO';

  @override
  String get previewDurationLabel => 'DURAÇÃO';

  @override
  String get previewCodecLabel => 'CODEC';

  @override
  String get previewShare => 'Compartilhar';

  @override
  String get previewVideoTitle => 'Vídeo';

  @override
  String get previewVideoNotFound => 'Vídeo não encontrado';

  @override
  String get comingSoon => 'Em breve';

  @override
  String galleryVideoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vídeos',
      one: '1 vídeo',
      zero: 'nenhum vídeo',
    );
    return '$_temp0';
  }
}
