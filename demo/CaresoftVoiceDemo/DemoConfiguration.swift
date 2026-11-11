import Foundation

enum DemoAuthentication: String, CaseIterable {
  case agent = "Agent ID + Voice token"
  case c2c = "C2C token"
  case backend = "Backend"
}

struct DemoConfiguration {
  var domain = ""
  var appId = ""
  var api = ""
  var agentId = ""
  var voiceToken = ""
  var c2cToken = ""
  var endpoint = "https://"
  var method: DemoAuthentication = .c2c
  var iceJSON = "[]"

  init(saved: [String: String] = [:]) {
    domain = saved["domain"] ?? domain
    appId = saved["appId"] ?? appId
    api = saved["api"] ?? api
    agentId = saved["agentId"] ?? agentId
  }
  var savedSettings: [String: String] {
    // Persist only the fields needed to locate the SDK's Keychain session.
    [
      "domain": domain.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
      "appId": appId.trimmingCharacters(in: .whitespacesAndNewlines),
      "api": api.trimmingCharacters(in: .whitespacesAndNewlines), "agentId": agentId,
      "iceStorage": "keychain-v1",
    ]
  }
  var validationError: String? {
    if domain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      return "Vui lòng nhập domain Caresoft."
    }
    if appId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      return "Vui lòng nhập App ID."
    }
    if !Self.isHTTPS(api) { return "API URL phải là địa chỉ HTTPS hợp lệ." }
    switch method {
    case .agent:
      if agentId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        || voiceToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      {
        return "Vui lòng nhập Agent ID và Voice API token."
      }
    case .c2c:
      if c2cToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        return "Vui lòng nhập C2C token."
      }
    case .backend:
      if !Self.isHTTPS(endpoint) { return "Token endpoint phải dùng HTTPS." }
    }
    return nil
  }
  private static func isHTTPS(_ value: String) -> Bool {
    guard !value.contains(where: { $0.isWhitespace }), let u = URLComponents(string: value),
      u.scheme == "https", let host = u.host, !host.isEmpty,
      u.user == nil, u.password == nil
    else { return false }
    return true
  }
}

enum DemoInput {
  static func phone(_ value: String) -> String {
    String(value.filter { "+0123456789*#".contains($0) }.prefix(40))
  }
  static func duration(connected: Date?, ended: Date?, now: Date) -> String {
    let seconds = connected.map { max(0, Int((ended ?? now).timeIntervalSince($0))) } ?? 0
    return String(format: "%02d:%02d", seconds / 60, seconds % 60)
  }
}
