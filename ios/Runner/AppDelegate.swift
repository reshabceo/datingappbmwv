import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var callActionChannel: FlutterMethodChannel?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Firebase (as per Firebase console instructions)
    FirebaseApp.configure()
    
    // Set up FCM for push notifications
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      // Register actionable notification category for calls
      let accept = UNNotificationAction(
        identifier: "ACCEPT_CALL",
        title: "Accept",
        options: [.foreground]
      )
      let decline = UNNotificationAction(
        identifier: "DECLINE_CALL",
        title: "Decline",
        options: [.destructive]
      )
      let callCategory = UNNotificationCategory(
        identifier: "CALL_CATEGORY",
        actions: [accept, decline],
        intentIdentifiers: [],
        options: [.customDismissAction]
      )
      UNUserNotificationCenter.current().setNotificationCategories([callCategory])
      print("📞 CALL_CATEGORY registered")
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { _, _ in }
      )
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }
    
    application.registerForRemoteNotifications()
    
    GeneratedPluginRegistrant.register(with: self)

    // Re-assert delegate after Firebase setup in case it's overridden
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      UNUserNotificationCenter.current().delegate = self
      print("✅ Notification delegate restored after Firebase setup")
    }

    // Setup MethodChannel to communicate call actions to Flutter
    if let controller = window?.rootViewController as? FlutterViewController {
      callActionChannel = FlutterMethodChannel(
        name: "com.lovebug.app/call_actions",
        binaryMessenger: controller.binaryMessenger
      )
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Handle FCM token refresh
  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
  }
}

// Handle notifications when app is in foreground
@available(iOS 10, *)
extension AppDelegate {
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                            willPresent notification: UNNotification,
                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    print("📩 Notification category: \(notification.request.content.categoryIdentifier)")
    // Suppress banner for incoming_call in foreground; CallKit/in-app handles UI
    let userInfo = notification.request.content.userInfo
    if let type = userInfo["type"] as? String, type == "incoming_call" {
      completionHandler([])
      return
    }
    if let action = userInfo["action"] as? String, action == "incoming_call" {
      completionHandler([])
      return
    }
    // Non-call notifications can show normally
    completionHandler([[.alert, .sound, .badge]])
  }

  // Handle actionable notification taps (Accept/Decline)
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       didReceive response: UNNotificationResponse,
                                       withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    let actionId = response.actionIdentifier

    // Extract call payload
    let callId = userInfo["call_id"] as? String ?? ""
    let callerId = userInfo["caller_id"] as? String ?? ""
    let matchId = userInfo["match_id"] as? String ?? ""
    let callType = userInfo["call_type"] as? String ?? "video"
    let callerName = userInfo["caller_name"] as? String ?? "Unknown"

    if actionId == UNNotificationDefaultActionIdentifier || actionId == "ACCEPT_CALL" || actionId == "DECLINE_CALL" {
      // Ensure Flutter is ready by bringing app to foreground
      if let channel = callActionChannel {
        // Map default tap to 'open' (show in-app invite), not auto-accept
        let action: String
        if actionId == UNNotificationDefaultActionIdentifier {
          action = "open"
        } else if actionId == "DECLINE_CALL" {
          action = "decline"
        } else {
          action = "accept"
        }
        let args: [String: Any] = [
          "action": action,
          "call_id": callId,
          "caller_id": callerId,
          "match_id": matchId,
          "call_type": callType,
          "caller_name": callerName
        ]
        channel.invokeMethod("handleCallAction", arguments: args)
      }
    }

    completionHandler()
  }
}
