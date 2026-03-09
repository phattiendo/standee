import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Dịch vụ theo dõi trạng thái mạng (online/offline)
class ConnectivityService {
  ConnectivityService._internal();

  static final ConnectivityService _instance = ConnectivityService._internal();
  static ConnectivityService get I => _instance;

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller =
      StreamController<bool>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Stream<bool> get onStatusChanged => _controller.stream;

  /// Trạng thái mạng hiện tại (sau khi init).
  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);
  }

  Future<void> init() async {
    _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged.listen(_onChanged);
    final initial = await _connectivity.checkConnectivity();
    _onChanged(initial);
  }

  void _onChanged(List<ConnectivityResult> results) {
    final hasNetwork = results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);
    _controller.add(hasNetwork);
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}

