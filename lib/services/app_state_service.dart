import 'dart:io';
import 'package:flutter/material.dart';

class AppStateService {
  static AppLifecycleState _currentState = AppLifecycleState.resumed;
  static bool _isInitialized = false;
  static bool _isAndroidBackground = false;
  
  static void initialize() {
    if (_isInitialized) {
      print('🔧 DEBUG: AppStateService already initialized, skipping');
      return;
    }
    WidgetsBinding.instance.addObserver(_AppLifecycleObserver());
    _isInitialized = true;
    print('🔧 DEBUG: AppStateService initialized successfully');
    print('🔧 DEBUG: Current app state: $_currentState');
  }
  
  static bool get isAppInForeground => _currentState == AppLifecycleState.resumed;
  static bool get isAppInBackground => _currentState == AppLifecycleState.paused;
  static bool get isAppClosed => _currentState == AppLifecycleState.detached;
  
  // CRITICAL FIX: Platform-specific logic for push notifications
  static bool get shouldSendPushNotification {
    final result = Platform.isIOS ? isAppClosed : !isAppInForeground;
    print('🔧 DEBUG: shouldSendPushNotification - Platform: ${Platform.isIOS ? "iOS" : "Android"}, AppState: $_currentState, Result: $result');
    return result;
  }
  
  static void _updateState(AppLifecycleState state) {
    final oldState = _currentState;
    _currentState = state;
    print('🔧 DEBUG: App state changed from $oldState to $state');
    print('🔧 DEBUG: isAppInForeground: $isAppInForeground, isAppInBackground: $isAppInBackground, isAppClosed: $isAppClosed');
    
    // Handle Android background state
    if (Platform.isAndroid) {
      if (state == AppLifecycleState.paused) {
        _isAndroidBackground = true;
        print('🤖 ANDROID: App moved to background');
      } else if (state == AppLifecycleState.resumed) {
        _isAndroidBackground = false;
        print('🤖 ANDROID: App resumed from background');
      }
    } else if (Platform.isIOS) {
      print('🍎 IOS: App state changed to $state');
    }
  }
}

class _AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AppStateService._updateState(state);
  }
}
