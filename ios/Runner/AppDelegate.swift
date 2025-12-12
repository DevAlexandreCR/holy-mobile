import Flutter
import UIKit
import WidgetKit

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

          sharedDefaults.set(verseJson, forKey: WidgetSharedConfig.widgetVerseKey)
          sharedDefaults.synchronize()
          if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
          }
          result(nil)

        case "readVerse":
          result(sharedDefaults.string(forKey: WidgetSharedConfig.widgetVerseKey))

        case "refreshWidgets":
          if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
          }
          result(nil)

        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
