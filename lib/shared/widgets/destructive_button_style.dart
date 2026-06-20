import 'package:flutter/material.dart';

/// Shared style for destructive [FilledButton]s (delete / permanent actions).
///
/// Centralizes the error/onError color pairing so the destructive treatment
/// lives in one place instead of being repeated inline at every call site.
ButtonStyle destructiveButtonStyle(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return FilledButton.styleFrom(
    backgroundColor: cs.error,
    foregroundColor: cs.onError,
  );
}
