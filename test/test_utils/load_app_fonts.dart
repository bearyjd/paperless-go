import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads every font declared in `FontManifest.json` (the app's bundled
/// Inter/SpaceGrotesk fonts plus MaterialIcons, pulled in automatically by
/// `uses-material-design: true`) into the test binding.
///
/// Without this, golden tests render text and icons as Flutter's fallback
/// test glyphs (solid boxes) instead of the real fonts, making goldens
/// visually meaningless. Call once per test via [loadAppFontsOnce].
Future<void> loadAppFonts() async {
  final fontManifest = await rootBundle.loadStructuredData<Iterable<dynamic>>(
    'FontManifest.json',
    (string) async => json.decode(string) as Iterable<dynamic>,
  );

  for (final dynamic entry in fontManifest) {
    final font = entry as Map<String, dynamic>;
    final fontLoader = FontLoader(font['family'] as String);
    for (final dynamic fontType in font['fonts'] as Iterable<dynamic>) {
      final asset = (fontType as Map<String, dynamic>)['asset'] as String;
      fontLoader.addFont(rootBundle.load(asset));
    }
    await fontLoader.load();
  }
}

bool _fontsLoaded = false;

/// Idempotent wrapper so multiple golden tests in the same file (or run via
/// `flutter test`'s process-per-file isolation) don't reload fonts needlessly.
Future<void> loadAppFontsOnce() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  if (_fontsLoaded) return;
  await loadAppFonts();
  _fontsLoaded = true;
}
