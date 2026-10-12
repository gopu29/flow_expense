import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let appGroupID = "group.com.quanto.flowexpense"
  private let channelName = "com.quanto.flow_expense/app_intent"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as? FlutterViewController
    if let messenger = controller?.binaryMessenger {
      let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)

      channel.setMethodCallHandler { [weak self] (call, result) in
        guard let self = self else { return }

        switch call.method {
        case "getPendingIntents":
          let intents = self.readPendingIntents()
          result(intents)

        case "clearPendingIntents":
          self.clearPendingIntents()
          result(true)

        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func readPendingIntents() -> [[String: Any]] {
    guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
      return []
    }
    let fileURL = containerURL.appendingPathComponent("pending_intents.json")
    guard let data = try? Data(contentsOf: fileURL),
          let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
      return []
    }
    return json
  }

  private func clearPendingIntents() {
    guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
      return
    }
    let fileURL = containerURL.appendingPathComponent("pending_intents.json")
    try? FileManager.default.removeItem(at: fileURL)
  }
}
