import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let appGroupID = "group.com.quanto.flowexpense"
  private let channelName = "com.quanto.flow_expense/app_intent"
  private var intentChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// With the scene-based implicit engine there is no root view controller at
  /// launch, so the channel is registered here, once the engine exists.
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "FlowExpenseAppIntent") else {
      return
    }
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "getPendingIntents":
        result(self.readPendingIntents())
      case "clearPendingIntents":
        self.clearPendingIntents()
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    intentChannel = channel
  }

  private func pendingIntentsURL() -> URL? {
    FileManager.default
      .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
      .appendingPathComponent("pending_intents.json")
  }

  private func readPendingIntents() -> [[String: Any]] {
    guard let fileURL = pendingIntentsURL(),
          let data = try? Data(contentsOf: fileURL),
          let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
      return []
    }
    return json
  }

  private func clearPendingIntents() {
    guard let fileURL = pendingIntentsURL() else { return }
    try? FileManager.default.removeItem(at: fileURL)
  }
}
