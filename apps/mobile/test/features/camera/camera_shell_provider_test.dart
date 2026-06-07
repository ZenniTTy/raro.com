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
    test('estado inicial: idle, lente wide', () {
      final container = makeContainer();
      final state = container.read(cameraShellProvider);

      expect(state.recording, isFalse);
      expect(state.lens, LensType.wide);
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
  });

  group('CameraShellState helpers', () {
    test('lensLabel (chips) usa × ; hudLensLabel (#hudLens) usa x ASCII', () {
      const wide = CameraShellState(recording: false, lens: LensType.wide);
      const ultra = CameraShellState(
        recording: false,
        lens: LensType.ultraWide,
      );

      expect(wide.lensLabel, '1×');
      expect(ultra.lensLabel, '0.5×');
      expect(wide.hudLensLabel, '1x');
      expect(ultra.hudLensLabel, '0.5x');
    });
  });
}
