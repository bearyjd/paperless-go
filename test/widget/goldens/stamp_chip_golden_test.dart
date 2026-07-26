import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/theme.dart';
import 'package:paperless_go/shared/widgets/stamp_chip.dart';

import '../../test_utils/golden_surface.dart';
import '../../test_utils/load_app_fonts.dart';

Widget _harness(
  List<Widget> chips, {
  Brightness brightness = Brightness.light,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: brightness == Brightness.light ? AppTheme.light() : AppTheme.dark(),
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(spacing: 12, runSpacing: 12, children: chips),
      ),
    ),
  );
}

void main() {
  setUpAll(loadAppFontsOnce);

  testWidgets('stamp_chip — default accent, rotated vs flat, light', (
    tester,
  ) async {
    setGoldenSurfaceSize(tester, const Size(360, 200));
    await tester.pumpWidget(
      _harness([
        const StampChip(label: 'EMPTY'),
        const StampChip(label: 'Flat', rotated: false),
        const StampChip(label: 'Selected', icon: Icons.check, onTap: null),
        StampChip(label: 'Deletable', onDeleted: () {}),
      ]),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/stamp_chip_default_light.png'),
    );
  });

  testWidgets('stamp_chip — default accent, dark', (tester) async {
    setGoldenSurfaceSize(tester, const Size(360, 200));
    await tester.pumpWidget(
      _harness([
        const StampChip(label: 'EMPTY'),
        const StampChip(label: 'Flat', rotated: false),
        const StampChip(label: 'Selected', icon: Icons.check),
      ], brightness: Brightness.dark),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/stamp_chip_default_dark.png'),
    );
  });

  testWidgets('stamp_chip — server tint colors, light and dark', (
    tester,
  ) async {
    setGoldenSurfaceSize(tester, const Size(360, 200));
    await tester.pumpWidget(
      _harness([
        const StampChip(label: 'Red tag', tint: Colors.red, rotated: false),
        const StampChip(label: 'Blue tag', tint: Colors.blue, rotated: false),
        const StampChip(label: 'Green tag', tint: Colors.green, rotated: false),
      ]),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/stamp_chip_tint_light.png'),
    );

    await tester.pumpWidget(
      _harness([
        const StampChip(label: 'Red tag', tint: Colors.red, rotated: false),
        const StampChip(label: 'Blue tag', tint: Colors.blue, rotated: false),
        const StampChip(label: 'Green tag', tint: Colors.green, rotated: false),
      ], brightness: Brightness.dark),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/stamp_chip_tint_dark.png'),
    );
  });
}
