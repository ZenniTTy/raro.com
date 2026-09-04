import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raro_mobile/core/subscription/billing_gateway.dart';
import 'package:raro_mobile/features/camera/application/persist_outcome.dart';
import 'package:raro_mobile/features/camera/application/persist_recording.dart';
import 'package:raro_mobile/features/camera/data/camera_repository.dart';
import 'package:raro_mobile/features/camera/data/vault_service.dart';
import 'package:raro_mobile/features/camera/domain/pending_clip.dart';
import 'package:raro_mobile/features/camera/domain/recording_metadata.dart';

import '../../../helpers/fake_billing_gateway.dart';
import '../../../helpers/fake_system_gallery_exporter.dart';

class _MockCameraRepository extends Mock implements CameraRepository {}

void main() {
  late Directory tempRoot;
  late File source;
  late VaultService vault;
  late FakeSystemGalleryExporter gallery;
  late _MockCameraRepository thumbnails;
  late PendingClip clip;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('persist_recording_');
    source = File('${tempRoot.path}/raro_clip1.mp4')
      ..writeAsBytesSync(List.filled(256, 4));
    vault = VaultService(documentsDir: tempRoot);
    gallery = FakeSystemGalleryExporter();
    thumbnails = _MockCameraRepository();
    when(
      () => thumbnails.generateThumbnail(any()),
    ).thenAnswer((_) async => '${tempRoot.path}/vault/clip1.jpg');
    clip = PendingClip(
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
  });

  tearDown(() {
    if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
  });

  PersistRecording persist({required BillingGateway billing}) {
    return PersistRecording(
      billing: billing,
      vault: vault,
      gallery: gallery,
      thumbnails: thumbnails,
      logger: Logger(level: Level.off),
    );
  }

  test('free returns NeedsPremium, keeps source, vault empty', () async {
    final outcome = await persist(billing: FakeBillingGateway())(clip);

    expect(outcome, isA<PersistNeedsPremium>());
    expect(source.existsSync(), isTrue);
    expect(await vault.listAll(), isEmpty);
    expect(gallery.exported, isEmpty);
    verifyNever(() => thumbnails.generateThumbnail(any()));
  });

  test('premium copies to vault, exports gallery, deletes temp', () async {
    final outcome = await persist(billing: FakeBillingGateway(premium: true))(
      clip,
    );

    expect(outcome, isA<PersistSucceeded>());
    final succeeded = outcome as PersistSucceeded;
    expect(succeeded.galleryExported, isTrue);
    expect(source.existsSync(), isFalse);
    final videos = await vault.listAll();
    expect(videos.single.id, 'clip1');
    expect(File(videos.single.filePath!).existsSync(), isTrue);
    expect(gallery.exported.single, videos.single.filePath);
    verify(() => thumbnails.generateThumbnail(any())).called(1);
  });

  test('gallery failure still succeeds and keeps vault copy', () async {
    gallery.fail = true;
    final outcome = await persist(billing: FakeBillingGateway(premium: true))(
      clip,
    );

    expect(outcome, isA<PersistSucceeded>());
    expect((outcome as PersistSucceeded).galleryExported, isFalse);
    expect(await vault.listAll(), isNotEmpty);
    expect(source.existsSync(), isFalse);
  });

  test('vault failure does not delete source or call gallery', () async {
    await source.delete();
    final outcome = await persist(billing: FakeBillingGateway(premium: true))(
      clip,
    );

    expect(outcome, isA<PersistFailed>());
    expect(gallery.exported, isEmpty);
    expect(await vault.listAll(), isEmpty);
  });

  test('billing unavailable does not save or delete source', () async {
    final outcome = await persist(billing: UnconfiguredBillingGateway())(clip);

    expect(outcome, isA<PersistFailed>());
    expect(source.existsSync(), isTrue);
    expect(await vault.listAll(), isEmpty);
    expect(gallery.exported, isEmpty);
  });

  test('thumbnail throw still returns Succeeded', () async {
    when(
      () => thumbnails.generateThumbnail(any()),
    ).thenThrow(Exception('android stub'));
    final outcome = await persist(billing: FakeBillingGateway(premium: true))(
      clip,
    );

    expect(outcome, isA<PersistSucceeded>());
    expect(await vault.listAll(), isNotEmpty);
    expect(source.existsSync(), isFalse);
  });
}
