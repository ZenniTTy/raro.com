import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raro_mobile/features/camera/data/camera_repository.dart';
import 'package:raro_mobile/features/camera/data/camera_repository_provider.dart';
import 'package:raro_mobile/features/camera/data/vault_service.dart';
import 'package:raro_mobile/features/camera/data/vault_service_provider.dart';
import 'package:raro_mobile/features/gallery/data/system_gallery_exporter_provider.dart';
import 'package:raro_mobile/features/paywall/application/subscription_controller.dart';
import 'package:raro_mobile/features/replay/application/replay_flutter_api_provider.dart';
import 'package:raro_mobile/features/replay/application/replay_vault_sink.dart';

import '../../helpers/fake_billing_gateway.dart';
import '../../helpers/fake_system_gallery_exporter.dart';

class _MockCameraRepository extends Mock implements CameraRepository {}

void main() {
  test(
    'disposing the container mid-save does not throw ref-after-dispose',
    () async {
      final tempRoot = await Directory.systemTemp.createTemp('replay_dispose_');
      addTearDown(() {
        if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
      });
      final saved = File('${tempRoot.path}/raro_replay_y.mp4')
        ..writeAsBytesSync(List.filled(512, 3));
      final events = StreamController<ReplayResult>.broadcast();
      addTearDown(events.close);

      final thumbnailDone = Completer<void>();
      final repository = _MockCameraRepository();
      when(() => repository.generateThumbnail(any())).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        if (!thumbnailDone.isCompleted) thumbnailDone.complete();
        return '${tempRoot.path}/vault/y.jpg';
      });

      final uncaught = <Object>[];
      await runZonedGuarded(() async {
        final container = ProviderContainer(
          overrides: [
            replayEventsProvider.overrideWithValue(events.stream),
            vaultServiceProvider.overrideWith(
              (ref) async => VaultService(documentsDir: tempRoot),
            ),
            cameraRepositoryProvider.overrideWithValue(repository),
            billingGatewayProvider.overrideWithValue(
              FakeBillingGateway(premium: true),
            ),
            systemGalleryExporterProvider.overrideWithValue(
              FakeSystemGalleryExporter(),
            ),
          ],
        );
        container.read(replayVaultSinkProvider);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        events.add(ReplayResult.saved(path: saved.path, durationMs: 15000));
        await Future<void>.delayed(const Duration(milliseconds: 15));
        container.dispose();
        await thumbnailDone.future;
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }, (error, _) => uncaught.add(error));

      expect(
        uncaught,
        isEmpty,
        reason: 'ref used after container dispose: $uncaught',
      );
    },
  );
}
