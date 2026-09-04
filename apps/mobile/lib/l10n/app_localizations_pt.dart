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
  String get onboardingNext => 'Avançar';

  @override
  String get onboardingSkip => 'Pular';

  @override
  String get onboarding1Title => 'Grave sem tocar';

  @override
  String get onboarding1Say => 'Diga ';

  @override
  String get onboarding1SayTail => ' para iniciar ou encerrar sua gravação.';

  @override
  String onboarding1Tagline(String brand) {
    return '— O $brand escuta.';
  }

  @override
  String get onboarding2Title => 'Nunca perca o momento';

  @override
  String get onboarding2Intro => 'O ';

  @override
  String get onboarding2SavesLast => ' salva automaticamente os últimos ';

  @override
  String get onboarding2Seconds => '15 ou 30 segundos';

  @override
  String get onboarding2Middle =>
      '. Aconteceu algo importante? Basta apertar o botão ';

  @override
  String get onboarding2OrSay => ' ou dizer: ';

  @override
  String onboarding2WakePhrase(String wakeWord) {
    return '\"$wakeWord, começar a gravar.\"';
  }

  @override
  String get bufferVisualizationLabel => 'BUFFER · 15s';

  @override
  String get bufferVisualizationNow => 'AGORA';

  @override
  String get bufferVisualizationCaption => 'Os 15s anteriores ficam salvos';

  @override
  String get permissionsStep => 'PASSO 1 DE 1';

  @override
  String get permissionsTitle => 'Permissões essenciais';

  @override
  String permissionsDescription(String brand) {
    return 'O $brand precisa de acesso para funcionar plenamente. Você pode revogar a qualquer momento.';
  }

  @override
  String get permissionsCameraTitle => 'Câmera';

  @override
  String get permissionsCameraDescription =>
      'Necessário para gravar vídeo em 4K com lentes 0.5x e 1x.';

  @override
  String get permissionsMicTitle => 'Microfone';

  @override
  String permissionsMicDescription(String wakeWord) {
    return 'Para áudio do vídeo e para escutar o comando “$wakeWord”.';
  }

  @override
  String get permissionsContinue => 'Continuar';

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
  String get cameraSessionInterrupted =>
      'Câmera interrompida. Tente novamente.';

  @override
  String get cameraFormatUnsupported =>
      'Resolução indisponível neste aparelho.';

  @override
  String get planPerMonth => '/mês';

  @override
  String get planPerYear => '/ano';

  @override
  String get galleryFilterAll => 'Todos';

  @override
  String get galleryFilterToday => 'Hoje';

  @override
  String get galleryFilterThisWeek => 'Esta semana';

  @override
  String get checkoutAppleSubtitle =>
      'App Store · Toque para autorizar com Face ID';

  @override
  String get checkoutGoogleSubtitle =>
      'Play Store · Cobrança na sua conta Google';

  @override
  String get checkoutAppleConfirmHint => 'AUTORIZE COM FACE ID · APP STORE';

  @override
  String get checkoutGoogleConfirmHint =>
      'AUTORIZE NA SUA CONTA GOOGLE · PLAY STORE';

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
  String get previewSave => 'Salvar';

  @override
  String get previewSaveFailed =>
      'Não foi possível guardar o vídeo. Tente de novo.';

  @override
  String get previewShareFailed => 'Não foi possível compartilhar o vídeo.';

  @override
  String get previewVideoTitle => 'Vídeo';

  @override
  String get previewVideoNotFound => 'Vídeo não encontrado';

  @override
  String get paywallTitle => 'Escolha seu plano';

  @override
  String paywallSubtitle(String brand, int days) {
    return 'Desbloqueie o potencial total do $brand. $days dias grátis, cancele quando quiser.';
  }

  @override
  String paywallSubtitleSave(String brand, int days) {
    return 'Assine para guardar este vídeo na galeria. $days dias grátis no $brand, cancele quando quiser.';
  }

  @override
  String paywallSubtitleShare(String brand, int days) {
    return 'Assine para compartilhar este vídeo. $days dias grátis no $brand, cancele quando quiser.';
  }

  @override
  String paywallMonthlyEquivalent(String price) {
    return 'R\$ $price / mês';
  }

  @override
  String get paywallBestOffer => 'MELHOR OFERTA';

  @override
  String get paywallSubscribeNow => 'Assinar agora';

  @override
  String get paywallRestorePurchases => 'Restaurar compras';

  @override
  String get paywallBack => 'Voltar';

  @override
  String get paywallPeriodMonthly => 'mensal';

  @override
  String get paywallPeriodYearly => 'anual';

  @override
  String paywallLegal(String period) {
    return 'Assinatura $period com renovação automática. Cancele a qualquer momento nas configurações da App Store.';
  }

  @override
  String get planPremium => 'Premium';

  @override
  String get planUnlockPotential => 'Desbloqueie todo o potencial';

  @override
  String get planFeature4k => 'Gravação em 4K 60fps';

  @override
  String get planFeatureBuffer => 'Buffer estendido';

  @override
  String get planFeatureNoAds => 'Sem anúncios';

  @override
  String planFreeDays(int days) {
    return '$days DIAS GRÁTIS';
  }

  @override
  String get planCancelAnytime => 'Cancele quando quiser';

  @override
  String get planSelected => 'SELECIONADO';

  @override
  String get popupEyebrow => 'ASSINATURA';

  @override
  String get popupTitle => 'Assinatura necessária';

  @override
  String get popupBody1 => 'Você pode usar o app normalmente, mas para ';

  @override
  String get popupBodyBold => 'salvar vídeos';

  @override
  String get popupBody2 => ' é preciso ativar a assinatura.';

  @override
  String get popupTrial1 => 'A assinatura inclui ';

  @override
  String popupTrialBold(int days) {
    return '$days dias grátis';
  }

  @override
  String popupTrial2(int days) {
    return '. Você pode cancelar antes de completar os $days dias e não será cobrado de nada.';
  }

  @override
  String get popupMaybeLater => 'Talvez depois';

  @override
  String get checkoutTitle => 'Finalizar assinatura';

  @override
  String get checkoutPaymentMethod => 'Método de pagamento';

  @override
  String get checkoutOrderSummary => 'RESUMO DO PEDIDO';

  @override
  String checkoutSubscription(String period) {
    return 'Assinatura $period';
  }

  @override
  String checkoutTrialPeriod(int days) {
    return 'Período de teste ($days dias)';
  }

  @override
  String get checkoutAfterTrial => 'Após o teste';

  @override
  String checkoutProcessedBy(String brand) {
    return 'Pagamento processado pela App Store ou Google Play. O $brand não armazena dados do seu cartão.';
  }

  @override
  String get checkoutSelectMethod => 'SELECIONE UM MÉTODO ACIMA';

  @override
  String get checkoutConfirm => 'Confirmar assinatura';

  @override
  String get checkoutStoreHint => 'A LOJA ABRE A FOLHA DE PAGAMENTO';

  @override
  String get paywallPurchaseFailed =>
      'Não foi possível concluir a compra. Tente de novo.';

  @override
  String get paywallRestoreEmpty =>
      'Nenhuma compra para restaurar neste aparelho.';

  @override
  String get paywallRestoreFailed =>
      'Não foi possível restaurar as compras. Tente de novo.';

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
