import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_tokens.dart';
import 'upload_queue_notifier.dart';

/// Tells the user when uploads have stopped trying, without nagging.
///
/// The queue was silent before this: a document could fail every retry and then
/// sit on disk indefinitely with nothing on screen. A badge in Settings alone
/// does not fix that — nobody opens Settings to check for a problem they have
/// not been told about.
///
/// Shows nothing at all unless a row actually needs a decision (failed or
/// legacy). Uploads merely waiting for signal are normal and must not raise a
/// banner, or the banner becomes noise and gets ignored on the one day it
/// matters.
class QueueStatusBanner extends ConsumerStatefulWidget {
  const QueueStatusBanner({super.key});

  @override
  ConsumerState<QueueStatusBanner> createState() => _QueueStatusBannerState();
}

class _QueueStatusBannerState extends ConsumerState<QueueStatusBanner> {
  /// Dismissal is per-visit, not persisted. A document the app is holding and
  /// cannot deliver is worth raising again next launch; remembering the
  /// dismissal forever is how it goes quiet again.
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final count = ref.watch(uploadsNeedingAttentionProvider);
    if (count == 0 || _dismissed) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            Spacing.lg, Spacing.sm, Spacing.sm, Spacing.sm),
        child: Row(
          children: [
            Icon(Icons.upload_file_outlined,
                size: 20, color: colorScheme.onErrorContainer),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(
                count == 1
                    ? '1 upload never reached your server'
                    : '$count uploads never reached your server',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
              ),
            ),
            TextButton(
              onPressed: () => context.push('/upload-queue'),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onErrorContainer,
              ),
              child: const Text('Review'),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              color: colorScheme.onErrorContainer,
              tooltip: 'Dismiss',
              onPressed: () => setState(() => _dismissed = true),
            ),
          ],
        ),
      ),
    );
  }
}
