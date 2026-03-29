import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/shared/widgets/empty_state.dart';

void main() {
  group('EmptyState', () {
    testWidgets('renders icon and title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox_outlined,
              title: 'No documents',
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
      expect(find.text('No documents'), findsOneWidget);
    });

    testWidgets('renders optional description', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox_outlined,
              title: 'No documents',
              description: 'Upload one to get started',
            ),
          ),
        ),
      );
      expect(find.text('Upload one to get started'), findsOneWidget);
    });

    testWidgets('renders optional action button', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox_outlined,
              title: 'No documents',
              actionLabel: 'Upload',
              onAction: () => tapped = true,
            ),
          ),
        ),
      );
      expect(find.text('Upload'), findsOneWidget);
      await tester.tap(find.text('Upload'));
      expect(tapped, true);
    });

    testWidgets('does not render action button when label is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox_outlined,
              title: 'No items',
            ),
          ),
        ),
      );
      expect(find.byType(FilledButton), findsNothing);
    });
  });
}
