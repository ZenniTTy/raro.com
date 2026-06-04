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
      expect(entity.filePath, endsWith('vault/a1.mov'));
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
    'attachThumbnail persists thumbnailPath and preserves other fields',
    () async {
      final service = VaultService(documentsDir: tempRoot);
      await service.save(
        source,
        metadata: meta('t1', at: DateTime(2026, 5, 20), replay: true),
      );

      await service.attachThumbnail('t1', '/vault/t1.jpg');

      final entity = (await service.listAll()).single;
      expect(entity.thumbnailPath, '/vault/t1.jpg');
      expect(entity.id, 't1');
      expect(entity.name, 'Vídeo t1');
      expect(entity.isReplay, isTrue);
      expect(entity.thumbnailHue, 100);
      expect(entity.recordedAt, DateTime(2026, 5, 20));
    },
  );

  test('attachThumbnail on missing metadata is a no-op (no throw)', () async {
    final service = VaultService(documentsDir: tempRoot);
    await service.attachThumbnail('ghost', '/vault/ghost.jpg');
    expect(await service.listAll(), isEmpty);
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
