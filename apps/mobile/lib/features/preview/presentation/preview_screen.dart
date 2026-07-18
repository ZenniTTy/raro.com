import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:raro_mobile/core/theme/raro_fonts.dart';
import 'package:raro_mobile/core/theme/raro_theme.dart';
import 'package:raro_mobile/features/gallery/application/video_list_provider.dart';
import 'package:raro_mobile/features/gallery/domain/video_entity.dart';
import 'package:raro_mobile/features/preview/domain/preview_metadata.dart';
import 'package:raro_mobile/features/preview/presentation/widgets/preview_viewport.dart';
import 'package:raro_mobile/l10n/app_localizations.dart';

class PreviewScreen extends ConsumerWidget {
  const PreviewScreen({super.key, required this.videoId, required this.onBack});

  final String videoId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    final videosAsync = ref.watch(videoListProvider);

    return Scaffold(
      backgroundColor: colors.bgDeep,
      body: videosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _NotFound(onBack: onBack),
        data: (videos) {
          final video = videos.where((v) => v.id == videoId).firstOrNull;
          if (video == null) return _NotFound(onBack: onBack);
          return _PreviewBody(video: video, onBack: onBack);
        },
      ),
    );
  }
}

class _PreviewBody extends StatelessWidget {
  const _PreviewBody({required this.video, required this.onBack});

  final VideoEntity video;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final meta = PreviewMetadata.fromVideo(video);
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _Header(title: meta.titleLabel, onBack: onBack),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: PreviewViewport(video: video),
                  ),
                  const SizedBox(height: 20),
                  _InfoCard(meta: meta),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _BottomActions(onBack: onBack),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          _CircleButton(
            key: const Key('preview_back_button'),
            icon: Icons.arrow_back_ios_new,
            onTap: onBack,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                title,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: RaroFonts.display,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          _CircleButton(
            key: const Key('preview_share_button'),
            icon: Icons.ios_share,
            onTap: () => _comingSoon(context),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          shape: BoxShape.circle,
          border: Border.all(color: colors.borderBright),
        ),
        child: Icon(icon, size: 18, color: colors.ink),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.meta});

  final PreviewMetadata meta;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElev,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).previewInfoSection,
            style: TextStyle(
              fontFamily: RaroFonts.mono,
              fontSize: 11,
              letterSpacing: 1.65,
              color: colors.inkFaint,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoColumn(
                value: meta.sizeLabel,
                label: AppLocalizations.of(context).previewSizeLabel,
              ),
              _InfoColumn(
                value: meta.durationLabel,
                label: AppLocalizations.of(context).previewDurationLabel,
              ),
              _InfoColumn(
                value: meta.codecLabel,
                label: AppLocalizations.of(context).previewCodecLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  const _InfoColumn({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: RaroFonts.mono,
              fontSize: 15,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: colors.inkDim)),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 28 + bottomInset),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _comingSoon(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: colors.bgElev,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.borderBright),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.ios_share, size: 18, color: colors.ink),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context).previewShare,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _SquareAction(
            icon: Icons.delete_outline,
            color: colors.raroRed,
            onTap: () => _comingSoon(context),
          ),
          const SizedBox(width: 8),
          _SquareAction(
            icon: Icons.info_outline,
            color: colors.ink,
            onTap: () => _comingSoon(context),
          ),
        ],
      ),
    );
  }
}

class _SquareAction extends StatelessWidget {
  const _SquareAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: colors.bgElev,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderBright),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    return SafeArea(
      child: Column(
        children: [
          _Header(
            title: AppLocalizations.of(context).previewVideoTitle,
            onBack: onBack,
          ),
          Expanded(
            child: Center(
              child: Text(
                AppLocalizations.of(context).previewVideoNotFound,
                style: TextStyle(color: colors.inkDim),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _comingSoon(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).comingSoon),
        duration: const Duration(seconds: 1),
      ),
    );
}
