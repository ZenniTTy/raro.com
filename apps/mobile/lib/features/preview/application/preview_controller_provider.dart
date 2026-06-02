import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:video_player/video_player.dart';

part 'preview_controller_provider.g.dart';

@riverpod
Future<VideoPlayerController> previewController(
  Ref ref,
  String assetPath,
) async {
  final controller = VideoPlayerController.asset(assetPath);
  ref.onDispose(controller.dispose);
  await controller.initialize();
  await controller.setLooping(true);
  return controller;
}
