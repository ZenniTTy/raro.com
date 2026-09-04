import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raro_mobile/core/subscription/billing_gateway.dart';
import 'package:raro_mobile/features/camera/application/pending_recording_controller.dart';
import 'package:raro_mobile/features/camera/application/persist_recording_scope.dart';
import 'package:raro_mobile/features/camera/data/camera_repository.dart';
import 'package:raro_mobile/features/camera/data/camera_repository_provider.dart';
import 'package:raro_mobile/features/camera/data/vault_service.dart';
import 'package:raro_mobile/features/camera/data/vault_service_provider.dart';
import 'package:raro_mobile/features/camera/domain/pending_clip.dart';
import 'package:raro_mobile/features/camera/domain/recording_metadata.dart';
import 'package:raro_mobile/features/gallery/data/system_gallery_exporter_provider.dart';
import 'package:raro_mobile/features/paywall/application/subscription_controller.dart';

import '../../../helpers/fake_billing_gateway.dart';
import '../../../helpers/fake_system_gallery_exporter.dart';

class _MockCameraRepository extends Mock implements CameraRepository {}

final persistPendingProbeProvider = FutureProvider<PersistPendingResult>(
  (ref) => persistPendingForRef(ref),
);

void main() {
  late Directory tempRoot;
  late File source;
  late _MockCameraRepository thumbnails;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('persist_pending_');
    source = File('${tempRoot.path}/raro_clip1.mp4')
      ..writeAsBytesSync(List.filled(256, 4));
    thumbnails = _MockCameraRepository();
    when(
      () => thumbnails.generateThumbnail(any()),
    ).thenAnswer((_) async => '${tempRoot.path}/vault/clip1.jpg');
  });

  tearDown(() {
    if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
  });

  PendingClip clip() {
    return PendingClip(
      path: source.path,
      metadata: RecordingMetadata(
        id: 'clip1',
        name: 'Vídeo 09:41',
        duration: const Duration(seconds: 5),
        recordedAt: DateTime(2026, 9, 4, 9, 41),
        isReplay: false,
        thumbnailHue: 20,
      ),
    );
  }

  ProviderContainer makeContainer(BillingGateway billing) {
    final container = ProviderContainer(
      overrides: [
        pendingRecordingProvider.overrideWith(PendingRecording.new),
        billingGatewayProvider.overrideWithValue(billing),
        vaultServiceProvider.overrideWith(
          (ref) => VaultService(documentsDir: tempRoot),
        ),
        systemGalleryExporterProvider.overrideWithValue(
          FakeSystemGalleryExporter(),
        ),
        cameraRepositoryProvider.overrideWithValue(thumbnails),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('sem pending devolve Absent', () async {
    final container = makeContainer(FakeBillingGateway(premium: true));
    final result = await container.read(persistPendingProbeProvider.future);
    expect(result, isA<PersistPendingAbsent>());
  });

  test('billing indisponível devolve Failed, não Saved', () async {
    final container = makeContainer(UnconfiguredBillingGateway());
    container.read(pendingRecordingProvider.notifier).replace(clip());
    final result = await container.read(persistPendingProbeProvider.future);
    expect(result, isA<PersistPendingFailed>());
    expect(container.read(pendingRecordingProvider)?.id, 'clip1');
  });

  test('free devolve NeedsPremium', () async {
    final container = makeContainer(FakeBillingGateway());
    container.read(pendingRecordingProvider.notifier).replace(clip());
    final result = await container.read(persistPendingProbeProvider.future);
    expect(result, isA<PersistPendingNeedsPremium>());
    expect(container.read(pendingRecordingProvider)?.id, 'clip1');
  });

  test('premium devolve Saved e limpa o pending', () async {
    final container = makeContainer(FakeBillingGateway(premium: true));
    container.read(pendingRecordingProvider.notifier).replace(clip());
    final result = await container.read(persistPendingProbeProvider.future);
    expect(result, isA<PersistPendingSaved>());
    expect((result as PersistPendingSaved).id, 'clip1');
    expect(container.read(pendingRecordingProvider), isNull);
  });
}
