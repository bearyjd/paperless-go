import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class ShareIntentHandler {
  StreamSubscription? _subscription;
  bool _initialized = false;
  final GlobalKey<NavigatorState> _navigatorKey;

  ShareIntentHandler(this._navigatorKey);

  void initialize() {
    if (_initialized) return;
    _initialized = true;

    // Handle shared files when app is already running
    _subscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      (files) => _handleSharedFiles(files),
    );

    // Handle shared files when app is opened via share
    ReceiveSharingIntent.instance.getInitialMedia().then((files) {
      if (files.isNotEmpty) {
        _handleSharedFiles(files);
        ReceiveSharingIntent.instance.reset();
      }
    });
  }

  void _handleSharedFiles(List<SharedMediaFile> files) {
    final route = resolveShareRoute(files);
    if (route == null) return;

    final context = _navigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    context.push(route.location, extra: route.extra);
  }

  void dispose() {
    _subscription?.cancel();
  }
}

/// The navigation target resolved from a batch of shared files.
@immutable
class ShareRoute {
  const ShareRoute(this.location, {this.extra});

  final String location;
  final Object? extra;
}

/// Decide where shared files should go.
///
/// Images — one or many — are routed into the scan pipeline
/// (`/scan/review` → enhance → PDF) so they get wrapped into a PDF before
/// upload, matching the in-app scanner flow. A non-image file (PDF, etc.) is
/// uploaded directly as-is. Routing keys off the file *type*, not the file
/// *count*, so a single shared image still launches the PDF pipeline.
///
/// Returns null when there is nothing valid to handle.
ShareRoute? resolveShareRoute(List<SharedMediaFile> files) {
  // Filter to files with valid paths.
  final validFiles = files.where((f) => f.path.isNotEmpty).toList();
  if (validFiles.isEmpty) return null;

  final imagePaths = validFiles
      .where((f) => f.type == SharedMediaType.image)
      .map((f) => f.path)
      .toList();

  if (imagePaths.isNotEmpty) {
    // One or more images → multi-page scan/enhance/PDF pipeline.
    return ShareRoute('/scan/review', extra: imagePaths);
  }

  // No images: upload the first non-image file (e.g. a PDF) directly.
  final file = validFiles.first;
  final filename = file.path.split('/').last;
  return ShareRoute(
    '/scan/upload',
    extra: {'filePath': file.path, 'filename': filename},
  );
}
