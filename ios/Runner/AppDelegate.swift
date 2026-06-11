import Flutter
import UIKit
import AVFoundation
import Darwin

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    do {
      try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      NSLog("Failed to configure audio session: \(error)")
    }

    if let controller = window?.rootViewController as? FlutterViewController {
      let appControlChannel = FlutterMethodChannel(
        name: "dimensional/app_control",
        binaryMessenger: controller.binaryMessenger
      )
      appControlChannel.setMethodCallHandler { call, result in
        guard call.method == "exitApp" else {
          result(FlutterMethodNotImplemented)
          return
        }

        result(nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
          exit(0)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
