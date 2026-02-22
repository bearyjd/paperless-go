import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_service.g.dart';

@Riverpod(keepAlive: true)
class ConnectivityNotifier extends _$ConnectivityNotifier {
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  bool build() {
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      state = results.any((r) => r != ConnectivityResult.none);
    });
    ref.onDispose(() => _subscription?.cancel());
    // Assume online initially, will update from stream
    _checkInitial();
    return true;
  }

  Future<void> _checkInitial() async {
    final results = await Connectivity().checkConnectivity();
    state = results.any((r) => r != ConnectivityResult.none);
  }
}
