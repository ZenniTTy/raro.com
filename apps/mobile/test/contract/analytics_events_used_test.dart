import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Iterable<File> _scanDart(String root) sync* {
  final dir = Directory(root);
  if (!dir.existsSync()) return;
  for (final e in dir.listSync(recursive: true)) {
    if (e is File &&
        e.path.endsWith('.dart') &&
        !e.path.endsWith('.g.dart') &&
        !e.path.endsWith('.tailor.dart') &&
        !e.path.contains('/generated/')) {
      yield e;
    }
  }
}

void main() {
  group('Family 6 — analytics logEvent uses AnalyticsEvents.*', () {
    test('no logEvent with string literal name', () {
      final hits = <String>[];
      final pattern = RegExp(r"logEvent\s*\(\s*name:\s*'([^']+)'");
      for (final f in _scanDart('lib')) {
        final content = f.readAsStringSync();
        for (final m in pattern.allMatches(content)) {
          hits.add('${f.path}: ${m.group(1)}');
        }
      }
      expect(
        hits,
        isEmpty,
        reason: 'logEvent with literal:\n${hits.join("\n")}',
      );
    });
  });
}
