import 'dart:async';
import 'dart:io';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class AnalyticsService {
  static FirebaseAnalytics? _analytics;
  static SupabaseClient get _supabase => Supabase.instance.client;
  static String? _currentSessionId;
  static DateTime? _sessionStartTime;
  static Timer? _sessionTimer;
  
  // Initialize Firebase Analytics
  static Future<void> initialize() async {
    try {
      _analytics = FirebaseAnalytics.instance;
      await _analytics?.setAnalyticsCollectionEnabled(true);
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
    // You can implement package_info_plus to get actual version
    return '1.0.0';
  }
}
