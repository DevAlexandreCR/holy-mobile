import Flutter
import UIKit
import WidgetKit

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

      // TODO: Replace with the real App Group ID configured in the Apple Developer portal.
      let appGroupId = "group.biblewidget.app"
      let widgetVerseKey = "widgetVerse" // TODO: Keep in sync with Flutter side.
      let sharedDefaults = UserDefaults(suiteName: appGroupId)

      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "saveVerse":
          if let verseJson = call.arguments as? String {
            sharedDefaults?.set(verseJson, forKey: widgetVerseKey)
            sharedDefaults?.synchronize()
            if #available(iOS 14.0, *) {
              WidgetCenter.shared.reloadAllTimelines()
            }
            result(nil)
          } else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected verse JSON string", details: nil))
          }

        case "readVerse":
          let verseJson = sharedDefaults?.string(forKey: widgetVerseKey)
          result(verseJson)

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
