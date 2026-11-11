import SwiftUI
import UIKit

struct SettingsScreen: View {
  @ObservedObject var service: VoiceService
  @Binding var customUI: Bool
  let onBack: () -> Void
  @State private var diagnosticStatus: String?
  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      DemoButton(title: "Bàn phím", symbol: "chevron.left", tone: .quiet, action: onBack)
      Text("Cấu hình thoại").font(.largeTitle.bold())
      DemoCard(title: "Nhân viên") {
        Text(service.agentLabel).font(.headline)
        Text(service.configuration.domain)
        Text("API: \(service.configuration.api)").font(.caption).textSelection(.enabled)
        Text("Phiên: \(service.snapshot?.session.status.rawValue ?? "unknown")").font(.caption)
      }
      DemoCard(title: "Trạng thái thoại") {
        Text(service.availabilityLabel).font(.subheadline)
        DemoButton(
          title: "Available — đang trong ca",
          tone: service.snapshot?.availability == .available ? .primary : .light,
          disabled: service.busy
        ) { service.setAvailability(.available) }
        DemoButton(
          title: "Not available — ngoài ca",
          tone: service.snapshot?.availability == .unavailable ? .primary : .light,
          disabled: service.busy
        ) { service.setAvailability(.unavailable) }
      }
      DemoCard(title: "Thiết bị nhận thoại") {
        Text("Thiết bị hiện tại: \(service.deviceLabel)").font(.subheadline)
        DemoButton(
          title: "Nghe gọi trên Mobile", symbol: "iphone",
          tone: service.snapshot?.callDevice == .mobile ? .primary : .light, disabled: service.busy
        ) { service.selectDevice(.mobile) }
        DemoButton(
          title: "Nghe gọi trên Web", symbol: "desktopcomputer",
          tone: service.snapshot?.callDevice == .browser ? .primary : .light, disabled: service.busy
        ) { service.selectDevice(.browser) }
      }
      DemoCard(title: "Giao diện nghe gọi") {
        Picker("Giao diện nghe gọi", selection: $customUI) {
          Text("UI của SDK").tag(false)
          Text("UI tự dựng").tag(true)
        }.pickerStyle(.segmented)
        Text("Cả hai chế độ sử dụng cùng phiên và cùng cuộc gọi SDK.").font(.subheadline)
          .foregroundColor(DemoColor.muted)
      }
      DemoCard(title: "Nhận cuộc gọi đến") {
        Text(service.pushStatus).font(.subheadline)
        DemoButton(
          title: "Cấp quyền microphone", symbol: "mic", tone: .light, disabled: service.busy
        ) { service.microphonePermission() }
        DemoButton(title: "Đăng ký lại thông báo thoại", tone: .light, disabled: service.busy) {
          service.run { await service.registerPush() }
        }
        #if targetEnvironment(simulator)
          Text(
            "Simulator nghe/gọi trong app, không dùng giao diện CallKit. PushKit và chất lượng âm thanh cần nghiệm thu trên iPhone thật."
          )
          .font(.caption).foregroundColor(DemoColor.muted)
        #endif
      }
      DemoCard(title: "Nhật ký thử nghiệm") {
        DemoButton(title: "Sao chép log chẩn đoán", symbol: "doc.on.doc", tone: .light) {
          guard
            let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
              .first,
            let log = try? String(
              contentsOf: directory.appendingPathComponent("CaresoftVoiceDiagnostics.log")),
            !log.isEmpty
          else {
            diagnosticStatus = "Chưa có log chẩn đoán."
            return
          }
          UIPasteboard.general.string =
            "CaresoftVoiceDemo "
            + (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
              ?? "") + " ("
            + (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "") + ")\n"
            + log
          diagnosticStatus = "Đã sao chép log. Bạn có thể dán vào cuộc trò chuyện hỗ trợ."
        }
        if let diagnosticStatus { Text(diagnosticStatus).font(.caption) }
        if service.history.isEmpty { Text("Chưa có sự kiện.").font(.caption) }
        ForEach(Array(service.history.enumerated()), id: \.offset) { _, entry in
          Text(entry).font(.caption)
        }
      }
      DemoNotice(message: service.error)
      DemoButton(title: "Kiểm tra phiên", tone: .light, disabled: service.busy) {
        service.refreshSession()
      }
      DemoButton(
        title: "Đăng xuất", symbol: "rectangle.portrait.and.arrow.right", tone: .danger,
        disabled: service.busy
      ) { service.logout() }
    }
  }
}
