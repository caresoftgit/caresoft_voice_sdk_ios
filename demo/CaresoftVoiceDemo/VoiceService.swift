import AVFoundation
import CaresoftVoice
import SwiftUI

@MainActor final class VoiceService: ObservableObject {
  enum Phase { case checking, signedOut, unknown, ready }
  @Published var configuration: DemoConfiguration
  @Published private(set) var phase: Phase = .checking
  @Published private(set) var client: CaresoftVoiceClient?
  @Published private(set) var snapshot: ClientSnapshot?
  @Published private(set) var call: VoiceCall?
  @Published private(set) var callSnapshot: CallSnapshot?
  @Published private(set) var busy = false
  @Published var error: String?
  @Published private(set) var callingLines: [DemoCallingLine] = []
  @Published var selectedLineId = "0"
  @Published private(set) var loadingLines = false
  @Published private(set) var linesError: String?
  @Published private(set) var callLineLabel: String?
  private var lineSelectionInitialized = false
  var selectedLineLabel: String {
    callingLines.first { $0.id == selectedLineId }?.label ?? "Mặc định tổng đài"
  }

  @Published private(set) var pushStatus = "Chưa đăng ký hoàn tất"
  @Published private(set) var history: [String] = []
  private var subscription: VoiceSubscription?
  private var callSubscription: VoiceSubscription?
  private var registration: PushRegistration?
  private var started = false
  private let settingsKey = "VoiceDemoSettings"
  let installationId: String
  private var iceStore: KeychainSessionStore {
    let safe = configuration.savedSettings
    return KeychainSessionStore(
      domain: safe["domain"]!, appId: safe["appId"]!,
      applicationId: (Bundle.main.bundleIdentifier ?? "CaresoftVoiceDemo") + ".demo-ice")
  }

  init() {
    let defaults = UserDefaults.standard
    installationId = defaults.string(forKey: "VoiceDemoInstallationID") ?? UUID().uuidString
    defaults.set(installationId, forKey: "VoiceDemoInstallationID")
    configuration = DemoConfiguration(
      saved: defaults.dictionary(forKey: settingsKey) as? [String: String] ?? [:])
  }
  var agentLabel: String {
    snapshot?.session.agent?.displayName ?? snapshot?.session.agent?.email
      ?? "Nhân viên \(snapshot?.session.agent?.id ?? configuration.agentId)"
  }
  var availabilityLabel: String {
    switch snapshot?.availability {
    case .available: return "Sẵn sàng nhận cuộc gọi"
    case .unavailable: return "Ngoài ca trực"
    default: return "Chưa đọc trạng thái"
    }
  }
  var deviceLabel: String {
    switch snapshot?.callDevice {
    case .mobile: return "Mobile"
    case .browser: return "Web"
    default: return "Thiết bị chưa rõ"
    }
  }
  func run(_ operation: @escaping @MainActor () async throws -> Void) {
    guard !busy else { return }
    busy = true
    error = nil
    Task {
      defer {
        busy = false
        refresh()
      }
      do { try await operation() } catch { self.error = error.localizedDescription }
    }
  }
  private func log(_ message: String) {
    history.insert(message, at: 0)
    history = Array(history.prefix(16))
  }
  private func refresh() {
    guard let client else { return }
    snapshot = client.getSnapshot()
    switch snapshot?.session.status {
    case .authenticated: phase = .ready
    case .unauthenticated: phase = .signedOut
    default: phase = .unknown
    }
    if let active = client.getActiveCall(), active !== call { attach(active) }
    // Retain the ended call independently of getActiveCall() until explicit dismissal.
    callSnapshot = call?.getSnapshot()
  }
  private func attach(_ value: VoiceCall) {
    guard call !== value else { return }
    callSubscription?.cancel()
    call = value
    callLineLabel =
      value.getSnapshot().direction == .incoming ? "Tổng đài chưa cung cấp line" : selectedLineLabel
    callSnapshot = value.getSnapshot()
    callSubscription = value.observe { [weak self, weak value] event, _ in
      guard let self, let value else { return }
      self.callSnapshot = value.getSnapshot()
      if case .error(let error) = event { self.error = error.localizedDescription }
    }
    log(value.getSnapshot().direction == .incoming ? "Cuộc gọi đến" : "Cuộc gọi đi")
  }
  func dismissCall() {
    guard call?.getSnapshot().state == .ended else { return }
    callSubscription?.cancel()
    callSubscription = nil
    call = nil
    callSnapshot = nil
  }
  private func configure(token: String) throws {
    let c = configuration
    let safe = c.savedSettings
    guard let api = URL(string: safe["api"]!), api.scheme == "https" else {
      throw VoiceError("INVALID_ARGUMENT", operation: "apiURL")
    }
    guard
      let rows = try JSONSerialization.jsonObject(with: Data(c.iceJSON.utf8)) as? [[String: Any]]
    else {
      throw VoiceError("INVALID_ARGUMENT", operation: "iceServers")
    }
    let ice = try rows.map { row -> IceServer in
      guard let urls = row["urls"] as? [String] else {
        throw VoiceError("INVALID_ARGUMENT", operation: "iceServers")
      }
      return IceServer(
        urls: urls, username: row["username"] as? String, credential: row["credential"] as? String)
    }
    let bundle = Bundle.main.bundleIdentifier!
    guard
      let environment = PushEnvironment(
        rawValue: Bundle.main.object(forInfoDictionaryKey: "VoicePushEnvironment") as? String ?? "")
    else {
      throw VoiceError("INVALID_ARGUMENT", operation: "pushEnvironment")
    }
    let provider: @Sendable () async throws -> String
    if c.method == .backend, let endpoint = URL(string: c.endpoint), endpoint.scheme == "https" {
      provider = {
        let (data, response) = try await URLSession.shared.data(from: endpoint)
        guard (response as? HTTPURLResponse)?.statusCode == 200, data.count < 65536,
          let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
          let value = json["token"] as? String, !value.isEmpty
        else {
          throw VoiceError("AUTH_REQUIRED", operation: "tokenProvider")
        }
        return value
      }
    } else {
      provider = {
        guard !token.isEmpty else { throw VoiceError("AUTH_REQUIRED", operation: "tokenProvider") }
        return token
      }
    }
    let voice = try CaresoftVoiceClient(
      options: VoiceOptions(
        domain: safe["domain"]!, appId: safe["appId"]!, apiBaseURL: api,
        installationId: installationId, appVersionCode: "3", tokenProvider: provider,
        iceServers: ice,
        pushConfig: AppPushConfig(applicationId: bundle, environment: environment),
        operationTimeoutMs: 45000, appName: "Caresoft Voice Demo"))
    client = voice
    subscription = voice.observe { [weak self] event, _ in
      guard let self else { return }
      switch event {
      case .incomingCall(let call), .callRestored(let call): self.attach(call)
      case .error(let error): self.error = error.localizedDescription
      default: break
      }
      self.refresh()
    }
    CaresoftVoicePush.shared.onToken = { [weak self] token in
      guard let self else { return }
      self.registration = PushRegistration(
        token: token, environment: environment, installationId: self.installationId,
        applicationId: bundle)
      if self.phase == .ready { Task { await self.registerPush() } }
    }
    CaresoftVoicePush.shared.onInvalidated = { [weak self] in
      guard let self else { return }
      let old = self.registration
      self.registration = nil
      self.pushStatus = "Token thông báo đã hết hiệu lực"
      if let old { Task { try? await self.client?.unregisterPushToken(old) } }
    }
  }
  func start() {
    guard !started else { return }
    started = true
    guard UserDefaults.standard.dictionary(forKey: settingsKey) != nil else {
      phase = .signedOut
      return
    }
    run {
      do {
        try await self.restoreICE()
        try self.configure(token: "")
        _ = try await self.client?.checkSession()
        self.refresh()
        if self.phase == .ready { await self.afterAuthentication() }
      } catch {
        self.phase = .unknown
        throw error
      }
    }
  }
  private func restoreICE() async throws {
    let saved = UserDefaults.standard.dictionary(forKey: settingsKey) as? [String: String]
    guard saved?["iceStorage"] == "keychain-v1" else { return }
    guard let data = try await iceStore.read(), let json = String(data: data, encoding: .utf8)
    else {
      throw VoiceError("INVALID_STORED_SESSION", operation: "restoreICE")
    }
    configuration.iceJSON = json
  }
  func login() {
    guard !busy else { return }
    if let message = configuration.validationError {
      error = message
      return
    }
    run {
      await self.disposeClient()
      let input = self.configuration
      defer {
        self.configuration.voiceToken = ""
        self.configuration.c2cToken = ""
      }
      let token =
        input.method == .agent
        ? try C2CTokenSigner.create(
          agentId: input.agentId.trimmingCharacters(in: .whitespacesAndNewlines),
          voiceAPIToken: input.voiceToken.trimmingCharacters(in: .whitespacesAndNewlines))
        : input.c2cToken.trimmingCharacters(in: .whitespacesAndNewlines)
      do {
        try self.configure(token: token)
        try await self.client?.connect()
        self.refresh()
        // TURN credentials belong in Keychain, not in the nonsecret demo settings.
        try await self.iceStore.write(Data(input.iceJSON.utf8))
        UserDefaults.standard.set(input.savedSettings, forKey: self.settingsKey)
        self.log("Đăng nhập thành công")
      } catch {
        await self.disposeClient()
        self.phase = .signedOut
        throw error
      }
      await self.afterAuthentication()
    }
  }
  private func afterAuthentication() async {
    if !(await requestMicrophone()) {
      error = "Chưa có quyền microphone. Bật quyền trong Cài đặt để nghe/gọi."
    }
    do { _ = try await client?.getAvailability() } catch { self.error = error.localizedDescription }
    await registerPush()
    await refreshCallingLines()
    refresh()
  }
  func refreshSession() {
    run {
      if self.client == nil {
        try await self.restoreICE()
        try self.configure(token: "")
      }
      _ = try await self.client?.checkSession()
      self.refresh()
      if self.phase == .ready { await self.afterAuthentication() }
    }
  }
  func registerPush() async {
    guard let client, client.getSnapshot().session.status == .authenticated, let registration else {
      return
    }
    pushStatus = "Đang đăng ký…"
    do {
      try await client.registerPushToken(registration)
      guard self.client === client, self.registration == registration else { return }
      pushStatus = "Đã đăng ký với tổng đài"
    } catch {
      guard self.client === client, self.registration == registration else { return }
      pushStatus = "Đăng ký thất bại: \(error.localizedDescription)"
    }
  }
  private func requestMicrophone() async -> Bool {
    await withCheckedContinuation { continuation in
      AVAudioSession.sharedInstance().requestRecordPermission { continuation.resume(returning: $0) }
    }
  }
  func microphonePermission() {
    run {
      guard await self.requestMicrophone() else {
        throw VoiceError("PERMISSION_DENIED", operation: "microphone")
      }
    }
  }
  func dial(_ number: String) {
    run {
      guard let client = self.client else { throw VoiceError("AUTH_REQUIRED", operation: "dial") }
      guard await self.requestMicrophone() else {
        throw VoiceError("PERMISSION_DENIED", operation: "microphone")
      }
      let call = try client.createCall(
        options: CallOptions(to: DemoInput.phone(number), callerId: self.selectedLineId))
      self.attach(call)
      self.callLineLabel = self.selectedLineLabel
      do { try await call.start() } catch {
        if call.getSnapshot().state == .ended, let error = error as? VoiceError,
          error.code == "OPERATION_CANCELED"
        {
          return
        }
        throw error
      }
    }
  }
  func setAvailability(_ value: DesiredAvailability) {
    run { try await self.client?.setAvailability(value) }
  }
  func selectDevice(_ value: SelectedCallDevice) {
    run { try await self.client?.selectCallDevice(value) }
  }
  func logout() {
    run {
      if let result = try await self.client?.logout(),
        result.appSession == .unconfirmed || result.voiceSession == .unconfirmed
      {
        self.error = "Đã xóa phiên trên máy; tổng đài chưa xác nhận đầy đủ đăng xuất."
      }
      try await self.iceStore.clear()
      UserDefaults.standard.removeObject(forKey: self.settingsKey)
      await self.disposeClient()
      self.configuration.voiceToken = ""
      self.configuration.c2cToken = ""
      self.phase = .signedOut
    }
  }
  func refreshCallingLines() async {
    guard !loadingLines, let client, client.getSnapshot().session.status == .authenticated else {
      return
    }
    loadingLines = true
    linesError = nil
    defer { loadingLines = false }
    do {
      let safe = configuration.savedSettings
      let store = KeychainSessionStore(
        domain: safe["domain"]!, appId: safe["appId"]!,
        applicationId: Bundle.main.bundleIdentifier!)
      guard let data = try await store.read(),
        let stored = try JSONSerialization.jsonObject(with: data) as? [String: Any],
        let c = stored["credentials"] as? [String: Any],
        let token = c["appToken"] as? String, let account = c["accountId"] as? String,
        let base = URL(string: safe["api"]!), base.scheme == "https"
      else { throw VoiceError("AUTH_REQUIRED", operation: "callingLines") }
      var request = URLRequest(
        url: base.appendingPathComponent("api/ticketCombobox/init"), timeoutInterval: 15)
      request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")
      request.setValue(account, forHTTPHeaderField: "acid")
      request.setValue(safe["domain"]!, forHTTPHeaderField: "domain")
      request.setValue("2", forHTTPHeaderField: "clientId")
      let session = URLSession(
        configuration: .ephemeral, delegate: DemoNoRedirect(), delegateQueue: nil)
      defer { session.invalidateAndCancel() }
      let (body, response) = try await session.data(for: request)
      guard (response as? HTTPURLResponse)?.statusCode == 200, body.count <= 1_048_576 else {
        throw VoiceError("REQUEST_REJECTED", operation: "callingLines")
      }
      let lines = try DemoCallingLine.parse(body)
      guard self.client === client else { return }
      callingLines = lines
      if !lineSelectionInitialized {
        selectedLineId = lines.first(where: { $0.isDefault })?.id ?? lines.first?.id ?? "0"
        lineSelectionInitialized = true
      }
      if selectedLineId != "0" && !lines.contains(where: { $0.id == selectedLineId }) {
        selectedLineId = "0"
      }
    } catch {
      guard self.client === client else { return }
      linesError = "Chưa tải được số gọi ra. Bạn có thể tải lại hoặc dùng mặc định tổng đài."
    }
  }
  private func disposeClient() async {
    callingLines = []
    lineSelectionInitialized = false
    selectedLineId = "0"
    callLineLabel = nil
    linesError = nil

    subscription?.cancel()
    subscription = nil
    callSubscription?.cancel()
    callSubscription = nil
    await client?.dispose()
    client = nil
    snapshot = nil
    call = nil
    callSnapshot = nil
    registration = nil
    pushStatus = "Chưa đăng ký hoàn tất"
    CaresoftVoicePush.shared.onToken = nil
    CaresoftVoicePush.shared.onInvalidated = nil
  }
}

struct DemoCallingLine: Identifiable, Equatable {
  let id: String
  let label: String
  let isDefault: Bool
  static func parse(_ data: Data) throws -> [DemoCallingLine] {
    guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
      let res = root["res"] as? [String: Any],
      let rows = res["lstCalloutPermission"] as? [[String: Any]]
    else {
      throw VoiceError("INVALID_RESPONSE", operation: "callingLines")
    }
    var seen = Set<String>()
    return rows.compactMap { row in
      let id = (row["callout_id"] as? String) ?? (row["callout_id"] as? NSNumber)?.stringValue
      guard let id, !id.isEmpty, id != "0",
        !id.contains(where: { $0.isWhitespace || $0.isNewline }),
        seen.insert(id).inserted
      else { return nil }
      let label = (row["descriptions"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? "Line \(id)"
      let value =
        (row["is_default"] as? NSNumber)?.intValue ?? Int(row["is_default"] as? String ?? "")
      return DemoCallingLine(id: id, label: label, isDefault: value == 1)
    }
  }
}
private final class DemoNoRedirect: NSObject, URLSessionTaskDelegate {
  func urlSession(
    _ session: URLSession, task: URLSessionTask,
    willPerformHTTPRedirection response: HTTPURLResponse,
    newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void
  ) {
    completionHandler(nil)
  }
}
