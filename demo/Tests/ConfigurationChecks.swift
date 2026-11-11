import Foundation

@main enum ConfigurationChecks {
  static func main() throws {
    var c = DemoConfiguration()
    assert(c.validationError != nil)
    assert(c.appId.isEmpty && c.api.isEmpty && c.voiceToken.isEmpty && c.c2cToken.isEmpty)
    assert(c.iceJSON == "[]" && c.method == .c2c)
    c.appId = "test-app"
    c.api = "https://example.test"
    c.method = .agent
    c.domain = " tenant "
    c.agentId = " 42 "
    c.voiceToken = "test-only"
    assert(c.validationError == nil)
    c.api = "http://example.test"
    assert(c.validationError != nil)
    c.api = "https://example.test"
    c.method = .c2c
    assert(c.validationError != nil)
    c.c2cToken = "test-c2c"
    assert(c.validationError == nil)
    c.iceJSON = #"[{"urls":["turn:example.test"],"credential":"turn-private"}]"#
    let saved = c.savedSettings
    assert(saved["iceStorage"] == "keychain-v1")
    assert(!saved.values.contains(where: { $0.contains("turn-private") }))
    assert(!saved.values.contains("test-only") && !saved.values.contains("test-c2c"))
    c.method = .backend
    c.endpoint = "http://example.test/token"
    assert(c.validationError != nil)
    c.endpoint = "https://example.test/token"
    assert(c.validationError == nil)
    let restored = DemoConfiguration(saved: [
      "appId": "test-app", "api": "https://example.test", "domain": "tenant",
    ])
    assert(restored.appId == "test-app" && restored.voiceToken.isEmpty && restored.c2cToken.isEmpty)
    assert(DemoInput.phone("+84 (123)-45x*#") == "+8412345*#")
    assert(DemoInput.phone(String(repeating: "9", count: 60)).count == 40)
    let start = Date(timeIntervalSince1970: 100)
    assert(
      DemoInput.duration(
        connected: start, ended: Date(timeIntervalSince1970: 165),
        now: Date(timeIntervalSince1970: 999)) == "01:05")
    assert(DemoInput.duration(connected: nil, ended: nil, now: start) == "00:00")
    print(
      "Demo configuration/input checks passed (validation, local defaults, secret exclusion, dialer and duration)."
    )
  }
}
