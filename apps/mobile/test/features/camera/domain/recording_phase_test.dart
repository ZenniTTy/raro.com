import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/features/camera/domain/recording_phase.dart';

void main() {
  test('idle aceita start e recusa stop', () {
    const phase = RecordingIdle();
    expect(phase.acceptsStart, isTrue);
    expect(phase.acceptsStop, isFalse);
  });

  test(
    'starting recusa start e stop (freeze do replay / handshake nativo)',
    () {
      const phase = RecordingStarting();
      expect(phase.acceptsStart, isFalse);
      expect(phase.acceptsStop, isFalse);
    },
  );

  test('active recusa start e aceita stop', () {
    final phase = RecordingActive(
      sessionId: 's-1',
      startedAt: DateTime(2026, 9, 6, 21, 15),
    );
    expect(phase.acceptsStart, isFalse);
    expect(phase.acceptsStop, isTrue);
  });
}
