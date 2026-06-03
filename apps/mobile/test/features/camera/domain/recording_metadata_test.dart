import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/features/camera/domain/recording_metadata.dart';

void main() {
  test('RecordingMetadata holds all fields', () {
    final at = DateTime(2026, 6, 3, 14, 30);
    const id = 'abc';
    final m = RecordingMetadata(
      id: id,
      name: 'Vídeo 14:30',
      duration: const Duration(seconds: 12),
      recordedAt: at,
      isReplay: false,
      thumbnailHue: 200,
    );
    expect(m.id, id);
    expect(m.name, 'Vídeo 14:30');
    expect(m.duration, const Duration(seconds: 12));
    expect(m.recordedAt, at);
    expect(m.isReplay, isFalse);
    expect(m.thumbnailHue, 200);
  });
}
