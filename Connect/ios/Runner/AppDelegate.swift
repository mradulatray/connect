import UIKit
import Flutter
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
      _ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    print("🚀 AppDelegate didFinishLaunchingWithOptions called")

    // Firebase setup
    FirebaseApp.configure()

    // Notification setup
    setupNotifications(application)

    // Method channel setup
    setupMethodChannel()

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func setupNotifications(_ application: UIApplication) {
    let center = UNUserNotificationCenter.current()
    center.delegate = self

    center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
      if let error = error {
        print("⚠️ Notification permission error: \(error)")
      } else {
        print("✅ Push permission granted: \(granted)")
        if granted {
          DispatchQueue.main.async {
            application.registerForRemoteNotifications()
          }
        }
      }
    }

    // Set Firebase messaging delegate
    Messaging.messaging().delegate = self
  }

  private func setupMethodChannel() {
    if let controller = window?.rootViewController as? FlutterViewController {
      let badgeChannel = FlutterMethodChannel(
          name: "com.connect/iosBadge",
          binaryMessenger: controller.binaryMessenger
      )

      badgeChannel.setMethodCallHandler { [weak self] call, result in
        switch call.method {
        case "updateBadge":
          if let args = call.arguments as? [String: Any],
             let count = args["count"] as? Int {
            DispatchQueue.main.async {
              UIApplication.shared.applicationIconBadgeNumber = count
              print("🔢 [iOS] Badge count updated → \(count)")
            }
            result(nil)
          } else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for updateBadge", details: nil))
          }

        case "getBadge":
          let currentBadge = UIApplication.shared.applicationIconBadgeNumber
          print("🔢 [iOS] Current badge count → \(currentBadge)")
          result(currentBadge)

        case "syncBadgeFromNative":
          let currentBadge = UIApplication.shared.applicationIconBadgeNumber
          print("🔢 [iOS] Syncing badge from native → \(currentBadge)")
          badgeChannel.invokeMethod("onBadgeSynced", arguments: ["count": currentBadge])
          result(currentBadge)

        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
  }

  override func application(_ application: UIApplication,
                            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
    print("📦 APNs token registered with Firebase.")
  }

  override func application(_ application: UIApplication,
                            didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("❌ Failed to register for remote notifications: \(error)")
  }

  // Handle background notifications
  override func application(_ application: UIApplication,
                            didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                            fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    print("📱 Background notification received")

    if let aps = userInfo["aps"] as? [String: Any],
       let badge = aps["badge"] as? Int {
      print("🔢 [iOS Background] Setting badge from APS → \(badge)")
      DispatchQueue.main.async {
        UIApplication.shared.applicationIconBadgeNumber = badge
      }
    }

    completionHandler(.newData)
  }

  // Handle notification tap
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       didReceive response: UNNotificationResponse,
                                       withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    print("📬 User tapped notification")

    // Decrement badge on tap
    let currentBadge = UIApplication.shared.applicationIconBadgeNumber
    if currentBadge > 0 {
      let newBadge = currentBadge - 1
      UIApplication.shared.applicationIconBadgeNumber = newBadge
      print("🔢 [iOS Tap] Decremented badge → \(newBadge)")
    }

    // Forward to Flutter
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: "plugins.flutter.io/firebase_messaging",
                                         binaryMessenger: controller.binaryMessenger)
      channel.invokeMethod("Messaging#onMessageOpenedApp", arguments: ["data": userInfo])
    }

    completionHandler()
  }

  // Handle foreground notifications
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       willPresent notification: UNNotification,
                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    let userInfo = notification.request.content.userInfo
    print("📱 Foreground notification received")

    // Update badge if present
    if let aps = userInfo["aps"] as? [String: Any],
       let badge = aps["badge"] as? Int {
      UIApplication.shared.applicationIconBadgeNumber = badge
      print("🔢 [iOS Foreground] Setting badge → \(badge)")
    }

    completionHandler([.banner, .badge, .sound])
  }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("📲 New FCM token: \(fcmToken ?? "nil")")
  }
}