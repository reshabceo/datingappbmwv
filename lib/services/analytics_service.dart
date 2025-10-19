import 'dart:async';
import 'dart:io';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

class AnalyticsService {
  static FirebaseAnalytics? _analytics;
  static FacebookAppEvents? _facebookAppEvents;
  static SupabaseClient get _supabase => Supabase.instance.client;
  static String? _currentSessionId;
  static DateTime? _sessionStartTime;
  static Timer? _sessionTimer;
  static PackageInfo? _packageInfo;
  static DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  // Initialize Firebase Analytics
  static Future<void> initialize() async {
    try {
      // Initialize Firebase Analytics
      _analytics = FirebaseAnalytics.instance;
      await _analytics?.setAnalyticsCollectionEnabled(true);
      
      // Initialize Facebook App Events
      // _facebookAppEvents = FacebookAppEvents();
      
      // Initialize Google Mobile Ads
      // await MobileAds.instance.initialize();
      
      // Get package info
      _packageInfo = await PackageInfo.fromPlatform();
      
      print('✅ Analytics Service initialized');
    } catch (e) {
      print('❌ Failed to initialize Analytics: $e');
    }
  }
  
  // Start user session
  static Future<void> startSession() async {
    try {
      _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      _sessionStartTime = DateTime.now();
      
      // Store session in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('analytics_session_id', _currentSessionId!);
      await prefs.setString('analytics_session_start', _sessionStartTime!.toIso8601String());
      
      // Send session start event to Supabase
      await _sendEventToSupabase(
        eventType: 'session_start',
        eventData: {
          'session_id': _currentSessionId,
          'timestamp': _sessionStartTime!.toIso8601String(),
          'user_id': _supabase.auth.currentUser?.id,
        },
      );
      
      // Create session record in user_sessions table
      await _createSessionRecord();
      
      // Start session timer for periodic updates
      _startSessionTimer();
      
      print('✅ Session started: $_currentSessionId');
    } catch (e) {
      print('❌ Failed to start session: $e');
    }
  }
  
  // End user session
  static Future<void> endSession() async {
    try {
      if (_currentSessionId == null || _sessionStartTime == null) return;
      
      final sessionDuration = DateTime.now().difference(_sessionStartTime!);
      
      // Send session end event to Supabase
      await _sendEventToSupabase(
        eventType: 'session_end',
        eventData: {
          'session_id': _currentSessionId,
          'duration_seconds': sessionDuration.inSeconds,
          'timestamp': DateTime.now().toIso8601String(),
          'user_id': _supabase.auth.currentUser?.id,
        },
      );
      
      // Update session record in user_sessions table
      await _updateSessionRecord(sessionDuration.inSeconds);
      
      // Clear session data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('analytics_session_id');
      await prefs.remove('analytics_session_start');
      
      _currentSessionId = null;
      _sessionStartTime = null;
      _sessionTimer?.cancel();
      
      print('✅ Session ended: ${sessionDuration.inSeconds}s');
    } catch (e) {
      print('❌ Failed to end session: $e');
    }
  }
  
  // Track user login
  static Future<void> trackLogin(String method) async {
    try {
      // Firebase Analytics
      await _analytics?.logLogin(loginMethod: method);
      
      // Supabase
      await _sendEventToSupabase(
        eventType: 'user_login',
        eventData: {
          'method': method,
          'timestamp': DateTime.now().toIso8601String(),
          'user_id': _supabase.auth.currentUser?.id,
        },
      );
      
      print('✅ Login tracked: $method');
    } catch (e) {
      print('❌ Failed to track login: $e');
    }
  }
  
  // Track user logout
  static Future<void> trackLogout() async {
    try {
      // End current session
      await endSession();
      
      // Firebase Analytics
      await _analytics?.logEvent(name: 'user_logout');
      
      // Supabase
      await _sendEventToSupabase(
        eventType: 'user_logout',
        eventData: {
          'timestamp': DateTime.now().toIso8601String(),
          'user_id': _supabase.auth.currentUser?.id,
        },
      );
      
      print('✅ Logout tracked');
    } catch (e) {
      print('❌ Failed to track logout: $e');
    }
  }
  
  // Track profile creation
  static Future<void> trackProfileCreated(Map<String, dynamic> profileData) async {
    try {
      // Firebase Analytics
      await _analytics?.logEvent(
        name: 'profile_created',
        parameters: {
          'has_photos': (profileData['photos'] as List?)?.isNotEmpty ?? false,
          'has_bio': (profileData['bio'] as String?)?.isNotEmpty ?? false,
          'age': profileData['age'] ?? 0,
        },
      );
      
      // Supabase
      await _sendEventToSupabase(
        eventType: 'profile_created',
        eventData: {
          'profile_data': profileData,
          'timestamp': DateTime.now().toIso8601String(),
          'user_id': _supabase.auth.currentUser?.id,
        },
      );
      
      print('✅ Profile creation tracked');
    } catch (e) {
      print('❌ Failed to track profile creation: $e');
    }
  }
  
  // Track swipe action
  static Future<void> trackSwipe(String action, String targetUserId) async {
    try {
      // Firebase Analytics
      await _analytics?.logEvent(
        name: 'swipe_action',
        parameters: {
          'action': action,
          'target_user_id': targetUserId,
        },
      );
      
      // Supabase
      await _sendEventToSupabase(
        eventType: 'swipe_action',
        eventData: {
          'action': action,
          'target_user_id': targetUserId,
          'timestamp': DateTime.now().toIso8601String(),
          'user_id': _supabase.auth.currentUser?.id,
        },
      );
      
      print('✅ Swipe tracked: $action');
    } catch (e) {
      print('❌ Failed to track swipe: $e');
    }
  }
  
  // Track match creation
  static Future<void> trackMatch(String matchId, String otherUserId) async {
    try {
      // Firebase Analytics
      await _analytics?.logEvent(
        name: 'match_created',
        parameters: {
          'match_id': matchId,
          'other_user_id': otherUserId,
        },
      );
      
      // Supabase
      await _sendEventToSupabase(
        eventType: 'match_created',
        eventData: {
          'match_id': matchId,
          'other_user_id': otherUserId,
          'timestamp': DateTime.now().toIso8601String(),
          'user_id': _supabase.auth.currentUser?.id,
        },
      );
      
      print('✅ Match tracked: $matchId');
    } catch (e) {
      print('❌ Failed to track match: $e');
    }
  }
  
  // Track message sent
  static Future<void> trackMessageSent(String matchId, String messageType) async {
    try {
      // Firebase Analytics
      await _analytics?.logEvent(
        name: 'message_sent',
        parameters: {
          'match_id': matchId,
          'message_type': messageType,
        },
      );
      
      // Supabase
      await _sendEventToSupabase(
        eventType: 'message_sent',
        eventData: {
          'match_id': matchId,
          'message_type': messageType,
          'timestamp': DateTime.now().toIso8601String(),
          'user_id': _supabase.auth.currentUser?.id,
        },
      );
      
      print('✅ Message sent tracked: $messageType');
    } catch (e) {
      print('❌ Failed to track message sent: $e');
    }
  }
  
  // Track story viewed
  static Future<void> trackStoryViewed(String storyId, String storyUserId) async {
    try {
      // Firebase Analytics
      await _analytics?.logEvent(
        name: 'story_viewed',
        parameters: {
          'story_id': storyId,
          'story_user_id': storyUserId,
        },
      );
      
      // Supabase
      await _sendEventToSupabase(
        eventType: 'story_viewed',
        eventData: {
          'story_id': storyId,
          'story_user_id': storyUserId,
          'timestamp': DateTime.now().toIso8601String(),
          'user_id': _supabase.auth.currentUser?.id,
        },
      );
      
      print('✅ Story viewed tracked: $storyId');
    } catch (e) {
      print('❌ Failed to track story viewed: $e');
    }
  }
  
  // Track story posted
  static Future<void> trackStoryPosted(String storyId, String mediaType) async {
    try {
      // Firebase Analytics
      await _analytics?.logEvent(
        name: 'story_posted',
        parameters: {
          'story_id': storyId,
          'media_type': mediaType,
        },
      );
      
      // Supabase
      await _sendEventToSupabase(
        eventType: 'story_posted',
        eventData: {
          'story_id': storyId,
          'media_type': mediaType,
          'timestamp': DateTime.now().toIso8601String(),
          'user_id': _supabase.auth.currentUser?.id,
        },
      );
      
      print('✅ Story posted tracked: $storyId');
    } catch (e) {
      print('❌ Failed to track story posted: $e');
    }
  }
  
  // Track feature usage
  static Future<void> trackFeatureUsage(String featureName, Map<String, dynamic>? parameters) async {
    try {
      // Firebase Analytics
      await _analytics?.logEvent(
        name: 'feature_used',
        parameters: {
          'feature_name': featureName,
          ...?parameters,
        },
      );
      
      // Supabase
      await _sendEventToSupabase(
        eventType: 'feature_used',
        eventData: {
          'feature_name': featureName,
          'parameters': parameters ?? {},
          'timestamp': DateTime.now().toIso8601String(),
          'user_id': _supabase.auth.currentUser?.id,
        },
      );
      
      print('✅ Feature usage tracked: $featureName');
    } catch (e) {
      print('❌ Failed to track feature usage: $e');
    }
  }
  
  // Send event to Supabase
  static Future<void> _sendEventToSupabase({
    required String eventType,
    required Map<String, dynamic> eventData,
  }) async {
    try {
      await _supabase.from('user_events').insert({
        'event_type': eventType,
        'event_data': eventData,
        'session_id': _currentSessionId,
        'timestamp': DateTime.now().toIso8601String(),
        'user_id': _supabase.auth.currentUser?.id,
      });
    } catch (e) {
      print('❌ Failed to send event to Supabase: $e');
    }
  }
  
  // Start session timer for periodic updates
  static void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _updateSessionActivity();
    });
  }
  
  // Update session activity
  static Future<void> _updateSessionActivity() async {
    try {
      await _sendEventToSupabase(
        eventType: 'session_activity',
        eventData: {
          'session_id': _currentSessionId,
          'timestamp': DateTime.now().toIso8601String(),
          'user_id': _supabase.auth.currentUser?.id,
        },
      );
    } catch (e) {
      print('❌ Failed to update session activity: $e');
    }
  }
  
  // Get current session ID
  static String? get currentSessionId => _currentSessionId;
  
  // Check if session is active
  static bool get isSessionActive => _currentSessionId != null;
  
  // Create session record in user_sessions table
  static Future<void> _createSessionRecord() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null || _currentSessionId == null || _sessionStartTime == null) return;
      
      await _supabase.from('user_sessions').insert({
        'user_id': userId,
        'session_id': _currentSessionId,
        'session_start': _sessionStartTime!.toIso8601String(),
        'device_type': _getDeviceType(),
        'app_version': _getAppVersion(),
      });
      
      print('✅ Session record created in user_sessions table');
    } catch (e) {
      print('❌ Failed to create session record: $e');
    }
  }
  
  // Update session record with end time and duration
  static Future<void> _updateSessionRecord(int durationSeconds) async {
    try {
      if (_currentSessionId == null) return;
      
      await _supabase.from('user_sessions').update({
        'session_end': DateTime.now().toIso8601String(),
        'duration_seconds': durationSeconds,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('session_id', _currentSessionId!);
      
      print('✅ Session record updated in user_sessions table');
    } catch (e) {
      print('❌ Failed to update session record: $e');
    }
  }
  
  // Get device type
  static String _getDeviceType() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }
  
  // Get app version
  static String _getAppVersion() {
    return _packageInfo?.version ?? '1.0.0';
  }
  
  // ===== UAC REQUIRED TRACKING EVENTS =====
  
  // Track App Install (called on first app launch)
  static Future<void> trackAppInstall() async {
    try {
      // Firebase Analytics
      await _analytics?.logEvent(name: 'app_install');
      
      // Facebook App Events
      // await _facebookAppEvents?.logEvent(name: 'fb_mobile_activate_app');
      
      // Supabase
      await _sendEventToSupabase(
        eventType: 'app_install',
        eventData: {
          'timestamp': DateTime.now().toIso8601String(),
          'app_version': _getAppVersion(),
          'platform': _getDeviceType(),
        },
      );
      
      print('✅ App Install tracked');
    } catch (e) {
      print('❌ Failed to track app install: $e');
    }
  }
  
  // Track First Open (called on first app open after install)
  static Future<void> trackFirstOpen() async {
    try {
      // Firebase Analytics
      await _analytics?.logEvent(name: 'first_open');
      
      // Facebook App Events
      // await _facebookAppEvents?.logEvent(name: 'fb_mobile_activate_app');
      
      // Supabase
      await _sendEventToSupabase(
        eventType: 'first_open',
        eventData: {
          'timestamp': DateTime.now().toIso8601String(),
          'app_version': _getAppVersion(),
          'platform': _getDeviceType(),
        },
      );
      
      print('✅ First Open tracked');
    } catch (e) {
      print('❌ Failed to track first open: $e');
    }
  }
  
  // Track Sign Up (called when user creates account)
  static Future<void> trackSignUp(String method) async {
    try {
      // Firebase Analytics
      await _analytics?.logSignUp(signUpMethod: method);
      
      // Facebook App Events
      // await _facebookAppEvents?.logEvent(name: 'fb_mobile_complete_registration');
      
      // Supabase
      await _sendEventToSupabase(
        eventType: 'user_signup',
        eventData: {
          'method': method,
          'timestamp': DateTime.now().toIso8601String(),
          'user_id': _supabase.auth.currentUser?.id,
        },
      );
      
      print('✅ Sign Up tracked: $method');
    } catch (e) {
      print('❌ Failed to track sign up: $e');
    }
  }
  
  // Track Profile Completed (called when user completes profile setup)
  static Future<void> trackProfileCompleted(Map<String, dynamic> profileData) async {
    try {
      // Firebase Analytics
      await _analytics?.logEvent(
        name: 'profile_completed',
        parameters: {
          'has_photos': (profileData['photos'] as List?)?.isNotEmpty ?? false,
          'has_bio': (profileData['bio'] as String?)?.isNotEmpty ?? false,
          'age': profileData['age'] ?? 0,
          'gender': profileData['gender'] ?? 'unknown',
        },
      );
      
      // Facebook App Events
      // await _facebookAppEvents?.logEvent(name: 'fb_mobile_complete_registration');
      
      // Supabase
      await _sendEventToSupabase(
        eventType: 'profile_completed',
        eventData: {
          'profile_data': profileData,
          'timestamp': DateTime.now().toIso8601String(),
          'user_id': _supabase.auth.currentUser?.id,
        },
      );
      
      print('✅ Profile Completed tracked');
    } catch (e) {
      print('❌ Failed to track profile completed: $e');
    }
  }
  
  // Track Subscription Purchased (called when user purchases subscription)
  static Future<void> trackSubscriptionPurchased({
    required String subscriptionId,
    required String planName,
    required double price,
    required String currency,
    required String paymentMethod,
  }) async {
    try {
      // Firebase Analytics
      await _analytics?.logPurchase(
        currency: currency,
        value: price,
        transactionId: subscriptionId,
        parameters: {
          'plan_name': planName,
          'payment_method': paymentMethod,
        },
      );
      
      // Facebook App Events
      // await _facebookAppEvents?.logPurchase(
      //   amount: price,
      //   currency: currency,
      //   parameters: {
      //     'fb_content_id': subscriptionId,
      //     'fb_content_type': 'subscription',
      //   },
      // );
      
      // Supabase
      await _sendEventToSupabase(
        eventType: 'subscription_purchased',
        eventData: {
          'subscription_id': subscriptionId,
          'plan_name': planName,
          'price': price,
          'currency': currency,
          'payment_method': paymentMethod,
          'timestamp': DateTime.now().toIso8601String(),
          'user_id': _supabase.auth.currentUser?.id,
        },
      );
      
      print('✅ Subscription Purchased tracked: $planName');
    } catch (e) {
      print('❌ Failed to track subscription purchase: $e');
    }
  }
  
  // Track Session Start (enhanced version of existing method)
  static Future<void> trackSessionStart() async {
    try {
      // Firebase Analytics
      await _analytics?.logEvent(name: 'session_start');
      
      // Facebook App Events
      // await _facebookAppEvents?.logEvent(name: 'fb_mobile_activate_app');
      
      // Call existing session start logic
      await startSession();
      
      print('✅ Session Start tracked');
    } catch (e) {
      print('❌ Failed to track session start: $e');
    }
  }
  
  
  // Enhanced login tracking for UAC
  static Future<void> trackLoginEnhanced(String method) async {
    try {
      // Firebase Analytics
      await _analytics?.logLogin(loginMethod: method);
      
      // Facebook App Events
      // await _facebookAppEvents?.logEvent(name: 'fb_mobile_login');
      
      // Supabase
      await _sendEventToSupabase(
        eventType: 'user_login',
        eventData: {
          'method': method,
          'timestamp': DateTime.now().toIso8601String(),
          'user_id': _supabase.auth.currentUser?.id,
        },
      );
      
      print('✅ Enhanced Login tracked: $method');
    } catch (e) {
      print('❌ Failed to track enhanced login: $e');
    }
  }
}
