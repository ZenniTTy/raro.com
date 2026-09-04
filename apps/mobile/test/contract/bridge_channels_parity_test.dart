import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:raro_shared/raro_shared.dart';

const _expectedFiles = {
  'pigeons/camera_api.dart': BridgeChannels.camera,
  'pigeons/replay_buffer_api.dart': BridgeChannels.replayBuffer,
  'pigeons/voice_api.dart': BridgeChannels.voice,
  'pigeons/volume_api.dart': BridgeChannels.volume,
  'pigeons/gallery_api.dart': BridgeChannels.gallery,
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
        BridgeChannels.gallery,
      ];
      for (final c in all) {
        expect(c, startsWith(prefix));
      }
    });
  });

  group('Family 3/4 — camera_preview PlatformView registration parity', () {
    test('iOS AppDelegate registers cameraPreview viewType', () {
      final iosFile = File('ios/Runner/AppDelegate.swift').readAsStringSync();
      expect(
        iosFile.contains(BridgeChannels.cameraPreview),
        isTrue,
        reason:
            'ios/Runner/AppDelegate.swift must register PlatformView with viewType ${BridgeChannels.cameraPreview}',
      );
    });

    test('Android MainActivity registers cameraPreview viewType', () {
      final androidFile = File(
        'android/app/src/main/kotlin/com/rarocamera/raro_mobile/MainActivity.kt',
      ).readAsStringSync();
      expect(
        androidFile.contains(BridgeChannels.cameraPreview),
        isTrue,
        reason:
            'MainActivity.kt must register PlatformView with viewType ${BridgeChannels.cameraPreview}',
      );
    });

    test('BridgeChannels.cameraPreview matches canonical native string', () {
      expect(
        BridgeChannels.cameraPreview,
        'com.rarocamera/camera_preview',
        reason:
            'Shared constant must equal native viewType string (single source of truth)',
      );
    });
  });
}
