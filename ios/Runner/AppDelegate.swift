import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging
import flutter_local_notifications
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, MessagingDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Firebase'i yapılandır
    FirebaseApp.configure()
    
    // Delegeları ayarla
    Messaging.messaging().delegate = self
    UNUserNotificationCenter.current().delegate = self
    
    // Bildirim izinlerini iste
    UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .badge, .sound]
    ) { granted, error in
      guard granted else { return }
      print("Bildirim izni verildi!")
      DispatchQueue.main.async {
        application.registerForRemoteNotifications()
      }
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Firebase token güncellendiğinde
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("Firebase Token: \(fcmToken ?? "nil")")
  }
  
  // Ön plandayken bildirim geldiğinde çağrılır
  override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    if #available(iOS 14.0, *) {
      completionHandler([[.banner, .badge, .sound]])
    } else {
      completionHandler([[.alert, .badge, .sound]])
    }
  }
  
  // Bildirime tıklandığında çağrılır
  override func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    completionHandler()
  }
}
