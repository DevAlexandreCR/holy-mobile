import Flutter
import UIKit
import WidgetKit
import BackgroundTasks

private enum WidgetSharedConfig {
  static let appGroupId = "group.gorda.holyverso"
  static let widgetVerseKey = "widgetVerse" // Must match Flutter + Widget target.
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Registrar y programar la tarea de background para verso diario
    if #available(iOS 13.0, *) {
      DailyVerseFetchTask.shared.registerBackgroundTask()
      DailyVerseFetchTask.shared.scheduleNextFetch()
    }

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "bible_widget/shared_verse",
        binaryMessenger: controller.binaryMessenger
      )

      channel.setMethodCallHandler { call, result in
        guard let sharedDefaults = UserDefaults(suiteName: WidgetSharedConfig.appGroupId) else {
          result(
            FlutterError(
              code: "APP_GROUP_MISSING",
              message: "App Group not configured for widget sync",
              details: nil
            )
          )
          return
        }

        switch call.method {
        case "saveVerse":
          guard let verseJson = call.arguments as? String else {
            result(
              FlutterError(
                code: "INVALID_ARGUMENT",
                message: "Expected verse JSON string",
                details: nil
              )
            )
            return
          }

          print("[AppDelegate] Saving verse to App Group...")
          print("[AppDelegate] JSON: \(verseJson)")
          sharedDefaults.set(verseJson, forKey: WidgetSharedConfig.widgetVerseKey)
          let saved = sharedDefaults.synchronize()
          print("[AppDelegate] Synchronize result: \(saved)")
          
          // Verificar que se guardó correctamente
          if let readBack = sharedDefaults.string(forKey: WidgetSharedConfig.widgetVerseKey) {
            print("[AppDelegate] Verification - Data saved correctly")
          } else {
            print("[AppDelegate] ERROR - Data not saved!")
          }
          
          if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
            print("[AppDelegate] Widgets reloaded")
          }
          result(nil)

        case "readVerse":
          result(sharedDefaults.string(forKey: WidgetSharedConfig.widgetVerseKey))

        case "refreshWidgets":
          if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
          }
          result(nil)

        case "requestImmediateUpdate":
          // Solicitar una actualización inmediata del background task
          if #available(iOS 13.0, *) {
            DailyVerseFetchTask.shared.scheduleNextFetch(retryInHour: false, immediate: true)
          }
          result(nil)

        default:
          result(FlutterMethodNotImplemented)
        }
      }
      
      // Channel para guardar JWT token en App Group compartido
      let authChannel = FlutterMethodChannel(
        name: "bible_widget/auth",
        binaryMessenger: controller.binaryMessenger
      )
      
      authChannel.setMethodCallHandler { call, result in
        guard let sharedDefaults = UserDefaults(suiteName: WidgetSharedConfig.appGroupId) else {
          result(
            FlutterError(
              code: "APP_GROUP_MISSING",
              message: "App Group not configured",
              details: nil
            )
          )
          return
        }
        
        switch call.method {
        case "saveJwtToken":
          guard let token = call.arguments as? String else {
            result(
              FlutterError(
                code: "INVALID_ARGUMENT",
                message: "Expected JWT token string",
                details: nil
              )
            )
            return
          }
          
          sharedDefaults.set(token, forKey: "jwt_token")
          sharedDefaults.synchronize()
          result(nil)
          
        case "clearJwtToken":
          sharedDefaults.removeObject(forKey: "jwt_token")
          sharedDefaults.synchronize()
          result(nil)
          
        case "setApiUrl":
          guard let apiUrl = call.arguments as? String else {
            result(
              FlutterError(
                code: "INVALID_ARGUMENT",
                message: "Expected API URL string",
                details: nil
              )
            )
            return
          }
          
          sharedDefaults.set(apiUrl, forKey: "api_url")
          sharedDefaults.synchronize()
          result(nil)
          
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
