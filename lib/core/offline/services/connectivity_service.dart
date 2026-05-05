import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Stream<bool> get onConnectivityChanged => _controller.stream;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Future<void> initialize() async {
    final result = await Connectivity().checkConnectivity();
    _isOnline = _isConnected(result);

    _subscription ??= Connectivity().onConnectivityChanged.listen((result) {
      final online = _isConnected(result);
      if (online != _isOnline) {
        _isOnline = online;
        _controller.add(online);
      }
    });
  }

  bool _isConnected(List<ConnectivityResult> result) {
    return result.any(
      (r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet,
    );
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
