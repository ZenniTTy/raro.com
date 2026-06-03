import 'package:raro_shared/raro_shared.dart';
import 'package:test/test.dart';

void main() {
  test('Codec has h264 and h265 with stable labels', () {
    expect(Codec.h264.label, 'h264');
    expect(Codec.h265.label, 'h265');
    expect(Codec.values, hasLength(2));
  });

  test('Codec.fromLabel round-trips', () {
    for (final c in Codec.values) {
      expect(Codec.fromLabel(c.label), c);
    }
  });
}
