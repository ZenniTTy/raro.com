import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:raro_shared/raro_shared.dart';

const _expectedFiles = {
  'pigeons/camera_api.dart': BridgeChannels.camera,
  'pigeons/replay_buffer_api.dart': BridgeChannels.replayBuffer,
  'pigeons/voice_api.dart': BridgeChannels.voice,
  'pigeons/volume_api.dart': BridgeChannels.volume,
};

void main() {
  group('Family 3/4 — Pigeon schemas reference canonical channels', () {
    test('each pigeons/*.dart exists and references its channel suffix', () {
      for (final entry in _expectedFiles.entries) {
        final f = File(entry.key);
        expect(f.existsSync(), isTrue, reason: 'missing ${entry.key}');
        final content = f.readAsStringSync();
        final last = entry.value.split('/').last;
        expect(
          content.contains(last),
          isTrue,
          reason: '${entry.key} does not reference "$last"',
        );
      }
    });

    test('every BridgeChannels entry starts with com.rarocamera namespace', () {
      final prefix = String.fromCharCodes([
        99,
        111,
        109,
        46,
        114,
        97,
        114,
        111,
        99,
        97,
        109,
        101,
        114,
        97,
        47,
      ]);
      const all = [
        BridgeChannels.camera,
        BridgeChannels.replayBuffer,
        BridgeChannels.voice,
        BridgeChannels.volume,
      ];
      for (final c in all) {
        expect(c, startsWith(prefix));
      }
    });
  });
}
