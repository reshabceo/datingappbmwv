import 'package:lovebug/services/push_notification_service.dart';

/// Test script for call notifications
/// Run this to test all call notification types
void main() async {
  print('🧪 Testing Call Notifications...\n');

  // Test user ID (replace with actual user ID)
  const testUserId = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b';
  const testCallId = 'test-call-123';
  const testCallerName = 'Test User';

  try {
    // Test 1: Incoming Audio Call
    print('📞 Testing Incoming Audio Call...');
    final audioResult = await PushNotificationService.sendIncomingCallNotification(
      userId: testUserId,
      callerName: testCallerName,
      callId: testCallId,
      callType: 'audio',
    );
    print('✅ Audio call notification: ${audioResult ? "Sent" : "Failed"}\n');

    // Wait a bit between tests
    await Future.delayed(Duration(seconds: 2));

    // Test 2: Incoming Video Call
    print('📹 Testing Incoming Video Call...');
    final videoResult = await PushNotificationService.sendIncomingCallNotification(
      userId: testUserId,
      callerName: testCallerName,
      callId: testCallId,
      callType: 'video',
    );
    print('✅ Video call notification: ${videoResult ? "Sent" : "Failed"}\n');

    // Wait a bit between tests
    await Future.delayed(Duration(seconds: 2));

    // Test 3: Missed Audio Call
    print('📞 Testing Missed Audio Call...');
    final missedAudioResult = await PushNotificationService.sendMissedCallNotification(
      userId: testUserId,
      callerName: testCallerName,
      callType: 'audio',
    );
    print('✅ Missed audio call notification: ${missedAudioResult ? "Sent" : "Failed"}\n');

    // Wait a bit between tests
    await Future.delayed(Duration(seconds: 2));

    // Test 4: Missed Video Call
    print('📹 Testing Missed Video Call...');
    final missedVideoResult = await PushNotificationService.sendMissedCallNotification(
      userId: testUserId,
      callerName: testCallerName,
      callType: 'video',
    );
    print('✅ Missed video call notification: ${missedVideoResult ? "Sent" : "Failed"}\n');

    // Wait a bit between tests
    await Future.delayed(Duration(seconds: 2));

    // Test 5: Call Ended
    print('📞 Testing Call Ended...');
    final endedResult = await PushNotificationService.sendCallEndedNotification(
      userId: testUserId,
      callerName: testCallerName,
      callType: 'audio',
      duration: '2m 30s',
    );
    print('✅ Call ended notification: ${endedResult ? "Sent" : "Failed"}\n');

    // Wait a bit between tests
    await Future.delayed(Duration(seconds: 2));

    // Test 6: Call Rejected
    print('📞 Testing Call Rejected...');
    final rejectedResult = await PushNotificationService.sendCallRejectedNotification(
      userId: testUserId,
      callerName: testCallerName,
      callType: 'video',
    );
    print('✅ Call rejected notification: ${rejectedResult ? "Sent" : "Failed"}\n');

    print('🎉 All call notification tests completed!');
    print('\n📱 Check your device for notifications:');
    print('   • Incoming calls should show with Answer/Decline actions');
    print('   • Missed calls should appear in notification history');
    print('   • Call ended should show duration');
    print('   • Call rejected should show decline message');

  } catch (e) {
    print('❌ Test failed with error: $e');
  }
}
