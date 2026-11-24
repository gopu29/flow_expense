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
    setupMethodChannel(messenger: registrar.messenger())
  }

  private func setupMethodChannel(messenger: FlutterBinaryMessenger) {
    guard intentChannel == nil else { return }
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "getPendingIntents":
        result(self.readPendingIntents())
      case "clearPendingIntents":
        self.clearPendingIntents()
        result(true)
      case "openURL":
        if let urlString = call.arguments as? String, let url = URL(string: urlString) {
          UIApplication.shared.open(url, options: [:], completionHandler: nil)
          result(true)
        } else {
          result(false)
        }
      case "openSettings":
        if let url = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(url, options: [:], completionHandler: nil)
          result(true)
        } else {
          result(false)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    intentChannel = channel
  }

  private func pendingIntentsURL() -> URL? {
    if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
      return containerURL.appendingPathComponent("pending_intents.json")
    }
    // Fallback for Free Apple Developer Accounts / Personal Teams (no App Groups capability)
    guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
      return nil
    }
    return docs.appendingPathComponent("pending_intents.json")
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
