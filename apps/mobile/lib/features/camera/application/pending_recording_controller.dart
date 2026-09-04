import 'dart:io';

import 'package:raro_mobile/core/logging/app_logger.dart';
import 'package:raro_mobile/features/camera/domain/pending_clip.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pending_recording_controller.g.dart';

@Riverpod(keepAlive: true)
class PendingRecording extends _$PendingRecording {
  @override
  PendingClip? build() => null;

  void replace(PendingClip clip) => state = clip;

  void clearKept() => state = null;

  Future<void> discard() async {
    final clip = state;
    state = null;
    if (clip == null) return;
    try {
      final file = File(clip.path);
      if (await file.exists()) {
        await file.delete();
      }
    } on Object catch (error) {
      ref
          .read(appLoggerProvider)
          .w('pending discard failed id=${clip.id} error=$error');
    }
  }
}
