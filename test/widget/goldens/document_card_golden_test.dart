import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/models/correspondent.dart';
import 'package:paperless_go/core/models/document.dart';
import 'package:paperless_go/core/models/document_type.dart';
import 'package:paperless_go/core/models/tag.dart';
import 'package:paperless_go/core/theme.dart';
import 'package:paperless_go/shared/widgets/document_card.dart';

import '../../test_utils/golden_surface.dart';
import '../../test_utils/load_app_fonts.dart';

const _tags = {
  1: Tag(id: 1, name: 'Receipts', slug: 'receipts'),
  2: Tag(id: 2, name: 'Warranty', slug: 'warranty', colour: '#2C6155'),
  3: Tag(id: 3, name: 'Tax 2026', slug: 'tax-2026'),
  4: Tag(id: 4, name: 'Insurance', slug: 'insurance'),
};

const _correspondents = {
  1: Correspondent(id: 1, name: 'Acme Utilities', slug: 'acme-utilities'),
};

const _docTypes = {1: DocumentType(id: 1, name: 'Invoice', slug: 'invoice')};

Widget _harness(Widget child, {Brightness brightness = Brightness.light}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: brightness == Brightness.light ? AppTheme.light() : AppTheme.dark(),
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: Padding(padding: const EdgeInsets.only(top: 8), child: child),
      ),
    ),
  );
}

void main() {
  setUpAll(loadAppFontsOnce);

  testWidgets('document_card — full metadata, light', (tester) async {
    setGoldenSurfaceSize(tester, const Size(400, 116));
    await tester.pumpWidget(
      _harness(
        DocumentCard(
          document: const Document(
            id: 1,
            title: 'Electric bill — March 2026',
            correspondent: 1,
            documentType: 1,
            tags: [1, 2],
          ),
          tags: _tags,
          correspondents: _correspondents,
          documentTypes: _docTypes,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/document_card_full_light.png'),
    );
  });

  testWidgets('document_card — full metadata, dark', (tester) async {
    setGoldenSurfaceSize(tester, const Size(400, 116));
    await tester.pumpWidget(
      _harness(
        DocumentCard(
          document: const Document(
            id: 1,
            title: 'Electric bill — March 2026',
            correspondent: 1,
            documentType: 1,
            tags: [1, 2],
          ),
          tags: _tags,
          correspondents: _correspondents,
          documentTypes: _docTypes,
        ),
        brightness: Brightness.dark,
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/document_card_full_dark.png'),
    );
  });

  testWidgets('document_card — bare (no metadata, no tags)', (tester) async {
    setGoldenSurfaceSize(tester, const Size(400, 76));
    await tester.pumpWidget(
      _harness(
        const DocumentCard(
          document: Document(id: 2, title: 'Untitled scan'),
          tags: {},
          correspondents: {},
          documentTypes: {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/document_card_bare.png'),
    );
  });

  testWidgets('document_card — tag overflow (>3 tags)', (tester) async {
    setGoldenSurfaceSize(tester, const Size(400, 108));
    await tester.pumpWidget(
      _harness(
        const DocumentCard(
          document: Document(
            id: 3,
            title: 'Bundled statement',
            tags: [1, 2, 3, 4],
          ),
          tags: _tags,
          correspondents: {},
          documentTypes: {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/document_card_tag_overflow.png'),
    );
  });
}
