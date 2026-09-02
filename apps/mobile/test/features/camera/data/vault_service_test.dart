import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/features/camera/data/vault_service.dart';
import 'package:raro_mobile/features/camera/domain/recording_metadata.dart';

void main() {
  late Directory tempRoot;
  late File source;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('vault_test_');
    source = File('${tempRoot.path}/src.mov')
      ..writeAsBytesSync(List.filled(2048, 7));
  });

  tearDown(() async {
    if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
  });

  RecordingMetadata meta(String id, {DateTime? at, bool replay = false}) =>
      RecordingMetadata(
        id: id,
        name: 'Vídeo $id',
        duration: const Duration(seconds: 5),
        recordedAt: at ?? DateTime(2026, 6, 3),
        isReplay: replay,
        thumbnailHue: 100,
      );

  test(
    'save copies file into vault and returns entity with filePath',
    () async {
      final service = VaultService(documentsDir: tempRoot);
      final entity = await service.save(source, metadata: meta('a1'));
      expect(entity.id, 'a1');
      expect(entity.filePath, endsWith('vault/a1.mp4'));
      expect(File(entity.filePath!).existsSync(), isTrue);
      expect(File(entity.filePath!).lengthSync(), 2048);
    },
  );

  test('listAll returns saved videos newest-first', () async {
    final service = VaultService(documentsDir: tempRoot);
    await service.save(source, metadata: meta('old', at: DateTime(2026, 1, 1)));
    await service.save(source, metadata: meta('new', at: DateTime(2026, 6, 1)));
    final all = await service.listAll();
    expect(all.map((v) => v.id).toList(), ['new', 'old']);
  });

  test('listAll on empty vault returns []', () async {
    final service = VaultService(documentsDir: tempRoot);
    expect(await service.listAll(), isEmpty);
  });

  test('delete removes the file and it disappears from listAll', () async {
    final service = VaultService(documentsDir: tempRoot);
    final e = await service.save(source, metadata: meta('d1'));
    await service.delete(e.id);
    expect(File(e.filePath!).existsSync(), isFalse);
    expect(await service.listAll(), isEmpty);
  });

  test(
    'thumbnailPath resolves to the real .jpg in the vault and preserves other fields',
    () async {
      final service = VaultService(documentsDir: tempRoot);
      await service.save(
        source,
        metadata: meta('t1', at: DateTime(2026, 5, 20), replay: true),
      );
      final thumb = File('${tempRoot.path}/vault/t1.jpg')
        ..writeAsBytesSync([0, 1, 2]);
      await service.attachThumbnail('t1', thumb.path);

      final entity = (await service.listAll()).single;
      expect(entity.thumbnailPath, endsWith('vault/t1.jpg'));
      expect(entity.id, 't1');
      expect(entity.name, 'Vídeo t1');
      expect(entity.isReplay, isTrue);
      expect(entity.thumbnailHue, 100);
      expect(entity.recordedAt, DateTime(2026, 5, 20));
      expect(entity.resolutionLabel, isNull);
      expect(entity.fpsLabel, isNull);
      expect(entity.lensLabel, isNull);
    },
  );

  test('thumbnailPath is recomputed from current vault dir, ignoring a stale '
      'absolute path in the sidecar (survives app reinstall)', () async {
    final service = VaultService(documentsDir: tempRoot);
    await service.save(source, metadata: meta('r1'));
    await service.attachThumbnail(
      'r1',
      '/var/mobile/Containers/Data/Application/OLD-UUID/Documents/vault/r1.jpg',
    );
    File('${tempRoot.path}/vault/r1.jpg').writeAsBytesSync([9, 9, 9]);

    final entity = (await service.listAll()).single;
    expect(entity.thumbnailPath, '${tempRoot.path}/vault/r1.jpg');
    expect(entity.thumbnailPath, isNot(contains('OLD-UUID')));
  });

  test('thumbnailPath is null when the .jpg is absent even if the sidecar '
      'stored a path (stale reference does not survive)', () async {
    final service = VaultService(documentsDir: tempRoot);
    await service.save(source, metadata: meta('s1'));
    await service.attachThumbnail('s1', '/old/container/vault/s1.jpg');

    expect((await service.listAll()).single.thumbnailPath, isNull);
  });

  test('attachThumbnail on missing metadata is a no-op (no throw)', () async {
    final service = VaultService(documentsDir: tempRoot);
    await service.attachThumbnail('ghost', '/vault/ghost.jpg');
    expect(await service.listAll(), isEmpty);
  });

  test('save round-trips resolution and fps labels in the sidecar', () async {
    final service = VaultService(documentsDir: tempRoot);
    await service.save(
      source,
      metadata: RecordingMetadata(
        id: 'fmt1',
        name: 'Vídeo fmt1',
        duration: const Duration(seconds: 5),
        recordedAt: DateTime(2026, 6, 3),
        isReplay: false,
        thumbnailHue: 100,
        resolutionLabel: '4K',
        fpsLabel: '30FPS',
        lensLabel: '0.5×',
      ),
    );
    final entity = (await service.listAll()).single;
    expect(entity.resolutionLabel, '4K');
    expect(entity.fpsLabel, '30FPS');
    expect(entity.lensLabel, '0.5×');
  });

  test('saved video without thumbnail has null thumbnailPath', () async {
    final service = VaultService(documentsDir: tempRoot);
    final entity = await service.save(source, metadata: meta('n1'));
    expect(entity.thumbnailPath, isNull);
    expect((await service.listAll()).single.thumbnailPath, isNull);
  });

  test('delete removes the thumbnail .jpg alongside the video', () async {
    final service = VaultService(documentsDir: tempRoot);
    await service.save(source, metadata: meta('d2'));
    final thumb = File('${tempRoot.path}/vault/d2.jpg')
      ..writeAsBytesSync([0, 1, 2]);
    await service.attachThumbnail('d2', thumb.path);

    await service.delete('d2');

    expect(thumb.existsSync(), isFalse);
  });
}
