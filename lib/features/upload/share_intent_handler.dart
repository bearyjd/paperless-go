import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

const _methodChannel = MethodChannel('com.ventoux.paperlessgo/share');
const _eventChannel = EventChannel('com.ventoux.paperlessgo/share_stream');

/// A file shared into the app, resolved natively via ContentResolver
/// (see android/.../SharePlugin.kt — not receive_sharing_intent, whose
/// legacy path lookup fails for SAF DocumentsProvider content:// URIs).
@immutable
class SharedFile {
  const SharedFile({required this.path, required this.filename, this.mimeType});

  final String path;
  final String filename;
  final String? mimeType;

  bool get isImage => mimeType?.startsWith('image/') ?? false;

  factory SharedFile.fromJson(Map<String, dynamic> json) => SharedFile(
        path: json['path'] as String? ?? '',
        filename: json['filename'] as String? ?? '',
        mimeType: json['mimeType'] as String?,
      );
}

List<SharedFile> _parseSharedFiles(String raw) {
  final decoded = jsonDecode(raw) as List<dynamic>;
  return decoded
      .map((e) => SharedFile.fromJson(e as Map<String, dynamic>))
      .toList();
}

class ShareIntentHandler {
  StreamSubscription? _subscription;
  bool _initialized = false;
  final GlobalKey<NavigatorState> _navigatorKey;

  ShareIntentHandler(this._navigatorKey);

  void initialize() {
    if (_initialized) return;
    _initialized = true;

    // Handle shared files when app is already running
    _subscription = _eventChannel.receiveBroadcastStream().listen((raw) {
      debugPrint('PaperlessShare: event received: $raw');
      _handleSharedFiles(_parseSharedFiles(raw as String));
    });

    // Handle shared files when app is opened via share
    _methodChannel.invokeMethod<String>('getInitialShare').then((raw) {
      debugPrint('PaperlessShare: getInitialShare returned: $raw');
      if (raw == null) return;
      final files = _parseSharedFiles(raw);
      if (files.isNotEmpty) _handleSharedFiles(files);
    });
  }

  void _handleSharedFiles(List<SharedFile> files) {
    final route = resolveShareRoute(files);
    debugPrint('PaperlessShare: resolveShareRoute -> $route');
    if (route == null) return;

    final context = _navigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    // TODO(#24): pushes unconditionally, including while logged out — this
    // lands the scan/upload screen on top of /login with no auth gate. Needs
    // either a check here or a "pending share" queue that resumes post-login.
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
ShareRoute? resolveShareRoute(List<SharedFile> files) {
  // Filter to files with valid paths.
  final validFiles = files.where((f) => f.path.isNotEmpty).toList();
  if (validFiles.isEmpty) return null;

  final imagePaths =
      validFiles.where((f) => f.isImage).map((f) => f.path).toList();

  if (imagePaths.isNotEmpty) {
    // One or more images → multi-page scan/enhance/PDF pipeline.
    return ShareRoute('/scan/review', extra: imagePaths);
  }

  // No images: upload the first non-image file (e.g. a PDF) directly.
  final file = validFiles.first;
  return ShareRoute(
    '/scan/upload',
    extra: {'filePath': file.path, 'filename': file.filename},
  );
}
