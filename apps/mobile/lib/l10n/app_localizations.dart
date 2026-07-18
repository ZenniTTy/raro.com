import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
  ];

  /// Título do header da tela de configurações
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get settingsTitle;

  /// Título da seção de qualidade em configurações
  ///
  /// In pt, this message translates to:
  /// **'Qualidade de Gravação'**
  String get settingsQualitySection;

  /// Título da seção de modo de controle em configurações
  ///
  /// In pt, this message translates to:
  /// **'Controle de Gravação'**
  String get settingsControlSection;

  /// Título da seção do seletor de idioma
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get settingsLanguageSection;

  /// Título da seção sobre o app
  ///
  /// In pt, this message translates to:
  /// **'Sobre'**
  String get settingsAboutSection;

  /// Label acima dos chips de resolução
  ///
  /// In pt, this message translates to:
  /// **'Resolução'**
  String get settingsResolutionLabel;

  /// Hint do chip 4K60 indicando restrição de lente
  ///
  /// In pt, this message translates to:
  /// **'lente fixa'**
  String get settingsResolutionFixedLensHint;

  /// Hint do chip 30 FPS
  ///
  /// In pt, this message translates to:
  /// **'Standard'**
  String get settingsFpsStandardHint;

  /// Hint do chip 60 FPS
  ///
  /// In pt, this message translates to:
  /// **'Smooth'**
  String get settingsFpsSmoothHint;

  /// Título da linha de estabilização
  ///
  /// In pt, this message translates to:
  /// **'Estabilização nativa'**
  String get settingsStabilizationTitle;

  /// Subtítulo da linha de estabilização
  ///
  /// In pt, this message translates to:
  /// **'Reduz tremor com sensor'**
  String get settingsStabilizationSubtitle;

  /// Pill indicando estabilização sempre ligada
  ///
  /// In pt, this message translates to:
  /// **'SEMPRE ATIVADA'**
  String get settingsStabilizationAlways;

  /// Fragmento 1 da descrição do modo de controle, antes do token ON
  ///
  /// In pt, this message translates to:
  /// **'Escolha o modo que você deseja gravar. No modo '**
  String get settingsControlModeIntro;

  /// Fragmento 2 da descrição, entre os tokens ON e OFF
  ///
  /// In pt, this message translates to:
  /// **' a gravação é controlada pela voz. No modo '**
  String get settingsControlModeVoicePart;

  /// Fragmento 3 da descrição, após o token OFF
  ///
  /// In pt, this message translates to:
  /// **', a gravação é controlada pelos botões laterais de volume do aparelho.'**
  String get settingsControlModeVolumePart;

  /// Título do card de controle por volume
  ///
  /// In pt, this message translates to:
  /// **'Volume'**
  String get settingsControlVolumeTitle;

  /// Subtítulo do card de controle por volume
  ///
  /// In pt, this message translates to:
  /// **'+ ou −'**
  String get settingsControlVolumeSubtitle;

  /// Título do card de controle por voz
  ///
  /// In pt, this message translates to:
  /// **'Voz ativa'**
  String get settingsControlVoiceTitle;

  /// Subtítulo do card de voz; wakeWord vem de VoiceConfig e não é traduzido
  ///
  /// In pt, this message translates to:
  /// **'Diga \"{wakeWord}\"'**
  String settingsControlVoiceSubtitle(String wakeWord);

  /// Badge de recurso indisponível no card de controle
  ///
  /// In pt, this message translates to:
  /// **'em breve'**
  String get settingsComingSoonBadge;

  /// Banner com dias restantes do período de teste
  ///
  /// In pt, this message translates to:
  /// **'{days, plural, =1{Período de teste · 1 dia restante} other{Período de teste · {days} dias restantes}}'**
  String settingsTrialBanner(int days);

  /// Botão que navega para o paywall
  ///
  /// In pt, this message translates to:
  /// **'Ver Planos'**
  String get settingsSeePlans;

  /// Label da linha de versão em Sobre
  ///
  /// In pt, this message translates to:
  /// **'Versão'**
  String get settingsVersionLabel;

  /// Link para termos de uso (Sobre e paywall)
  ///
  /// In pt, this message translates to:
  /// **'Termos de Uso'**
  String get termsOfUse;

  /// Link para política de privacidade (Sobre e paywall)
  ///
  /// In pt, this message translates to:
  /// **'Política de Privacidade'**
  String get privacyPolicy;

  /// Sufixo do badge do card Raro Replay; a marca fica fora da tradução
  ///
  /// In pt, this message translates to:
  /// **'Buffer rotativo'**
  String get replayBufferBadge;

  /// Descrição do card Raro Replay; wakeWord não é traduzido
  ///
  /// In pt, this message translates to:
  /// **'Grava 15 ou 30 segundos antes do comando de voz \"{wakeWord}\" ou do botão na tela inicial.'**
  String replayBufferDescription(String wakeWord);

  /// Label acima dos chips 15s/30s
  ///
  /// In pt, this message translates to:
  /// **'Duração do buffer'**
  String get replayBufferDurationLabel;

  /// Hint central da câmera quando a voz escuta; wakeWord não é traduzido
  ///
  /// In pt, this message translates to:
  /// **'DIGA “{wakeWord}” PARA GRAVAR'**
  String voiceSayToRecord(String wakeWord);

  /// Indicador de voz pausada na câmera
  ///
  /// In pt, this message translates to:
  /// **'VOZ PAUSADA'**
  String get voicePaused;

  /// Indicador quando o reconhecimento de voz está indisponível
  ///
  /// In pt, this message translates to:
  /// **'ATIVAR VOZ NAS CONFIGURAÇÕES'**
  String get voiceEnableInSettings;

  /// SnackBar de erro genérico ao gravar
  ///
  /// In pt, this message translates to:
  /// **'Falha ao gravar'**
  String get cameraRecordFailed;

  /// Erro de replay por aquecimento do aparelho
  ///
  /// In pt, this message translates to:
  /// **'Replay pausado: o aparelho está aquecido.'**
  String get cameraReplayThermal;

  /// Erro genérico ao salvar o replay
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar o replay.'**
  String get cameraReplaySaveFailed;

  /// Aviso sob o seletor de lente quando 4K60 trava a ultra-wide
  ///
  /// In pt, this message translates to:
  /// **'indisponível em 4K60'**
  String get cameraLensUnavailable4k60;

  /// Pill de confirmação do pré-roll incluído na gravação
  ///
  /// In pt, this message translates to:
  /// **'últimos {seconds}s incluídos'**
  String cameraPrerollIncluded(int seconds);

  /// Título do header da galeria
  ///
  /// In pt, this message translates to:
  /// **'Galeria'**
  String get galleryTitle;

  /// Label da seção de metadados no preview
  ///
  /// In pt, this message translates to:
  /// **'INFO'**
  String get previewInfoSection;

  /// Coluna de tamanho do arquivo no preview
  ///
  /// In pt, this message translates to:
  /// **'TAMANHO'**
  String get previewSizeLabel;

  /// Coluna de duração no preview
  ///
  /// In pt, this message translates to:
  /// **'DURAÇÃO'**
  String get previewDurationLabel;

  /// Coluna de codec no preview
  ///
  /// In pt, this message translates to:
  /// **'CODEC'**
  String get previewCodecLabel;

  /// Botão de compartilhar no preview
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar'**
  String get previewShare;

  /// Título fallback do header do preview
  ///
  /// In pt, this message translates to:
  /// **'Vídeo'**
  String get previewVideoTitle;

  /// Estado vazio quando o vídeo não existe mais
  ///
  /// In pt, this message translates to:
  /// **'Vídeo não encontrado'**
  String get previewVideoNotFound;

  /// SnackBar de recurso ainda não disponível
  ///
  /// In pt, this message translates to:
  /// **'Em breve'**
  String get comingSoon;

  /// Contador de vídeos no header da galeria
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{nenhum vídeo} =1{1 vídeo} other{{count} vídeos}}'**
  String galleryVideoCount(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
