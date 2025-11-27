import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService instance = ConnectivityService._internal();
  ConnectivityService._internal();

  bool _isOnline = true;
  final Connectivity _connectivity = Connectivity();

  bool get isOnline => _isOnline;

  Future<void> initialize() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;
    notifyListeners();

    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((result) {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;
      
      if (wasOnline != _isOnline) {
        notifyListeners();
      }
    });
  }
}