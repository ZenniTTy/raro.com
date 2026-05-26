import 'package:flutter_test/flutter_test.dart';
import 'package:raro_shared/raro_shared.dart';

void main() {
  group('Family 8 — AppScreen + AppModal uniqueness', () {
    test('AppScreen paths are unique', () {
      final paths = AppScreen.values.map((s) => s.path).toList();
      expect(paths.toSet().length, paths.length);
    });

    test('AppScreen analyticsNames are unique', () {
      final names = AppScreen.values.map((s) => s.analyticsName).toList();
      expect(names.toSet().length, names.length);
    });

    test('AppModal analyticsNames are unique', () {
      final names = AppModal.values.map((m) => m.analyticsName).toList();
      expect(names.toSet().length, names.length);
    });
  });
}
