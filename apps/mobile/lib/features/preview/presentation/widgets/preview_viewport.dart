import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:raro_mobile/core/theme/raro_fonts.dart';
import 'package:raro_mobile/core/theme/raro_gradients.dart';
import 'package:raro_mobile/core/theme/raro_theme.dart';
import 'package:raro_mobile/features/gallery/domain/video_entity.dart';
import 'package:raro_mobile/features/preview/application/preview_controller_provider.dart';
import 'package:raro_mobile/features/preview/domain/preview_info_badge.dart';
import 'package:video_player/video_player.dart';

class PreviewViewport extends ConsumerStatefulWidget {
  const PreviewViewport({super.key, required this.video});

  final VideoEntity video;

  @override
  ConsumerState<PreviewViewport> createState() => _PreviewViewportState();
}

class _PreviewViewportState extends ConsumerState<PreviewViewport> {
  bool _playing = false;

  void _togglePlay(VideoPlayerController? controller) {
    if (controller == null || !controller.value.isInitialized) return;
    setState(() {
      _playing = !_playing;
      _playing ? controller.play() : controller.pause();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    final controllerAsync = ref.watch(previewControllerProvider(widget.video));
    final controller = controllerAsync.value;
    final playback = controller?.value;
    final size = playback != null && playback.isInitialized
        ? playback.size
        : null;
    final badge = previewInfoBadge(
      width: size?.width,
      height: size?.height,
      storedResolution: widget.video.resolutionLabel,
      storedFps: widget.video.fpsLabel,
      storedLens: widget.video.lensLabel,
    );
    final base = HSLColor.fromAHSL(
      1,
      widget.video.thumbnailHue.toDouble(),
      0.65,
      0.35,
    ).toColor();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 9 / 14,
        child: GestureDetector(
          onTap: () => _togglePlay(controller),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: colors.bgDeep),
              if (controller != null && controller.value.isInitialized)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: controller.value.size.width,
                    height: controller.value.size.height,
                    child: VideoPlayer(controller),
                  ),
                )
              else
                DecoratedBox(
                  decoration: BoxDecoration(
                    backgroundBlendMode: BlendMode.screen,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        base.withValues(alpha: 0.7),
                        base.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                    stops: [0.4, 1],
                  ),
                ),
              ),
              Positioned(top: 12, left: 12, child: _InfoBadge(label: badge)),
              if (!_playing)
                Center(
                  child: Container(
                    key: const Key('preview_play_button'),
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      size: 34,
                      color: Colors.white,
                    ),
                  ),
                ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: _Scrubber(controller: controller, video: widget.video),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: RaroFonts.mono,
          fontSize: 10,
          letterSpacing: 1,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _Scrubber extends StatelessWidget {
  const _Scrubber({required this.controller, required this.video});

  final VideoPlayerController? controller;
  final VideoEntity video;

  @override
  Widget build(BuildContext context) {
    final total = video.formattedDuration;
    if (controller != null && controller!.value.isInitialized) {
      return ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: controller!,
        builder: (context, value, _) {
          final dur = value.duration.inMilliseconds;
          final progress = dur == 0
              ? 0.0
              : (value.position.inMilliseconds / dur).clamp(0.0, 1.0);
          return _ScrubberView(
            progress: progress,
            position: _format(value.position),
            total: total,
            onSeek: (fraction) => controller!.seekTo(
              Duration(
                milliseconds: (value.duration.inMilliseconds * fraction)
                    .round(),
              ),
            ),
          );
        },
      );
    }
    return _ScrubberView(progress: 0, position: '00:00', total: total);
  }

  static String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _ScrubberView extends StatelessWidget {
  const _ScrubberView({
    required this.progress,
    required this.position,
    required this.total,
    this.onSeek,
  });

  final double progress;
  final String position;
  final String total;
  final ValueChanged<double>? onSeek;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            void seek(Offset local) {
              if (onSeek == null || width == 0) return;
              onSeek!((local.dx / width).clamp(0.0, 1.0));
            }

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => seek(d.localPosition),
              onHorizontalDragUpdate: (d) => seek(d.localPosition),
              child: SizedBox(
                height: 16,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: RaroGradients.rainbow,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment(progress * 2 - 1, 0),
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(position, style: _timeStyle),
            Text(total, style: _timeStyle),
          ],
        ),
      ],
    );
  }

  static const TextStyle _timeStyle = TextStyle(
    fontFamily: RaroFonts.mono,
    fontSize: 11,
    color: Colors.white,
  );
}
