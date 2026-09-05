import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:raro_mobile/core/l10n/app_locale.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart'
    show FormatCapability;
import 'package:raro_mobile/core/theme/raro_fonts.dart';
import 'package:raro_mobile/core/theme/raro_gradients.dart';
import 'package:raro_mobile/core/theme/raro_theme.dart';
import 'package:raro_mobile/features/camera/application/capabilities_provider.dart';
import 'package:raro_mobile/features/camera/domain/format_catalog.dart';
import 'package:raro_mobile/features/paywall/application/subscription_controller.dart';
import 'package:raro_mobile/features/settings/application/settings_controller.dart';
import 'package:raro_mobile/features/settings/domain/recording_settings.dart';
import 'package:raro_mobile/features/settings/presentation/widgets/control_mode_card.dart';
import 'package:raro_mobile/features/settings/presentation/widgets/language_grid.dart';
import 'package:raro_mobile/features/settings/presentation/widgets/replay_buffer_card.dart';
import 'package:raro_mobile/features/settings/presentation/widgets/settings_chip.dart';
import 'package:raro_mobile/features/settings/presentation/widgets/settings_section.dart';
import 'package:raro_mobile/features/volume/data/volume_repository_provider.dart';
import 'package:raro_mobile/l10n/app_localizations.dart';
import 'package:raro_shared/raro_shared.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({
    super.key,
    required this.onBack,
    required this.onSeePlans,
    required this.onTerms,
    required this.onPrivacy,
  });

  final VoidCallback onBack;
  final VoidCallback onSeePlans;
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    final settings = ref.watch(settingsControllerProvider);

    return Scaffold(
      backgroundColor: colors.bgDeep,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: onBack),
            const _GradLineThin(),
            Expanded(
              child: settings.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const SizedBox.shrink(),
                data: (data) => _SettingsBody(
                  settings: data,
                  onSeePlans: onSeePlans,
                  onTerms: onTerms,
                  onPrivacy: onPrivacy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            key: const Key('settings_back_button'),
            onTap: onBack,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colors.borderBright),
              ),
              child: Icon(Icons.arrow_back, size: 18, color: colors.ink),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context).settingsTitle,
            style: TextStyle(
              fontFamily: RaroFonts.display,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradLineThin extends StatelessWidget {
  const _GradLineThin();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: const BoxDecoration(gradient: RaroGradients.rainbow),
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  const _SettingsBody({
    required this.settings,
    required this.onSeePlans,
    required this.onTerms,
    required this.onPrivacy,
  });

  final RecordingSettings settings;
  final VoidCallback onSeePlans;
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(settingsControllerProvider.notifier);
    final supportedFormats = ref.watch(capabilitiesProvider);
    final volumeAvailable = ref.watch(volumeAvailableProvider).value ?? false;
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        SettingsSection(
          title: l10n.settingsQualitySection,
          child: _RecordingQuality(
            settings: settings,
            supportedFormats: supportedFormats,
            onResolution: controller.setResolution,
            onFps: controller.setFps,
          ),
        ),
        const SizedBox(height: 14),
        ReplayBufferCard(
          selected: settings.bufferDuration,
          onSelected: controller.setBufferDuration,
        ),
        const SizedBox(height: 14),
        SettingsSection(
          title: l10n.settingsControlSection,
          child: _ControlMode(
            selected: settings.controlMode,
            onSelected: controller.setControlMode,
            volumeAvailable: volumeAvailable,
          ),
        ),
        const SizedBox(height: 14),
        SettingsSection(
          title: l10n.settingsLanguageSection,
          child: LanguageGrid(
            selected:
                settings.language ??
                languageForLocale(Localizations.localeOf(context)),
            onSelected: controller.setLanguage,
          ),
        ),
        const SizedBox(height: 14),
        const _TrialBanner(),
        _SeePlansButton(onTap: onSeePlans),
        const SizedBox(height: 14),
        SettingsSection(
          title: l10n.settingsAboutSection,
          child: _About(onTerms: onTerms, onPrivacy: onPrivacy),
        ),
        const SizedBox(height: 24),
        const _Wordmark(),
      ],
    );
  }
}

class _RecordingQuality extends StatelessWidget {
  const _RecordingQuality({
    required this.settings,
    required this.supportedFormats,
    required this.onResolution,
    required this.onFps,
  });

  final RecordingSettings settings;
  final List<FormatCapability> supportedFormats;
  final ValueChanged<Resolution> onResolution;
  final ValueChanged<Fps> onFps;

  static const _fallbackResolutions = <Resolution>[
    Resolution.hd720,
    Resolution.fullHd1080,
    Resolution.uhd4k,
  ];

  static const _resolutionLabels = <Resolution, String>{
    Resolution.hd720: '720p HD',
    Resolution.fullHd1080: '1080p Full HD',
    Resolution.uhd4k: '4K Ultra HD',
    Resolution.uhd4k60: '4K 60fps',
  };

  List<Resolution> get _resolutions {
    if (supportedFormats.isEmpty) return _fallbackResolutions;
    return availableSharedResolutions(supportedFormats);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    final l10n = AppLocalizations.of(context);
    final resolutions = _resolutions;
    final fpsLocked = settings.resolution == Resolution.uhd4k60;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(l10n.settingsResolutionLabel, colors),
        const SizedBox(height: 8),
        for (var i = 0; i < resolutions.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 6),
          Row(
            children: [
              for (var j = i; j < i + 2 && j < resolutions.length; j++) ...[
                if (j > i) const SizedBox(width: 6),
                Expanded(
                  child: SettingsChip(
                    label: _resolutionLabels[resolutions[j]]!,
                    hint: resolutions[j] == Resolution.uhd4k60
                        ? l10n.settingsResolutionFixedLensHint
                        : null,
                    active: settings.resolution == resolutions[j],
                    onTap: () => onResolution(resolutions[j]),
                  ),
                ),
              ],
            ],
          ),
        ],
        if (!fpsLocked) ...[
          const SizedBox(height: 14),
          _Label('FPS', colors),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SettingsChip(
                  label: '30 FPS',
                  hint: l10n.settingsFpsStandardHint,
                  active: settings.fps == Fps.fps30,
                  onTap: () => onFps(Fps.fps30),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: SettingsChip(
                  label: '60 FPS',
                  hint: l10n.settingsFpsSmoothHint,
                  active: settings.fps == Fps.fps60,
                  onTap: () => onFps(Fps.fps60),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        const _StabilizationRow(),
      ],
    );
  }
}

class _StabilizationRow extends StatelessWidget {
  const _StabilizationRow();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    const green = RaroAccents.green;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).settingsStabilizationTitle,
                style: TextStyle(fontSize: 14, color: colors.ink),
              ),
              const SizedBox(height: 2),
              Text(
                AppLocalizations.of(context).settingsStabilizationSubtitle,
                style: TextStyle(fontSize: 11, color: colors.inkDim),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: green.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).settingsStabilizationAlways,
                style: const TextStyle(
                  fontFamily: RaroFonts.mono,
                  fontSize: 10,
                  letterSpacing: 1.2,
                  color: green,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ControlMode extends StatelessWidget {
  const _ControlMode({
    required this.selected,
    required this.onSelected,
    required this.volumeAvailable,
  });

  final ControlMode selected;
  final ValueChanged<ControlMode> onSelected;
  final bool volumeAvailable;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 12.5, height: 1.5, color: colors.inkDim),
            children: [
              TextSpan(text: l10n.settingsControlModeIntro),
              TextSpan(
                text: 'ON',
                style: TextStyle(color: colors.ink),
              ),
              TextSpan(
                text: volumeAvailable
                    ? l10n.settingsControlModeVoicePart
                    : l10n.settingsControlModeVoiceOnlyPart,
              ),
              if (volumeAvailable) ...[
                TextSpan(
                  text: 'OFF',
                  style: TextStyle(color: colors.ink),
                ),
                TextSpan(text: l10n.settingsControlModeVolumePart),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            if (volumeAvailable) ...[
              Expanded(
                child: ControlModeCard(
                  badge: 'OFF',
                  title: l10n.settingsControlVolumeTitle,
                  subtitle: l10n.settingsControlVolumeSubtitle,
                  active: selected == ControlMode.volume,
                  onTap: () => onSelected(ControlMode.volume),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: ControlModeCard(
                badge: 'ON',
                title: l10n.settingsControlVoiceTitle,
                subtitle: l10n.settingsControlVoiceSubtitle(
                  VoiceConfig.wakeWord,
                ),
                active: selected == ControlMode.voice,
                onTap: () => onSelected(ControlMode.voice),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TrialBanner extends ConsumerWidget {
  const _TrialBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    final subscription = ref.watch(subscriptionControllerProvider).value;
    if (subscription == null) return const SizedBox.shrink();
    final remaining = subscription.trialDaysRemaining(DateTime.now());
    if (!subscription.isSubscribed || remaining <= 0) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: RaroAccents.yellow.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: RaroAccents.yellow.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.hourglass_bottom,
              size: 18,
              color: RaroAccents.yellow,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                AppLocalizations.of(context).settingsTrialBanner(remaining),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: colors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeePlansButton extends StatelessWidget {
  const _SeePlansButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('settings_see_plans_button'),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: RaroGradients.rainbow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.workspace_premium_outlined,
              size: 16,
              color: Colors.black,
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context).settingsSeePlans,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _About extends StatelessWidget {
  const _About({required this.onTerms, required this.onPrivacy});

  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.settingsVersionLabel,
                style: TextStyle(fontSize: 13, color: colors.inkDim),
              ),
              Text(
                '1.0.0 · build 23',
                style: TextStyle(
                  fontFamily: RaroFonts.mono,
                  fontSize: 12,
                  color: colors.ink,
                ),
              ),
            ],
          ),
        ),
        _AboutLink(
          key: const Key('settings_terms_link'),
          label: l10n.termsOfUse,
          colors: colors,
          onTap: onTerms,
        ),
        _AboutLink(
          key: const Key('settings_privacy_link'),
          label: l10n.privacyPolicy,
          colors: colors,
          onTap: onPrivacy,
        ),
      ],
    );
  }
}

class _AboutLink extends StatelessWidget {
  const _AboutLink({
    super.key,
    required this.label,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final RaroColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 13, color: colors.ink)),
            Icon(Icons.chevron_right, size: 16, color: colors.inkFaint),
          ],
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    return Center(
      child: Text(
        'RARO · CAPTURE UNSCRIPTED',
        style: TextStyle(
          fontFamily: RaroFonts.mono,
          fontSize: 10,
          letterSpacing: 2,
          color: colors.inkFaint,
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, this.colors);

  final String text;
  final RaroColors colors;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(fontSize: 11, color: colors.inkDim));
  }
}
