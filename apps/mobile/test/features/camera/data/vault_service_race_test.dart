import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/features/camera/data/vault_service.dart';
import 'package:raro_mobile/features/camera/domain/recording_metadata.dart';

void main() {
  late Directory tempRoot;
  late VaultService vault;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('vault_race_test_');
    vault = VaultService(documentsDir: tempRoot);
  });

  tearDown(() {
    if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
  });

  RecordingMetadata meta(String id) => RecordingMetadata(
    id: id,
    name: 'Vídeo $id',
    duration: const Duration(seconds: 5),
    recordedAt: DateTime.now(),
    isReplay: false,
    thumbnailHue: 120,
  );

  test('concurrent save and listAll never throws FormatException', () async {
    final source = File('${tempRoot.path}/src.mp4')
      ..writeAsBytesSync(List.filled(512, 1));
    await vault.save(source, metadata: meta('seed'));

    Object? caught;
    final futures = <Future<void>>[];
    for (var i = 0; i < 40; i++) {
      futures.add(vault.save(source, metadata: meta('id$i')));
      futures.add(() async {
        try {
          await vault.listAll();
        } on FormatException catch (e) {
          caught = e;
        }
      }());
    }
    await Future.wait(futures);
    expect(
      caught,
      isNull,
      reason: 'listAll leu um sidecar parcial durante a escrita',
    );
  });

  test('no orphan .json.tmp remains after writes', () async {
    final source = File('${tempRoot.path}/src.mp4')
      ..writeAsBytesSync(List.filled(512, 1));
    for (var i = 0; i < 20; i++) {
      await vault.save(source, metadata: meta('id$i'));
    }
    final vaultDir = Directory('${tempRoot.path}/vault');
    final tmps = vaultDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json.tmp'))
        .toList();
    expect(tmps, isEmpty);
  });

  test('listAll skips an orphan partial .json.tmp without throwing', () async {
    final source = File('${tempRoot.path}/src.mp4')
      ..writeAsBytesSync(List.filled(512, 1));
    await vault.save(source, metadata: meta('done'));

    final vaultDir = Directory('${tempRoot.path}/vault');
    File('${vaultDir.path}/crashed.json.tmp').writeAsStringSync('{"id":"cra');

    final entities = await vault.listAll();

    expect(
      entities.map((e) => e.id),
      ['done'],
      reason:
          'o .json.tmp orfao de uma escrita interrompida deve ser filtrado por '
          'listAll (complemento do tmp+rename), nunca decodificado como sidecar',
    );
  });
}
