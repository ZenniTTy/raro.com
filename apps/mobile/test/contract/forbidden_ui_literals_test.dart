import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _excludedSuffixes = ['.g.dart', '.tailor.dart', '.freezed.dart'];

const _excludedFiles = ['camera_test_harness_screen.dart'];

const _allowedLiterals = <String>{
  'RARO',
  'RARO · CAPTURE UNSCRIPTED',
  'CAPTURE · UNSCRIPTED',
  'Raro Replay',
  'Raro Replay s',
  'REC',
  'ON',
  'OFF',
  'PT',
  'ES',
  'EN',
  '🇧🇷',
  '🇪🇸',
  '🇺🇸',
  'FPS',
  '30 FPS',
  '60 FPS',
  '15s',
  '30s',
  '0.5×',
  '1×',
  '00:00',
  '1.0.0 · build 23',
  '720p HD',
  '1080p Full HD',
  '4K Ultra HD',
  '4K 60fps',
  '  ·  ',
};

final _textLiteral = RegExp(
  'Text(?:\\.rich)?\\(\\s*[\'"]([^\'"]+)[\'"]',
  multiLine: true,
);

final _hasLetter = RegExp('[A-Za-zÀ-ú]');

bool _isExcluded(String path) {
  for (final s in _excludedSuffixes) {
    if (path.endsWith(s)) return true;
  }
  for (final f in _excludedFiles) {
    if (path.endsWith(f)) return true;
  }
  return false;
}

final _interpolation = RegExp(r'\$\{[^}]*\}|\$[A-Za-z_][A-Za-z0-9_.]*');

bool _isAllowed(String literal) {
  if (_allowedLiterals.contains(literal)) return true;
  final withoutInterpolations = literal
      .replaceAll(_interpolation, '')
      .replaceAll(RegExp(r'[\s·]+$'), '')
      .trim();
  if (_allowedLiterals.contains(withoutInterpolations)) return true;
  return !_hasLetter.hasMatch(withoutInterpolations);
}

final _constStringList = RegExp(
  r'static const \w+ = (?:<String>)?\[([^\]]*)\]',
  multiLine: true,
  dotAll: true,
);

final _quotedString = RegExp('''['"]([^'"]+)['"]''');

void main() {
  group('Family i18n — UI literals fora do arb', () {
    test('presentation não contém lista const de strings traduzíveis', () {
      final hits = <String>[];
      final root = Directory('lib/features');
      for (final entity in root.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (!entity.path.contains('/presentation/')) continue;
        if (_isExcluded(entity.path)) continue;
        final content = entity.readAsStringSync();
        for (final list in _constStringList.allMatches(content)) {
          for (final match in _quotedString.allMatches(list.group(1)!)) {
            final literal = match.group(1)!;
            if (!_isAllowed(literal)) {
              hits.add('${entity.path}: $literal');
            }
          }
        }
      }
      expect(
        hits,
        isEmpty,
        reason:
            'lista const com literal de UI fora do arb:\n${hits.join("\n")}',
      );
    });

    test('presentation não contém Text literal traduzível fora do arb', () {
      final hits = <String>[];
      final root = Directory('lib/features');
      for (final entity in root.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (!entity.path.contains('/presentation/')) continue;
        if (_isExcluded(entity.path)) continue;
        final content = entity.readAsStringSync();
        for (final match in _textLiteral.allMatches(content)) {
          final literal = match.group(1)!;
          if (!_isAllowed(literal)) {
            hits.add('${entity.path}: $literal');
          }
        }
      }
      expect(
        hits,
        isEmpty,
        reason:
            'literal de UI fora do arb (migrar para AppLocalizations):\n'
            '${hits.join("\n")}',
      );
    });
  });
}
