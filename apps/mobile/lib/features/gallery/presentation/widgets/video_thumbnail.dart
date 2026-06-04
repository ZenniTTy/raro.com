import 'dart:io';

import 'package:flutter/material.dart';
import 'package:raro_mobile/core/theme/raro_fonts.dart';
import 'package:raro_mobile/core/theme/raro_gradients.dart';
import 'package:raro_mobile/core/theme/raro_theme.dart';
import 'package:raro_mobile/features/gallery/domain/video_entity.dart';

class VideoThumbnail extends StatelessWidget {
  const VideoThumbnail({super.key, required this.video, required this.onTap});

  final VideoEntity video;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    final base = HSLColor.fromAHSL(
      1,
      video.thumbnailHue.toDouble(),
      0.7,
      0.4,
    ).toColor();
    final thumbnailPath = video.thumbnailPath;
    final hasThumbnail =
        thumbnailPath != null && File(thumbnailPath).existsSync();
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: colors.bgElev),
              if (hasThumbnail)
                Image.file(
                  File(thumbnailPath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) =>
                      _GradientFallback(base: base),
                )
              else
                _GradientFallback(base: base),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.black54,
                      Colors.transparent,
                      Colors.black54,
                    ],
                    stops: [0, 0.5, 1],
                  ),
                ),
              ),
              const Center(
                child: Icon(
                  Icons.play_arrow_rounded,
                  size: 26,
                  color: Colors.white,
                ),
              ),
              Positioned(
                right: 6,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    video.formattedDuration,
                    style: const TextStyle(
                      fontFamily: RaroFonts.mono,
                      fontSize: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (video.isReplay)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      gradient: RaroGradients.rainbow,
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientFallback extends StatelessWidget {
  const _GradientFallback({required this.base});

  final Color base;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        backgroundBlendMode: BlendMode.screen,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base.withValues(alpha: 0.55), base.withValues(alpha: 0.25)],
        ),
      ),
    );
  }
}
