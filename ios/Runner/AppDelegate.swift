import UIKit
import Flutter
import Firebase
import Kommunicate
@UIApplicationMain

@objc class AppDelegate: FlutterAppDelegate {
    
    override func application( _ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        GeneratedPluginRegistrant.register(with: self)
        
        // Use Firebase library to configure APIs
        //FirebaseApp.configure()
        
        Messaging.messaging().delegate = self
        
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error = error {
                    print("D'oh: \(error.localizedDescription)")
                } else {
                    DispatchQueue.main.async {
                        application.registerForRemoteNotifications()
                    }
                }
            }
        }
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        }
        
        KMPushNotificationHandler.shared.dataConnectionNotificationHandlerWith(Kommunicate.defaultConfiguration, Kommunicate.kmConversationViewConfiguration)
        let kmApplocalNotificationHandler : KMAppLocalNotification =  KMAppLocalNotification.appLocalNotificationHandler()
        kmApplocalNotificationHandler.dataConnectionNotificationHandler()
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    override func applicationDidEnterBackground(_ application: UIApplication) {
        print("APP_ENTER_IN_BACKGROUND")
        NotificationCenter.default.post(name: Notification.Name(rawValue: "APP_ENTER_IN_BACKGROUND"), object: nil)
    }

    override func applicationWillEnterForeground(_ application: UIApplication) {
        KMPushNotificationService.applicationEntersForeground()
        print("APP_ENTER_IN_FOREGROUND")
        NotificationCenter.default.post(name: Notification.Name(rawValue: "APP_ENTER_IN_FOREGROUND"), object: nil)
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    @objc func applicationWillTerminate(application: UIApplication) {
        KMDbHandler.sharedInstance().saveContext()
    }
    
    @available(iOS 10.0, *)
    override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let userInfo = notification.request.content.userInfo
        print(userInfo)
        
        let service = KMPushNotificationService()
        let dict = notification.request.content.userInfo
        
        if service.isKommunicateNotification(dict) {
            service.processPushNotification(dict, appState: UIApplication.shared.applicationState)
            completionHandler([])
            return
        } else {
            Messaging.messaging().appDidReceiveMessage(userInfo)
        }
        completionHandler([.sound, .badge, .alert])
    }
    
    @available(iOS 10.0, *)
    override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                         didReceive response: UNNotificationResponse,
                                         withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print(userInfo)
        let service = KMPushNotificationService()
        let dict = response.notification.request.content.userInfo
        if service.isApplozicNotification(dict) {
            service.processPushNotification(dict, appState: UIApplication.shared.applicationState)
        } else {
            Messaging.messaging().appDidReceiveMessage(userInfo)
        }
        completionHandler()
    }
    
    override func application(_ application: UIApplication,
                              didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                              fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult)
                                -> Void) {
        
        if let messageID = userInfo["gcmMessageIDKey"] {
            print("Message ID: \(messageID)")
        }
        print(userInfo)
        
        let service = KMPushNotificationService()
        if service.isApplozicNotification(userInfo) {
            service.processPushNotification(userInfo, appState: UIApplication.shared.applicationState)
        } else {
            Messaging.messaging().appDidReceiveMessage(userInfo)
        }
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        print("DEVICE_TOKEN_DATA :: \(deviceToken.description)")  // (SWIFT = 3) : TOKEN PARSING
        var deviceTokenString: String = ""
        for i in 0..<deviceToken.count
        {
            deviceTokenString += String(format: "%02.2hhx", deviceToken[i] as CVarArg)
        }
        print("DEVICE_TOKEN_STRING :: \(deviceTokenString)")

        if (KMUserDefaultHandler.getApnDeviceToken() != deviceTokenString)
        {
            let kmRegisterUserClientService: KMRegisterUserClientService = KMRegisterUserClientService()
            kmRegisterUserClientService.updateApnDeviceToken(withCompletion: deviceTokenString, withCompletion: { (response, error) in
                print ("REGISTRATION_RESPONSE :: \(String(describing: response))")
            })
        }
        Messaging.messaging().apnsToken = deviceToken;
    }
    
    override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for notifications: \(error.localizedDescription)")
    }
}

extension AppDelegate: MessagingDelegate {
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        
        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict
        )
    }
    
    func messaging(_ messaging: Messaging, appDidReceiveMessage message: NSDictionary) {
        print(message)
    }
}
