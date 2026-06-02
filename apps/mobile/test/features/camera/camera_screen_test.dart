import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/core/theme/raro_theme_data.dart';
import 'package:raro_mobile/features/camera/application/camera_shell_provider.dart';
import 'package:raro_mobile/features/camera/presentation/camera_screen.dart';
import 'package:raro_mobile/features/camera/presentation/widgets/lens_switcher.dart';
import 'package:raro_mobile/features/camera/presentation/widgets/rec_button.dart';

void main() {
  Widget harness({
    VoidCallback? onClose,
    VoidCallback? onGallery,
    VoidCallback? onSettings,
  }) {
    return ProviderScope(
      child: MaterialApp(
        theme: buildRaroDarkTheme(),
        home: CameraScreen(
          onClose: onClose ?? () {},
          onGallery: onGallery ?? () {},
          onSettings: onSettings ?? () {},
        ),
      ),
    );
  }

  group('CameraScreen', () {
    testWidgets('renderiza wordmark RARO e o REC button', (tester) async {
      await tester.pumpWidget(harness());
      expect(find.text('RARO'), findsOneWidget);
      expect(find.byType(RecButton), findsOneWidget);
    });

    testWidgets('mostra hint central quando idle', (tester) async {
      await tester.pumpWidget(harness());
      expect(find.text('DIGA “RARO” PARA GRAVAR'), findsOneWidget);
    });

    testWidgets('mostra HUD com resolução/fps/lens', (tester) async {
      await tester.pumpWidget(harness());
      expect(find.text('1080p · 60FPS · 1×'), findsOneWidget);
    });

    testWidgets('mostra a buffer pill Raro Replay 15s', (tester) async {
      await tester.pumpWidget(harness());
      expect(find.text('Raro Replay 15s'), findsOneWidget);
    });

    testWidgets('tap no REC alterna o estado de gravação', (tester) async {
      late WidgetRef capturedRef;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildRaroDarkTheme(),
            home: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                return CameraScreen(
                  onClose: () {},
                  onGallery: () {},
                  onSettings: () {},
                );
              },
            ),
          ),
        ),
      );

      expect(capturedRef.read(cameraShellProvider).recording, isFalse);
      await tester.tap(find.byType(RecButton));
      await tester.pump();
      expect(capturedRef.read(cameraShellProvider).recording, isTrue);
    });

    testWidgets('tap na lente 0.5× atualiza o provider', (tester) async {
      late WidgetRef capturedRef;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildRaroDarkTheme(),
            home: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                return CameraScreen(
                  onClose: () {},
                  onGallery: () {},
                  onSettings: () {},
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(LensSwitcher), findsOneWidget);
      await tester.tap(find.text('0.5×'));
      await tester.pump();
      expect(capturedRef.read(cameraShellProvider).lens, LensType.ultraWide);
    });

    testWidgets('tap em gallery e settings dispara callbacks', (tester) async {
      var gallery = false;
      var settings = false;
      await tester.pumpWidget(
        harness(
          onGallery: () => gallery = true,
          onSettings: () => settings = true,
        ),
      );

      await tester.tap(find.byKey(const Key('camera_gallery_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('camera_settings_button')));
      await tester.pump();

      expect(gallery, isTrue);
      expect(settings, isTrue);
    });
  });
}
