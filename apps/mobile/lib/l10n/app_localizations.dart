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

  /// URL pública do texto legal aberto no app
  ///
  /// In pt, this message translates to:
  /// **'Também em {url}'**
  String legalCanonicalHint(String url);

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

  /// CTA de avançar do onboarding
  ///
  /// In pt, this message translates to:
  /// **'Avançar'**
  String get onboardingNext;

  /// Botão de pular onboarding
  ///
  /// In pt, this message translates to:
  /// **'Pular'**
  String get onboardingSkip;

  /// Título da página 1 do onboarding
  ///
  /// In pt, this message translates to:
  /// **'Grave sem tocar'**
  String get onboarding1Title;

  /// Fragmento antes da wake word na página 1
  ///
  /// In pt, this message translates to:
  /// **'Diga '**
  String get onboarding1Say;

  /// Fragmento após a wake word na página 1
  ///
  /// In pt, this message translates to:
  /// **' para iniciar ou encerrar sua gravação.'**
  String get onboarding1SayTail;

  /// Tagline da página 1; brand é a marca RARO, não traduzida
  ///
  /// In pt, this message translates to:
  /// **'— O {brand} escuta.'**
  String onboarding1Tagline(String brand);

  /// Título da página 2 do onboarding
  ///
  /// In pt, this message translates to:
  /// **'Nunca perca o momento'**
  String get onboarding2Title;

  /// Fragmento antes de Raro Replay na página 2
  ///
  /// In pt, this message translates to:
  /// **'O '**
  String get onboarding2Intro;

  /// Fragmento entre Raro Replay e a duração
  ///
  /// In pt, this message translates to:
  /// **' salva automaticamente os últimos '**
  String get onboarding2SavesLast;

  /// Duração destacada do buffer na página 2
  ///
  /// In pt, this message translates to:
  /// **'15 ou 30 segundos'**
  String get onboarding2Seconds;

  /// Fragmento entre a duração e o token REC
  ///
  /// In pt, this message translates to:
  /// **'. Aconteceu algo importante? Basta apertar o botão '**
  String get onboarding2Middle;

  /// Fragmento entre REC e a frase de comando
  ///
  /// In pt, this message translates to:
  /// **' ou dizer: '**
  String get onboarding2OrSay;

  /// Frase de comando destacada; wakeWord não é traduzido
  ///
  /// In pt, this message translates to:
  /// **'\"{wakeWord}, começar a gravar.\"'**
  String onboarding2WakePhrase(String wakeWord);

  /// Label esquerdo da visualização de buffer no onboarding
  ///
  /// In pt, this message translates to:
  /// **'BUFFER · 15s'**
  String get bufferVisualizationLabel;

  /// Label direito da visualização de buffer
  ///
  /// In pt, this message translates to:
  /// **'AGORA'**
  String get bufferVisualizationNow;

  /// Legenda sob a visualização de buffer
  ///
  /// In pt, this message translates to:
  /// **'Os 15s anteriores ficam salvos'**
  String get bufferVisualizationCaption;

  /// Eyebrow da tela de permissões
  ///
  /// In pt, this message translates to:
  /// **'PASSO 1 DE 1'**
  String get permissionsStep;

  /// Título da tela de permissões
  ///
  /// In pt, this message translates to:
  /// **'Permissões essenciais'**
  String get permissionsTitle;

  /// Descrição da tela de permissões; brand não é traduzido
  ///
  /// In pt, this message translates to:
  /// **'O {brand} precisa de acesso para funcionar plenamente. Você pode revogar a qualquer momento.'**
  String permissionsDescription(String brand);

  /// Título do card de permissão de câmera
  ///
  /// In pt, this message translates to:
  /// **'Câmera'**
  String get permissionsCameraTitle;

  /// Descrição do card de câmera
  ///
  /// In pt, this message translates to:
  /// **'Necessário para gravar vídeo em 4K com lentes 0.5x e 1x.'**
  String get permissionsCameraDescription;

  /// Título do card de permissão de microfone
  ///
  /// In pt, this message translates to:
  /// **'Microfone'**
  String get permissionsMicTitle;

  /// Descrição do card de microfone; wakeWord não é traduzido
  ///
  /// In pt, this message translates to:
  /// **'Para áudio do vídeo e para escutar o comando “{wakeWord}”.'**
  String permissionsMicDescription(String wakeWord);

  /// CTA da tela de permissões
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get permissionsContinue;

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

  /// Erro quando a sessão da câmera é interrompida
  ///
  /// In pt, this message translates to:
  /// **'Câmera interrompida. Tente novamente.'**
  String get cameraSessionInterrupted;

  /// Erro quando o formato pedido não existe no aparelho
  ///
  /// In pt, this message translates to:
  /// **'Resolução indisponível neste aparelho.'**
  String get cameraFormatUnsupported;

  /// Sufixo de preço do plano mensal
  ///
  /// In pt, this message translates to:
  /// **'/mês'**
  String get planPerMonth;

  /// Sufixo de preço do plano anual
  ///
  /// In pt, this message translates to:
  /// **'/ano'**
  String get planPerYear;

  /// Filtro da galeria: todos os vídeos
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get galleryFilterAll;

  /// Filtro da galeria: gravados hoje
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get galleryFilterToday;

  /// Filtro da galeria: gravados nesta semana
  ///
  /// In pt, this message translates to:
  /// **'Esta semana'**
  String get galleryFilterThisWeek;

  /// Subtítulo do método Apple Pay; marcas não são traduzidas
  ///
  /// In pt, this message translates to:
  /// **'App Store · Toque para autorizar com Face ID'**
  String get checkoutAppleSubtitle;

  /// Subtítulo do método Google Play; marcas não são traduzidas
  ///
  /// In pt, this message translates to:
  /// **'Play Store · Cobrança na sua conta Google'**
  String get checkoutGoogleSubtitle;

  /// Hint de confirmação do método Apple
  ///
  /// In pt, this message translates to:
  /// **'AUTORIZE COM FACE ID · APP STORE'**
  String get checkoutAppleConfirmHint;

  /// Hint de confirmação do método Google
  ///
  /// In pt, this message translates to:
  /// **'AUTORIZE NA SUA CONTA GOOGLE · PLAY STORE'**
  String get checkoutGoogleConfirmHint;

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

  /// CTA de guardar o clipe pendente no preview
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get previewSave;

  /// Erro ao persistir o clipe no vault ou na galeria
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível guardar o vídeo. Tente de novo.'**
  String get previewSaveFailed;

  /// Erro ao abrir a folha nativa de compartilhar
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível compartilhar o vídeo.'**
  String get previewShareFailed;

  /// Billing falhou ao checar premium no Salvar/Compartilhar; não abrir paywall
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível verificar sua assinatura. Tente de novo.'**
  String get previewEntitlementUnavailable;

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

  /// Título do diálogo de confirmação da lixeira no preview
  ///
  /// In pt, this message translates to:
  /// **'Apagar este vídeo?'**
  String get previewDeleteTitle;

  /// Explica que o delete é só do vault, não do rolo do sistema
  ///
  /// In pt, this message translates to:
  /// **'O vídeo sai só do RARO. Uma cópia já salva no app de Fotos do celular permanece.'**
  String get previewDeleteBody;

  /// Confirma a exclusão irreversível do vault
  ///
  /// In pt, this message translates to:
  /// **'Apagar'**
  String get previewDeleteConfirm;

  /// Cancela a exclusão e mantém o clipe
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get previewDeleteCancel;

  /// Snack quando o vault.delete falha; a tela de preview permanece
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível apagar o vídeo. Tente de novo.'**
  String get previewDeleteFailed;

  /// Título do painel de detalhes do clipe
  ///
  /// In pt, this message translates to:
  /// **'Detalhes'**
  String get previewDetailsTitle;

  /// Campo nome no painel de detalhes
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get previewDetailsName;

  /// Campo duração no painel de detalhes
  ///
  /// In pt, this message translates to:
  /// **'Duração'**
  String get previewDetailsDuration;

  /// Campo data/hora no painel de detalhes
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get previewDetailsRecordedAt;

  /// Campo resolução no painel de detalhes
  ///
  /// In pt, this message translates to:
  /// **'Resolução'**
  String get previewDetailsResolution;

  /// Campo fps no painel de detalhes
  ///
  /// In pt, this message translates to:
  /// **'FPS'**
  String get previewDetailsFps;

  /// Campo lente no painel de detalhes
  ///
  /// In pt, this message translates to:
  /// **'Lente'**
  String get previewDetailsLens;

  /// Campo tamanho do arquivo no painel de detalhes
  ///
  /// In pt, this message translates to:
  /// **'Tamanho'**
  String get previewDetailsSize;

  /// Campo se o clipe é replay no painel de detalhes
  ///
  /// In pt, this message translates to:
  /// **'Replay'**
  String get previewDetailsReplay;

  /// Valor positivo do campo replay
  ///
  /// In pt, this message translates to:
  /// **'Sim'**
  String get previewDetailsReplayYes;

  /// Valor negativo do campo replay
  ///
  /// In pt, this message translates to:
  /// **'Não'**
  String get previewDetailsReplayNo;

  /// Placeholder quando o sidecar não tem o campo
  ///
  /// In pt, this message translates to:
  /// **'—'**
  String get previewDetailsUnavailable;

  /// Título do paywall
  ///
  /// In pt, this message translates to:
  /// **'Escolha seu plano'**
  String get paywallTitle;

  /// Subtítulo do paywall; brand não é traduzido; days vem de raro_shared
  ///
  /// In pt, this message translates to:
  /// **'Desbloqueie o potencial total do {brand}. {days} dias grátis, cancele quando quiser.'**
  String paywallSubtitle(String brand, int days);

  /// Subtítulo do paywall quando a origem é Salvar
  ///
  /// In pt, this message translates to:
  /// **'Assine para guardar este vídeo na galeria. {days} dias grátis no {brand}, cancele quando quiser.'**
  String paywallSubtitleSave(String brand, int days);

  /// Subtítulo do paywall quando a origem é Compartilhar
  ///
  /// In pt, this message translates to:
  /// **'Assine para compartilhar este vídeo. {days} dias grátis no {brand}, cancele quando quiser.'**
  String paywallSubtitleShare(String brand, int days);

  /// Equivalente mensal do plano anual; moeda fixa em BRL nesta fase
  ///
  /// In pt, this message translates to:
  /// **'R\$ {price} / mês'**
  String paywallMonthlyEquivalent(String price);

  /// Badge do plano anual (invariant de produto)
  ///
  /// In pt, this message translates to:
  /// **'MELHOR OFERTA'**
  String get paywallBestOffer;

  /// CTA principal do paywall e do popup
  ///
  /// In pt, this message translates to:
  /// **'Assinar agora'**
  String get paywallSubscribeNow;

  /// CTA secundário de restauração
  ///
  /// In pt, this message translates to:
  /// **'Restaurar compras'**
  String get paywallRestorePurchases;

  /// Link de voltar do paywall
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get paywallBack;

  /// Palavra do período mensal usada em frases compostas
  ///
  /// In pt, this message translates to:
  /// **'mensal'**
  String get paywallPeriodMonthly;

  /// Palavra do período anual usada em frases compostas
  ///
  /// In pt, this message translates to:
  /// **'anual'**
  String get paywallPeriodYearly;

  /// Texto legal do paywall (2.8); period é paywallPeriodMonthly/Yearly; days vem de raro_shared
  ///
  /// In pt, this message translates to:
  /// **'Assinatura {period} com renovação automática. Inclui {days} dias grátis. Cancele a qualquer momento nas configurações da App Store ou do Google Play. Desinstalar o app não cancela a assinatura.'**
  String paywallLegal(String period, int days);

  /// Nome do plano no card e no checkout
  ///
  /// In pt, this message translates to:
  /// **'Premium'**
  String get planPremium;

  /// Subtítulo do card de plano
  ///
  /// In pt, this message translates to:
  /// **'Desbloqueie todo o potencial'**
  String get planUnlockPotential;

  /// Feature 1 do plano
  ///
  /// In pt, this message translates to:
  /// **'Gravação em 4K 60fps'**
  String get planFeature4k;

  /// Feature 2 do plano
  ///
  /// In pt, this message translates to:
  /// **'Buffer estendido'**
  String get planFeatureBuffer;

  /// Feature 3 do plano
  ///
  /// In pt, this message translates to:
  /// **'Sem anúncios'**
  String get planFeatureNoAds;

  /// Pill de dias grátis; days vem de raro_shared
  ///
  /// In pt, this message translates to:
  /// **'{days} DIAS GRÁTIS'**
  String planFreeDays(int days);

  /// Nota sob a pill de dias grátis
  ///
  /// In pt, this message translates to:
  /// **'Cancele quando quiser'**
  String get planCancelAnytime;

  /// Pill do plano selecionado
  ///
  /// In pt, this message translates to:
  /// **'SELECIONADO'**
  String get planSelected;

  /// Eyebrow do popup de assinatura
  ///
  /// In pt, this message translates to:
  /// **'ASSINATURA'**
  String get popupEyebrow;

  /// Título do popup de assinatura
  ///
  /// In pt, this message translates to:
  /// **'Assinatura necessária'**
  String get popupTitle;

  /// Fragmento 1 do corpo do popup, antes do trecho em negrito
  ///
  /// In pt, this message translates to:
  /// **'Você pode usar o app normalmente, mas para '**
  String get popupBody1;

  /// Trecho em negrito do corpo do popup
  ///
  /// In pt, this message translates to:
  /// **'salvar vídeos'**
  String get popupBodyBold;

  /// Fragmento 2 do corpo do popup
  ///
  /// In pt, this message translates to:
  /// **' é preciso ativar a assinatura.'**
  String get popupBody2;

  /// Fragmento antes dos dias grátis em negrito
  ///
  /// In pt, this message translates to:
  /// **'A assinatura inclui '**
  String get popupTrial1;

  /// Dias grátis em negrito no popup
  ///
  /// In pt, this message translates to:
  /// **'{days} dias grátis'**
  String popupTrialBold(int days);

  /// Fragmento final sobre cancelamento no popup
  ///
  /// In pt, this message translates to:
  /// **'. Você pode cancelar antes de completar os {days} dias e não será cobrado de nada.'**
  String popupTrial2(int days);

  /// CTA de dispensar o popup
  ///
  /// In pt, this message translates to:
  /// **'Talvez depois'**
  String get popupMaybeLater;

  /// Título do header do checkout
  ///
  /// In pt, this message translates to:
  /// **'Finalizar assinatura'**
  String get checkoutTitle;

  /// Label da seção de método de pagamento
  ///
  /// In pt, this message translates to:
  /// **'Método de pagamento'**
  String get checkoutPaymentMethod;

  /// Label da seção de resumo
  ///
  /// In pt, this message translates to:
  /// **'RESUMO DO PEDIDO'**
  String get checkoutOrderSummary;

  /// Linha do tipo de assinatura; period é paywallPeriodMonthly/Yearly
  ///
  /// In pt, this message translates to:
  /// **'Assinatura {period}'**
  String checkoutSubscription(String period);

  /// Linha do período de teste no resumo
  ///
  /// In pt, this message translates to:
  /// **'Período de teste ({days} dias)'**
  String checkoutTrialPeriod(int days);

  /// Linha do valor pós-teste no resumo
  ///
  /// In pt, this message translates to:
  /// **'Após o teste'**
  String get checkoutAfterTrial;

  /// Nota de segurança do checkout; marcas de loja e brand não são traduzidas
  ///
  /// In pt, this message translates to:
  /// **'Pagamento processado pela App Store ou Google Play. O {brand} não armazena dados do seu cartão.'**
  String checkoutProcessedBy(String brand);

  /// Hint do bottom bar sem método selecionado
  ///
  /// In pt, this message translates to:
  /// **'SELECIONE UM MÉTODO ACIMA'**
  String get checkoutSelectMethod;

  /// CTA final do checkout
  ///
  /// In pt, this message translates to:
  /// **'Confirmar assinatura'**
  String get checkoutConfirm;

  /// Hint do checkout: a folha nativa da loja (ou Test Store) cobra
  ///
  /// In pt, this message translates to:
  /// **'A LOJA ABRE A FOLHA DE PAGAMENTO'**
  String get checkoutStoreHint;

  /// SnackBar de falha de compra (não inclui cancelamento)
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível concluir a compra. Tente de novo.'**
  String get paywallPurchaseFailed;

  /// SnackBar de restore sem entitlement premium
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma compra para restaurar neste aparelho.'**
  String get paywallRestoreEmpty;

  /// SnackBar de falha de restore
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível restaurar as compras. Tente de novo.'**
  String get paywallRestoreFailed;

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
