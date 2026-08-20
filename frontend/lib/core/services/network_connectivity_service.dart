import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final networkOnlineProvider = StateNotifierProvider<NetworkNotifier, bool>((ref) {
  return NetworkNotifier();
});

class NetworkNotifier extends StateNotifier<bool> {
  Timer? _timer;

  NetworkNotifier() : super(true) {
    _checkConnectivity();
    _timer = Timer.periodic(const Duration(seconds: 12), (_) => _checkConnectivity());
  }

  Future<void> _checkConnectivity() async {
    if (kIsWeb) return;
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      final online = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      if (state != online) {
        state = online;
      }
    } catch (_) {
      if (state != false) {
        state = false;
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
