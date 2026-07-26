import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/models/tag.dart';
import 'package:paperless_go/core/theme.dart';
import 'package:paperless_go/shared/widgets/tag_chip.dart';

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
      body: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(spacing: 8, runSpacing: 8, children: chips),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(loadAppFontsOnce);

  // Covers TagChip's parseColor/computeLuminance contrast logic: a light
  // server color needs dark text, a dark one needs white text, and no
  // server color at all falls back to the theme's secondaryContainer.
  const lightServerColor = Tag(
    id: 1,
    name: 'Light yellow',
    slug: 'light-yellow',
    colour: '#F5E050',
  );
  const darkServerColor = Tag(
    id: 2,
    name: 'Dark navy',
    slug: 'dark-navy',
    colour: '#1A1A40',
  );
  const noServerColor = Tag(id: 3, name: 'No color set', slug: 'no-color');
  const midToneServerColor = Tag(
    id: 4,
    name: 'Mid teal',
    slug: 'mid-teal',
    colour: '#2C6155',
  );

  testWidgets('tag_chip — server-color contrast, light theme', (tester) async {
    setGoldenSurfaceSize(tester, const Size(300, 90));
    await tester.pumpWidget(
      _harness([
        const TagChip(tag: lightServerColor),
        const TagChip(tag: darkServerColor),
        const TagChip(tag: midToneServerColor),
        const TagChip(tag: noServerColor),
        const TagOverflowChip(count: 5),
      ]),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/tag_chip_contrast_light.png'),
    );
  });

  testWidgets('tag_chip — server-color contrast, dark theme', (tester) async {
    setGoldenSurfaceSize(tester, const Size(300, 90));
    await tester.pumpWidget(
      _harness([
        const TagChip(tag: lightServerColor),
        const TagChip(tag: darkServerColor),
        const TagChip(tag: midToneServerColor),
        const TagChip(tag: noServerColor),
        const TagOverflowChip(count: 5),
      ], brightness: Brightness.dark),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/tag_chip_contrast_dark.png'),
    );
  });
}
