import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/database/app_database.dart';
import '../../core/design_tokens.dart';
import '../../shared/widgets/empty_state.dart';
import 'queue_error_text.dart';
import 'queue_row_status.dart';
import 'upload_queue_notifier.dart';

/// Everything waiting to reach the server, and why it hasn't.
///
/// The queue was invisible until this screen existed, which is how documents
/// could sit in app-private storage indefinitely with no way to see or clear
/// them. Retention deliberately no longer deletes those files, so this is the
/// only place a user can act on them.
class UploadQueueScreen extends ConsumerWidget {
  const UploadQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(pendingUploadsProvider);
    final activeServer = ref.watch(authStateProvider).valueOrNull?.serverUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload queue'),
        actions: [
          if ((queue.valueOrNull ?? const []).any((r) => r.isFailed))
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Delete all failed',
              onPressed: () => _confirmClearFailed(context, ref),
            ),
        ],
      ),
      body: queue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const EmptyState(
          icon: Icons.error_outline,
          title: 'Could not read the queue',
          description: 'Reopen this screen to try again.',
        ),
        data: (rows) {
          if (rows.isEmpty) {
            return const EmptyState(
              icon: Icons.cloud_done_outlined,
              title: 'Nothing waiting',
              description: 'Documents you share or scan while offline will '
                  'appear here until they reach your server.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: Spacing.xxl),
            itemCount: rows.length + 1,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == rows.length) return const _RetentionFootnote();
              return _QueueRow(
                upload: rows[index],
                activeServer: activeServer,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmClearFailed(BuildContext context, WidgetRef ref) async {
    final failedCount = (ref.read(pendingUploadsProvider).valueOrNull ?? const [])
        .where((r) => r.isFailed)
        .length;
    final confirmed = await _confirmDestructive(
      context,
      title: 'Delete $failedCount failed ${failedCount == 1 ? 'upload' : 'uploads'}?',
      // Names the consequence rather than asking "are you sure?" — for most of
      // these rows this app holds the only copy of the document.
      body: 'Their files are deleted from this device. If a document was only '
          'ever shared into Paperless Go, this is the last copy of it.',
      confirmLabel: 'Delete',
    );
    if (!confirmed || !context.mounted) return;
    final removed =
        await ref.read(uploadQueueActionsProvider.notifier).clearFailed();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted $removed failed '
          '${removed == 1 ? 'upload' : 'uploads'}.')),
    );
  }
}

class _QueueRow extends ConsumerWidget {
  const _QueueRow({required this.upload, required this.activeServer});

  final PendingUpload upload;
  final String? activeServer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final status = queueRowStatus(upload, activeServer: activeServer);
    final summary = queueErrorSummary(upload.lastError);

    return ExpansionTile(
      leading: Icon(_iconFor(status), color: _colorFor(status, colorScheme)),
      title: Text(upload.title?.isNotEmpty == true
          ? upload.title!
          : upload.filename),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_labelFor(status)} · queued '
            '${DateFormat.yMMMd().format(upload.queuedAt)}',
            style: textTheme.bodySmall?.copyWith(
              color: _colorFor(status, colorScheme),
            ),
          ),
          if (summary != null)
            Text(summary,
                style: textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant)),
        ],
      ),
      childrenPadding: const EdgeInsets.fromLTRB(
          Spacing.lg, 0, Spacing.lg, Spacing.md),
      children: [
        if (status == QueueRowStatus.otherServer)
          _DetailLine(
            label: 'Queued for',
            // The row's own server, not the active one — the whole point of
            // this line is that they differ.
            value: upload.serverUrl ?? 'an unknown server',
          ),
        if (status == QueueRowStatus.legacy)
          const _DetailLine(
            label: 'Note',
            value: 'This upload predates server profiles, so Paperless Go '
                'will not guess which server it belongs to. Delete it and '
                'share the document again.',
          ),
        if (upload.retryCount > 0)
          _DetailLine(label: 'Attempts', value: '${upload.retryCount}'),
        if (upload.lastError != null)
          _DetailLine(label: 'Details', value: upload.lastError!),
        const SizedBox(height: Spacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // No Retry for a legacy row: it has no server, so decideUpload
            // always skips it. The button would clear the recorded failure,
            // say "Retrying…", and change nothing — worse than absent.
            if (status != QueueRowStatus.legacy) ...[
              TextButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: () => _retry(context, ref),
              ),
              const SizedBox(width: Spacing.sm),
            ],
            TextButton.icon(
              icon: const Icon(Icons.delete_outline),
              style: TextButton.styleFrom(foregroundColor: colorScheme.error),
              label: const Text('Delete'),
              onPressed: () => _delete(context, ref),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _retry(BuildContext context, WidgetRef ref) async {
    await ref.read(uploadQueueActionsProvider.notifier).retry(upload);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Retrying…')),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await _confirmDestructive(
      context,
      title: 'Delete this upload?',
      body: 'The file is deleted from this device. If this document was only '
          'ever shared into Paperless Go, this is the last copy of it.',
      confirmLabel: 'Delete',
    );
    if (!confirmed || !context.mounted) return;
    await ref.read(uploadQueueActionsProvider.notifier).delete(upload);
  }

  static IconData _iconFor(QueueRowStatus status) {
    switch (status) {
      case QueueRowStatus.waiting:
        return Icons.schedule;
      case QueueRowStatus.retrying:
        return Icons.autorenew;
      case QueueRowStatus.failed:
        return Icons.error_outline;
      case QueueRowStatus.otherServer:
        return Icons.dns_outlined;
      case QueueRowStatus.legacy:
        return Icons.help_outline;
    }
  }

  static String _labelFor(QueueRowStatus status) {
    switch (status) {
      case QueueRowStatus.waiting:
        return 'Waiting';
      case QueueRowStatus.retrying:
        return 'Retrying';
      case QueueRowStatus.failed:
        return 'Failed';
      case QueueRowStatus.otherServer:
        return 'Queued for another server';
      case QueueRowStatus.legacy:
        return 'Needs attention';
    }
  }

  static Color _colorFor(QueueRowStatus status, ColorScheme scheme) {
    switch (status) {
      case QueueRowStatus.failed:
      case QueueRowStatus.legacy:
        return scheme.error;
      case QueueRowStatus.waiting:
      case QueueRowStatus.retrying:
      case QueueRowStatus.otherServer:
        return scheme.onSurfaceVariant;
    }
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Text(label,
                style: textTheme.labelMedium
                    ?.copyWith(color: Theme.of(context).hintColor)),
          ),
          Expanded(child: SelectableText(value, style: textTheme.bodySmall)),
        ],
      ),
    );
  }
}

/// Explains why storage grows, so it is not a mystery the user has to guess at.
class _RetentionFootnote extends StatelessWidget {
  const _RetentionFootnote();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Spacing.lg, Spacing.lg, Spacing.lg, Spacing.sm),
      child: Text(
        'Paperless Go keeps the file for an upload it has given up on, rather '
        'than deleting it — it may be the only copy of that document. Delete '
        'them here once you no longer need them.',
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: Theme.of(context).hintColor),
      ),
    );
  }
}

/// Shared confirm dialog. Returns false when dismissed, so a stray tap outside
/// never destroys a document.
Future<bool> _confirmDestructive(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
