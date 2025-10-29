import 'dart:io';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lovebug/services/call_listener_service.dart';

class AndroidCallActionService {
  static const MethodChannel _channel = MethodChannel('com.lovebug.app/call_actions');
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (!Platform.isAndroid) return;
    if (_initialized) return;
    _channel.setMethodCallHandler(_handleMethodCall);
    _initialized = true;
  }

  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    try {
      if (call.method == 'handleCallAction') {
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final String action = args['action'] as String? ?? '';
        final String? callId = args['call_id'] as String?;
        final String? callerId = args['caller_id'] as String?;
        final String? matchId = args['match_id'] as String?;
        final String? callType = args['call_type'] as String?; // 'audio' | 'video'

        if (action == 'accept' && callId != null && callerId != null && matchId != null && callType != null) {
          await CallListenerService.acceptCallFromNotification(
            callId: callId,
            callerId: callerId,
            matchId: matchId,
            callType: callType,
          );
        } else if (action == 'decline' && callId != null) {
          await CallListenerService.declineCall(callId);
        }
      }
    } catch (e) {
      // Swallow errors to avoid crashing background channel
      if (Get.isLogEnable) {
        // ignore: avoid_print
        print('❌ AndroidCallActionService error: $e');
      }
    }
    return null;
  }
}


