import CaresoftVoice
import SwiftUI
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    CaresoftVoicePush.shared.start(appName: "Caresoft Voice Demo")
    return true
  }
}

@main struct DemoApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
  @StateObject private var service = VoiceService()
  var body: some Scene { WindowGroup { DemoRootView(service: service) } }
}
