import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/application/camera_shell_provider.dart';
import 'package:raro_mobile/features/camera/domain/camera_shell_state.dart';

void main() {
  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  group('CameraShell', () {
    test('estado inicial: idle, lente wide, buffer 15s', () {
      final container = makeContainer();
      final state = container.read(cameraShellProvider);

      expect(state.recording, isFalse);
      expect(state.lens, LensType.wide);
      expect(state.bufferDuration, BufferDuration.fifteenSec);
    });

    test('toggleRecording alterna recording para true', () {
      final container = makeContainer();
      final notifier = container.read(cameraShellProvider.notifier);

      notifier.toggleRecording();

      expect(container.read(cameraShellProvider).recording, isTrue);
    });

    test('toggleRecording duas vezes volta para idle', () {
      final container = makeContainer();
      final notifier = container.read(cameraShellProvider.notifier);

      notifier.toggleRecording();
      notifier.toggleRecording();

      expect(container.read(cameraShellProvider).recording, isFalse);
    });

    test('selectLens muda a lente ativa', () {
      final container = makeContainer();
      final notifier = container.read(cameraShellProvider.notifier);

      notifier.selectLens(LensType.ultraWide);

      expect(container.read(cameraShellProvider).lens, LensType.ultraWide);
    });

    test('toggleBufferDuration alterna 15s → 30s → 15s', () {
      final container = makeContainer();
      final notifier = container.read(cameraShellProvider.notifier);

      notifier.toggleBufferDuration();
      expect(
        container.read(cameraShellProvider).bufferDuration,
        BufferDuration.thirtySec,
      );

      notifier.toggleBufferDuration();
      expect(
        container.read(cameraShellProvider).bufferDuration,
        BufferDuration.fifteenSec,
      );
    });
  });

  group('CameraShellState helpers', () {
    test('lensLabel (chips) usa × ; hudLensLabel (#hudLens) usa x ASCII', () {
      const wide = CameraShellState(
        recording: false,
        lens: LensType.wide,
        bufferDuration: BufferDuration.fifteenSec,
      );
      const ultra = CameraShellState(
        recording: false,
        lens: LensType.ultraWide,
        bufferDuration: BufferDuration.fifteenSec,
      );

      expect(wide.lensLabel, '1×');
      expect(ultra.lensLabel, '0.5×');
      expect(wide.hudLensLabel, '1x');
      expect(ultra.hudLensLabel, '0.5x');
    });

    test('bufferSeconds: 15 / 30', () {
      expect(BufferDuration.fifteenSec.seconds, 15);
      expect(BufferDuration.thirtySec.seconds, 30);
    });
  });
}
