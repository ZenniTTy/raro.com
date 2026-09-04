import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/application/camera_flutter_api_provider.dart';
import 'package:raro_mobile/features/camera/application/pending_recording_controller.dart';
import 'package:raro_mobile/features/camera/data/vault_service.dart';
import 'package:raro_mobile/features/camera/data/vault_service_provider.dart';

void main() {
  late Directory tempRoot;
  late File recorded;
  late StreamController<RecordingResult> events;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('vault_sink_test_');
    recorded = File('${tempRoot.path}/raro_sess1.mov')
      ..writeAsBytesSync(List.filled(1024, 9));
    events = StreamController<RecordingResult>.broadcast();
  });

  tearDown(() async {
    await events.close();
    if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        recordingEventsProvider.overrideWithValue(events.stream),
        vaultServiceProvider.overrideWith(
          (ref) async => VaultService(documentsDir: tempRoot),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('RecordingFinished becomes pending and does not vault', () async {
    final container = makeContainer();
    container.read(recordingVaultSinkProvider);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    events.add(RecordingResult.finished(path: recorded.path, durationMs: 5000));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(await VaultService(documentsDir: tempRoot).listAll(), isEmpty);
    expect(container.read(pendingRecordingProvider)?.id, 'sess1');
    expect(recorded.existsSync(), isTrue);
  });

  test('RecordingFailed does not save anything', () async {
    final container = makeContainer();
    container.read(recordingVaultSinkProvider);

    events.add(
      const RecordingResult.failed(code: CameraErrorCode.sessionFailed),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(await VaultService(documentsDir: tempRoot).listAll(), isEmpty);
    expect(container.read(pendingRecordingProvider), isNull);
  });
}
