import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('iOS — pbxproj parity (Native/** Swift files)', () {
    final pbxprojFile = File('ios/Runner.xcodeproj/project.pbxproj');
    final nativeDir = Directory('ios/Runner/Native');

    if (!pbxprojFile.existsSync() || !nativeDir.existsSync()) {
      test('preconditions exist', () {
        fail(
          'Expected pbxproj at ${pbxprojFile.path} and dir ${nativeDir.path}',
        );
      });
      return;
    }

    final pbxproj = pbxprojFile.readAsStringSync();
    final swiftFiles = nativeDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.swift'))
        .where(
          (f) => !f.path.contains(
            '${Platform.pathSeparator}Generated${Platform.pathSeparator}',
          ),
        )
        .toList();

    for (final file in swiftFiles) {
      final basename = file.uri.pathSegments.last;
      test('$basename has PBXFileReference entry', () {
        expect(
          pbxproj,
          contains(basename),
          reason:
              'Swift file $basename exists on disk under ios/Runner/Native/ '
              'but is NOT referenced in project.pbxproj. '
              'Add it via Xcode or by editing pbxproj — without this, '
              'the file will not be compiled into Runner.app.',
        );
      });

      test('$basename is in Sources build phase', () {
        final sourcesPattern = RegExp(
          r'/\* Sources \*/ = \{[^}]*files = \([^)]*?' +
              RegExp.escape(basename) +
              r'[^)]*?\)',
          dotAll: true,
        );
        expect(
          sourcesPattern.hasMatch(pbxproj),
          isTrue,
          reason:
              'Swift file $basename has a PBXFileReference but is NOT in the '
              'PBXSourcesBuildPhase files list. It will not be compiled. '
              'Open Xcode → Target Runner → Build Phases → Compile Sources → +.',
        );
      });
    }

    test('at least one Swift file under Native/ is checked', () {
      expect(
        swiftFiles,
        isNotEmpty,
        reason:
            'Expected at least one .swift file under ios/Runner/Native/ '
            '(camera bridge files). Empty discovery means the test or path is wrong.',
      );
    });
  });
}
