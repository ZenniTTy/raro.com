import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:raro_mobile/core/theme/raro_fonts.dart';
import 'package:raro_mobile/core/theme/raro_gradients.dart';
import 'package:raro_mobile/core/theme/raro_theme.dart';
import 'package:raro_mobile/features/gallery/application/video_list_provider.dart';
import 'package:raro_mobile/features/gallery/domain/gallery_filter.dart';
import 'package:raro_mobile/features/gallery/domain/video_entity.dart';
import 'package:raro_mobile/features/gallery/presentation/widgets/filter_pill.dart';
import 'package:raro_mobile/features/gallery/presentation/widgets/video_thumbnail.dart';
import 'package:raro_mobile/l10n/app_localizations.dart';

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({
    super.key,
    required this.onBack,
    required this.onOpenVideo,
  });

  final VoidCallback onBack;
  final ValueChanged<String> onOpenVideo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    final videosAsync = ref.watch(videoListProvider);

    return Scaffold(
      backgroundColor: colors.bgDeep,
      body: SafeArea(
        child: videosAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const SizedBox.shrink(),
          data: (videos) => _GalleryBody(
            videos: videos,
            onBack: onBack,
            onOpenVideo: onOpenVideo,
          ),
        ),
      ),
    );
  }
}

class _GalleryBody extends ConsumerWidget {
  const _GalleryBody({
    required this.videos,
    required this.onBack,
    required this.onOpenVideo,
  });

  final List<VideoEntity> videos;
  final VoidCallback onBack;
  final ValueChanged<String> onOpenVideo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(galleryFilterControllerProvider);
    final visible = filter.apply(videos, now: DateTime.now());

    return Column(
      children: [
        _Header(count: videos.length, onBack: onBack),
        _FilterBar(selected: filter),
        const _GradLineThin(),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 40),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemCount: visible.length,
            itemBuilder: (context, index) {
              final video = visible[index];
              return VideoThumbnail(
                key: ValueKey(video.id),
                video: video,
                onTap: () => onOpenVideo(video.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.count, required this.onBack});

  final int count;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            key: const Key('gallery_back_button'),
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
          Expanded(
            child: Text(
              AppLocalizations.of(context).galleryTitle,
              style: TextStyle(
                fontFamily: RaroFonts.display,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.ink,
              ),
            ),
          ),
          Text(
            AppLocalizations.of(context).galleryVideoCount(count),
            style: TextStyle(
              fontFamily: RaroFonts.mono,
              fontSize: 10,
              letterSpacing: 1,
              color: colors.inkDim,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.selected});

  final GalleryFilter selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          for (final filter in GalleryFilter.values) ...[
            FilterPill(
              label: _filterLabel(context, filter),
              active: filter == selected,
              onTap: () => ref
                  .read(galleryFilterControllerProvider.notifier)
                  .select(filter),
            ),
            if (filter != GalleryFilter.values.last) const SizedBox(width: 6),
          ],
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
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(gradient: RaroGradients.rainbow),
    );
  }
}

String _filterLabel(BuildContext context, GalleryFilter filter) {
  final l10n = AppLocalizations.of(context);
  return switch (filter) {
    GalleryFilter.all => l10n.galleryFilterAll,
    GalleryFilter.today => l10n.galleryFilterToday,
    GalleryFilter.thisWeek => l10n.galleryFilterThisWeek,
    GalleryFilter.raroReplay => 'Raro Replay',
  };
}
