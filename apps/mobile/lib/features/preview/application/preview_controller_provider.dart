import 'dart:io';

import 'package:raro_mobile/features/gallery/domain/video_entity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:video_player/video_player.dart';

part 'preview_controller_provider.g.dart';

const String _fallbackAsset = 'assets/sample_videos/sample_preview.mp4';

@riverpod
Future<VideoPlayerController> previewController(
  Ref ref,
  VideoEntity video,
) async {
  final path = video.filePath;
  final hasFile = path != null && path.isNotEmpty && File(path).existsSync();
  final controller = hasFile
      ? VideoPlayerController.file(File(path))
      : VideoPlayerController.asset(_fallbackAsset);
  ref.onDispose(controller.dispose);
  await controller.initialize();
  await controller.setLooping(true);
  return controller;
}
