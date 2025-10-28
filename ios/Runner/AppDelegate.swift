import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Firebase (as per Firebase console instructions)
    FirebaseApp.configure()
    
    // Set up FCM for push notifications
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
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
    // CRITICAL FIX: Check if this is an incoming call notification
    let userInfo = notification.request.content.userInfo
    
    // Check if this is a call notification by looking at the type or action field
    if let type = userInfo["type"] as? String, type == "incoming_call" {
      print("📱 iOS: Incoming call notification detected in foreground - suppressing system notification")
      // Don't show system notification - let CallListenerService handle it with CallKit/in-app dialog
      completionHandler([])
      return
    }
    
    if let action = userInfo["action"] as? String, action == "incoming_call" {
      print("📱 iOS: Incoming call notification detected in foreground - suppressing system notification")
      // Don't show system notification - let CallListenerService handle it with CallKit/in-app dialog
      completionHandler([])
      return
    }
    
    // For non-call notifications, show the notification normally
    completionHandler([[.alert, .sound, .badge]])
  }
}
