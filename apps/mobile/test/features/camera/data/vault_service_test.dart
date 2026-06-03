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
}
