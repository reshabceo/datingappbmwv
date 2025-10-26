import 'dart:io' show Platform; // guarded by kIsWeb checks below
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class CallDebugService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  
  // Enhanced logging for call debugging
  static Future<void> logCallEvent({
    required String event,
    required String callId,
    String? userId,
    Map<String, dynamic>? data,
    String? error,
  }) async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      PackageInfo? packageInfo;
      try { packageInfo = await PackageInfo.fromPlatform(); } catch (_) {}
      
      Map<String, dynamic> logData = {
        'event': event,
        'call_id': callId,
        'user_id': userId ?? _supabase.auth.currentUser?.id,
        'timestamp': DateTime.now().toIso8601String(),
        'platform': kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android'),
        if (packageInfo != null) 'app_version': packageInfo.version,
        if (packageInfo != null) 'build_number': packageInfo.buildNumber,
        'data': data ?? {},
      };
      
      if (error != null) {
        logData['error'] = error;
      }
      
      // Add device-specific info
      if (!kIsWeb && Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        logData['device_info'] = {
          'model': androidInfo.model,
          'version': androidInfo.version.release,
          'sdk': androidInfo.version.sdkInt,
        };
      } else if (!kIsWeb && Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        logData['device_info'] = {
          'model': iosInfo.model,
          'version': iosInfo.systemVersion,
          'name': iosInfo.name,
        };
      } else if (kIsWeb) {
        try {
          final webInfo = await deviceInfo.webBrowserInfo;
          logData['device_info'] = {
            'browserName': describeEnum(webInfo.browserName),
            'appVersion': webInfo.appVersion,
            'platform': webInfo.platform,
            'userAgent': webInfo.userAgent,
          };
        } catch (_) {}
      }
      
      // Log to console
      print('📞 CALL DEBUG: $event - $logData');
      
      // Send to Supabase for remote debugging
      await _supabase.from('call_debug_logs').insert(logData);
      
    } catch (e) {
      print('❌ Failed to log call event: $e');
    }
  }
  
  // Log WebRTC connection events
  static Future<void> logWebRTCEvent({
    required String event,
    required String callId,
    String? peerId,
    Map<String, dynamic>? webrtcData,
  }) async {
    await logCallEvent(
      event: 'webrtc_$event',
      callId: callId,
      data: {
        'peer_id': peerId,
        'webrtc_data': webrtcData,
      },
    );
  }
  
  // Log call state changes
  static Future<void> logCallStateChange({
    required String callId,
    required String fromState,
    required String toState,
    String? reason,
  }) async {
    await logCallEvent(
      event: 'call_state_change',
      callId: callId,
      data: {
        'from_state': fromState,
        'to_state': toState,
        'reason': reason,
      },
    );
  }
  
  // Log call errors
  static Future<void> logCallError({
    required String callId,
    required String error,
    String? stackTrace,
    Map<String, dynamic>? context,
  }) async {
    await logCallEvent(
      event: 'call_error',
      callId: callId,
      error: error,
      data: {
        'stack_trace': stackTrace,
        'context': context,
      },
    );
  }
  
  // Log network conditions
  static Future<void> logNetworkConditions({
    required String callId,
    required String connectionType,
    int? signalStrength,
    Map<String, dynamic>? networkInfo,
  }) async {
    await logCallEvent(
      event: 'network_conditions',
      callId: callId,
      data: {
        'connection_type': connectionType,
        'signal_strength': signalStrength,
        'network_info': networkInfo,
      },
    );
  }
  
  // Get call debug logs for a specific call
  static Future<List<Map<String, dynamic>>> getCallDebugLogs(String callId) async {
    try {
      final response = await _supabase
          .from('call_debug_logs')
          .select('*')
          .eq('call_id', callId)
          .order('timestamp', ascending: true);
      
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ Failed to get call debug logs: $e');
      return [];
    }
  }
}
