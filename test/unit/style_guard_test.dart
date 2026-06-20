import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Files that legitimately use literal `Colors.*` — the image editor, the
/// forced-dark PDF viewer, and tag-contrast computation — exempt from the
/// destructive-color guard.
const _colorAllowlist = {
  'annotate_screen.dart',
  'crop_screen.dart',
  'crop_overlay.dart',
  'document_preview_screen.dart',
  'tag_chip.dart',
};

Iterable<File> _dartFiles(String dir) sync* {
  for (final e in Directory(dir).listSync(recursive: true)) {
    if (e is File &&
        e.path.endsWith('.dart') &&
        !e.path.endsWith('.g.dart') &&
        !e.path.endsWith('.freezed.dart')) {
      yield e;
    }
  }
}

void main() {
  group('style guard', () {
    test('no hardcoded Colors.red outside the editor allowlist', () {
      final offenders = <String>[];
      for (final f in _dartFiles('lib')) {
        if (_colorAllowlist.contains(f.uri.pathSegments.last)) continue;
        final lines = f.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (lines[i].contains('Colors.red')) {
            offenders.add('${f.path}:${i + 1}');
          }
        }
      }
      expect(
        offenders,
        isEmpty,
        reason: 'Use Theme.of(context).colorScheme.error for destructive UI '
            'instead of Colors.red. Offenders:\n${offenders.join('\n')}',
      );
    });

    test('errors are not stored raw (no errorMessage: <x>.toString())', () {
      final offenders = <String>[];
      final re = RegExp(r'errorMessage:\s*\w+\.toString\(\)');
      for (final f in _dartFiles('lib')) {
        final lines = f.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (re.hasMatch(lines[i])) offenders.add('${f.path}:${i + 1}');
        }
      }
      expect(
        offenders,
        isEmpty,
        reason: 'Sanitize with friendlyApiMessage(e) before storing in '
            'errorMessage. Offenders:\n${offenders.join('\n')}',
      );
    });
  });
}
