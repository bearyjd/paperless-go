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
    if (files.isEmpty) return;

    // Filter to files with valid paths
    final validFiles = files.where((f) => f.path.isNotEmpty).toList();
    if (validFiles.isEmpty) return;

    final context = _navigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    if (validFiles.length == 1) {
      // Single file → upload directly
      final file = validFiles.first;
      final filename = file.path.split('/').last;
      context.push(
        '/scan/upload',
        extra: {'filePath': file.path, 'filename': filename},
      );
    } else {
      // Multiple files → treat as multi-page scan for review
      final paths = validFiles.map((f) => f.path).toList();
      context.push('/scan/review', extra: paths);
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
