import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/api/api_providers.dart';
import 'package:paperless_go/core/models/correspondent.dart';
import 'package:paperless_go/core/models/document_type.dart';
import 'package:paperless_go/core/models/tag.dart';
import 'package:paperless_go/core/theme.dart';
import 'package:paperless_go/features/documents/documents_notifier.dart';
import 'package:paperless_go/features/documents/filter_bottom_sheet.dart';

import '../../test_utils/golden_surface.dart';
import '../../test_utils/load_app_fonts.dart';

Widget _harness(
  DocumentsFilter filter, {
  Brightness brightness = Brightness.light,
}) {
  return ProviderScope(
    overrides: [
      tagsProvider.overrideWith(
        (ref) async => const {
          1: Tag(id: 1, name: 'Receipts', slug: 'receipts'),
          2: Tag(id: 2, name: 'Warranty', slug: 'warranty', colour: '#2C6155'),
        },
      ),
      correspondentsProvider.overrideWith(
        (ref) async => const {
          1: Correspondent(
            id: 1,
            name: 'Acme Utilities',
            slug: 'acme-utilities',
          ),
        },
      ),
      documentTypesProvider.overrideWith(
        (ref) async => const {
          1: DocumentType(id: 1, name: 'Invoice', slug: 'invoice'),
        },
      ),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: brightness == Brightness.light
          ? AppTheme.light()
          : AppTheme.dark(),
      home: Scaffold(
        body: FilterBottomSheet(currentFilter: filter, onApply: (_) {}),
      ),
    ),
  );
}

void main() {
  setUpAll(loadAppFontsOnce);

  testWidgets('filter_bottom_sheet — no active filters, light', (tester) async {
    setGoldenSurfaceSize(tester, const Size(400, 700));
    await tester.pumpWidget(_harness(const DocumentsFilter()));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/filter_bottom_sheet_empty_light.png'),
    );
  });

  testWidgets('filter_bottom_sheet — active filters, light', (tester) async {
    setGoldenSurfaceSize(tester, const Size(400, 700));
    await tester.pumpWidget(
      _harness(
        const DocumentsFilter(
          correspondentId: 1,
          documentTypeId: 1,
          tagIds: [2],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/filter_bottom_sheet_active_light.png'),
    );
  });

  testWidgets('filter_bottom_sheet — active filters, dark', (tester) async {
    setGoldenSurfaceSize(tester, const Size(400, 700));
    await tester.pumpWidget(
      _harness(
        const DocumentsFilter(
          correspondentId: 1,
          documentTypeId: 1,
          tagIds: [2],
        ),
        brightness: Brightness.dark,
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/filter_bottom_sheet_active_dark.png'),
    );
  });
}
