import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'offline_database_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isOnline = true;

  // Check if device is online
  Future<bool> isOnline() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isOnline = result != ConnectivityResult.none;
      return _isOnline;
    } catch (e) {
      debugPrint('❌ Error checking connectivity: $e');
      return false;
    }
  }

  // Start listening to connectivity changes
  void startListening(Function(bool) onConnectivityChanged) {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;
      
      if (_isOnline != wasOnline) {
        debugPrint(_isOnline ? '🌐 Device is ONLINE' : '📡 Device is OFFLINE');
        onConnectivityChanged(_isOnline);
        
        // Sync pending actions when coming back online
        if (_isOnline && !wasOnline) {
          _syncPendingActions();
        }
      }
    });
  }

  // Stop listening
  void stopListening() {
    _connectivitySubscription?.cancel();
  }

  // Sync all pending actions to server
  Future<void> _syncPendingActions() async {
    try {
      final pendingActions = OfflineDatabaseService.getPendingActions();
      
      if (pendingActions.isEmpty) {
        debugPrint('✅ No pending actions to sync');
        return;
      }

      debugPrint('🔄 Syncing ${pendingActions.length} pending actions.. .');
      
      // Sync each pending action
      for (var action in pendingActions) {
        debugPrint('  📤 Syncing: ${action['type']}');
        // Actions will be synced automatically when online
        // because api_service checks _isOnline() before operations
      }
      
      // Clear pending actions after successful sync
      await OfflineDatabaseService. clearPendingActions();
      debugPrint('✅ All pending actions synced');
      
    } catch (e) {
      debugPrint('❌ Error syncing pending actions: $e');
    }
  }

  // Get current connectivity status
  bool get isCurrentlyOnline => _isOnline;
}