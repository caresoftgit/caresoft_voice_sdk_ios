import CaresoftVoice
import UIKit

@main @MainActor final class ConsumerApp: UIResponder, UIApplicationDelegate {
  var window: UIWindow?
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    let options = VoiceOptions(
      domain: "tenant", appId: "app", apiBaseURL: URL(string: "https://api.example.test")!,
      installationId: "test-install", appVersionCode: "1", tokenProvider: { "example" },
      iceServers: [])
    do {
      let client = try CaresoftVoiceClient(options: options)
      assert(client.getSnapshot().activeCall == nil)
      Task { await client.dispose() }
    } catch { assertionFailure("Local initialization failed") }
    return true
  }
}
