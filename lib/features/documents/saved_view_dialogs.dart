import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_providers.dart';
import '../../core/models/saved_view.dart';
import '../../core/api/api_error_mapper.dart';
import 'documents_notifier.dart';
import 'saved_view_helpers.dart';

Future<void> showSaveViewDialog({
  required BuildContext context,
  required WidgetRef ref,
  required DocumentsFilter currentFilter,
}) async {
  final nameController = TextEditingController();
  try {
    bool showOnDashboard = false;
    bool showInSidebar = true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Save as view'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'View name',
                  hintText: 'e.g. Invoices 2024',
                ),
                textCapitalization:
                    TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show in sidebar'),
                value: showInSidebar,
                onChanged: (v) =>
                    setDialogState(() => showInSidebar = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show on dashboard'),
                value: showOnDashboard,
                onChanged: (v) =>
                    setDialogState(() => showOnDashboard = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final name = nameController.text.trim();
    final rules = documentsFilterToFilterRules(currentFilter);
    final (sortField, sortReverse) =
        parseOrdering(currentFilter.ordering);

    try {
      await ref.read(paperlessApiProvider).createSavedView(
            name: name,
            filterRules: rules,
            sortField: sortField,
            sortReverse: sortReverse,
            showOnDashboard: showOnDashboard,
            showInSidebar: showInSidebar,
          );
      ref.invalidate(savedViewsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$name" saved')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to save view: ${friendlyApiMessage(e)}')),
        );
      }
    }
  } finally {
    nameController.dispose();
  }
}

Future<void> showChipManagementSheet({
  required BuildContext context,
  required SavedView view,
  required Future<void> Function() onDelete,
  required Future<void> Function() onRename,
}) async {
  final action = await showModalBottomSheet<String>(
    context: context,
    builder: (sheetCtx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Rename'),
            onTap: () => Navigator.pop(sheetCtx, 'rename'),
          ),
          ListTile(
            leading: Icon(Icons.delete_outline,
                color:
                    Theme.of(sheetCtx).colorScheme.error),
            title: Text('Delete',
                style: TextStyle(
                    color: Theme.of(sheetCtx)
                        .colorScheme
                        .error)),
            onTap: () => Navigator.pop(sheetCtx, 'delete'),
          ),
        ],
      ),
    ),
  );

  if (!context.mounted) return;

  if (action == 'delete') {
    await onDelete();
  } else if (action == 'rename') {
    await onRename();
  }
}

Future<void> confirmDeleteSavedView({
  required BuildContext context,
  required WidgetRef ref,
  required SavedView view,
  required VoidCallback? onDeactivated,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete view?'),
      content: Text(
          'Delete "${view.name}"? This cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor:
                Theme.of(ctx).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  try {
    await ref
        .read(paperlessApiProvider)
        .deleteSavedView(view.id);
    onDeactivated?.call();
    ref.invalidate(savedViewsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('"${view.name}" deleted')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: ${friendlyApiMessage(e)}')),
      );
    }
  }
}

Future<void> showRenameSavedViewDialog({
  required BuildContext context,
  required WidgetRef ref,
  required SavedView view,
}) async {
  final nameController =
      TextEditingController(text: view.name);

  try {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename view'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration:
              const InputDecoration(labelText: 'Name'),
          textCapitalization:
              TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final newName = nameController.text.trim();
    try {
      await ref
          .read(paperlessApiProvider)
          .updateSavedView(view.id, name: newName);
      ref.invalidate(savedViewsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Renamed to "$newName"')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to rename: ${friendlyApiMessage(e)}')),
        );
      }
    }
  } finally {
    nameController.dispose();
  }
}
