import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    do {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
      try audioSession.setActive(true)
      print("Audio session configured successfully")
    } catch {
      print("Failed to set audio session category: \(error)")
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Ensure audio session remains active in background
  override func applicationDidEnterBackground(_ application: UIApplication) {
    print("App entered background")
    do {
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      print("Failed to reactivate audio session: \(error)")
    }
  }
}