import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:lovebug/services/supabase_service.dart';

class NotificationService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      // Skip on web for now (push not needed for in-tab calls)
      if (kIsWeb) {
        _initialized = true;
        return;
      }

      // Ensure Firebase is initialized
      try {
        await Firebase.initializeApp();
      } catch (_) {}

      final messaging = FirebaseMessaging.instance;

      // Request permissions (iOS)
      if (Platform.isIOS) {
        await messaging.requestPermission(alert: true, badge: true, sound: true);
        // Get APNs token (optional, for diagnostics)
        await messaging.getAPNSToken();
      }

      // Get FCM token
      final token = await messaging.getToken() ?? '';
      if (token.isNotEmpty) {
        await SupabaseService.updateFCMToken(token);
      }

      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        await SupabaseService.updateFCMToken(newToken);
      });

      _initialized = true;
      print('✅ NotificationService initialized');
    } catch (e) {
      print('❌ NotificationService init failed: $e');
    }
  }
}


