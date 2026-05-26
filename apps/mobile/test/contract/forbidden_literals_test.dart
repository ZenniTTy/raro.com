import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:raro_shared/raro_shared.dart';

const _excludedSuffixes = ['.g.dart', '.tailor.dart', '.freezed.dart'];

bool _isExcluded(String path) {
  for (final s in _excludedSuffixes) {
    if (path.endsWith(s)) return true;
  }
  return path.contains('/generated/');
}

Iterable<File> _scanDart(String rootRelative) sync* {
  final dir = Directory(rootRelative);
  if (!dir.existsSync()) return;
  for (final e in dir.listSync(recursive: true)) {
    if (e is File && e.path.endsWith('.dart') && !_isExcluded(e.path)) {
      yield e;
    }
  }
}

void main() {
  group('Family 2/12 — forbidden terms', () {
    test(
      'no forbidden term variant in lib or shared (outside canonical sources)',
      () {
        final hits = <String>[];
        for (final f in [
          ..._scanDart('lib'),
          ..._scanDart('../../packages/shared/lib'),
        ]) {
          if (f.path.contains('forbidden_terms.dart')) continue;
          final content = f.readAsStringSync();
          for (final term in ForbiddenTerms.all) {
            if (content.contains(term)) hits.add('${f.path}: $term');
          }
        }
        expect(
          hits,
          isEmpty,
          reason: 'forbidden term found:\n${hits.join("\n")}',
        );
      },
    );
  });

  group('Family 3 — channel literal isolation', () {
    test('no channel literal outside canonical bridges/ source', () {
      final marker = String.fromCharCodes([
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
      final hits = <String>[];
      for (final f in _scanDart('../../packages/shared/lib')) {
        if (f.path.contains('/bridges/')) continue;
        if (f.readAsStringSync().contains(marker)) hits.add(f.path);
      }
      for (final f in _scanDart('lib')) {
        final c = f.readAsStringSync();
        if (c.contains("'$marker") || c.contains('"$marker')) hits.add(f.path);
      }
      expect(
        hits,
        isEmpty,
        reason: 'channel literal outside canonical source:\n${hits.join("\n")}',
      );
    });
  });

  group('Family 2 — SKU literal isolation', () {
    test('no SKU prefix literal outside canonical subscription/ source', () {
      final marker = String.fromCharCodes([
        114,
        97,
        114,
        111,
        95,
        112,
        114,
        101,
        109,
        105,
        117,
        109,
        95,
      ]);
      final hits = <String>[];
      for (final f in _scanDart('../../packages/shared/lib')) {
        if (f.path.contains('/subscription/')) continue;
        if (f.readAsStringSync().contains(marker)) hits.add(f.path);
      }
      for (final f in _scanDart('lib')) {
        if (f.readAsStringSync().contains(marker)) hits.add(f.path);
      }
      expect(
        hits,
        isEmpty,
        reason: 'SKU literal outside canonical source:\n${hits.join("\n")}',
      );
    });
  });

  group('Family 11 — hex color isolation', () {
    test('no Color(0xFF...) outside core/theme/', () {
      final pattern = RegExp(r'Color\(0x[0-9A-Fa-f]{8}\)');
      final hits = <String>[];
      for (final f in _scanDart('lib')) {
        if (f.path.contains('/core/theme/')) continue;
        if (pattern.hasMatch(f.readAsStringSync())) hits.add(f.path);
      }
      expect(
        hits,
        isEmpty,
        reason: 'hex color outside core/theme:\n${hits.join("\n")}',
      );
    });
  });
}
