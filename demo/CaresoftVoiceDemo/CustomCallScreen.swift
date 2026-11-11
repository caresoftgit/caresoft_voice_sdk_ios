import AVFoundation
import CaresoftVoice
import CaresoftVoiceUI
import SwiftUI

// Host-owned UI uses the same VoiceCall object as the SDK's drop-in view.
struct CustomCallScreen: View {
  @StateObject private var model: VoiceCallViewModel
  let agent: String
  let line: String?
  @State private var panel: Panel?
  @State private var digits = ""
  @State private var busy = false
  @State private var ending = false
  @State private var error: String?
  enum Panel { case keypad, audio }
  init(call: VoiceCall, agent: String, line: String? = nil) {
    _model = StateObject(wrappedValue: VoiceCallViewModel(call: call))
    self.agent = agent
    self.line = line
  }
  private var active: Bool { model.snapshot.state == .active }
  private var ended: Bool { model.snapshot.state == .ended }
  private var incoming: Bool {
    model.snapshot.direction == .incoming && model.snapshot.state == .ringing
  }
  private var remote: String {
    model.snapshot.remote.displayName ?? model.snapshot.remote.number ?? "Chưa có thông tin"
  }
  private var status: String {
    switch model.snapshot.state {
    case .new, .dialing: return "Đang gọi…"
    case .ringing: return incoming ? "Cuộc gọi đến" : "Đang đổ chuông…"
    case .connecting: return "Đang kết nối…"
    case .active: return model.snapshot.held ? "Đang giữ máy" : "Đang đàm thoại"
    case .ended: return "Đã kết thúc"
    }
  }
  private func run(_ action: @escaping () async throws -> Void) {
    guard !busy, !ended else { return }
    busy = true
    error = nil
    Task { @MainActor in
      defer { busy = false }
      do { try await action() } catch {
        if model.call.getSnapshot().state == .ended, let error = error as? VoiceError,
          ["OPERATION_CANCELED", "INVALID_STATE"].contains(error.code)
        {
          return
        }
        self.error = error.localizedDescription
      }
    }
  }
  private func end() {
    guard !ending else { return }
    ending = true
    Task { @MainActor in
      defer { ending = false }
      do {
        let result = incoming ? try await model.call.reject() : try await model.call.hangup()
        if !result.serverAcknowledged {
          error = "Cuộc gọi đã kết thúc trên máy; tổng đài chưa xác nhận."
        }
      } catch { self.error = error.localizedDescription }
    }
  }
  var body: some View {
    VStack(spacing: 16) {
      VStack(spacing: 14) {
        Label(
          model.snapshot.direction == .incoming ? "CUỘC GỌI ĐẾN" : "CUỘC GỌI ĐI",
          systemImage: model.snapshot.direction == .incoming ? "arrow.down.left" : "arrow.up.right"
        )
        .font(.system(size: 11, weight: .semibold)).foregroundColor(DemoColor.teal)
        Image(systemName: "person.fill").font(.system(size: 42, weight: .light))
          .frame(width: 88, height: 88).foregroundColor(DemoColor.teal).background(DemoColor.soft)
          .clipShape(Circle()).overlay(Circle().stroke(DemoColor.teal.opacity(0.08), lineWidth: 8))
          .accessibilityHidden(true)
        Text(remote).font(.system(size: 30, weight: .semibold, design: .rounded))
          .multilineTextAlignment(.center)
        if model.snapshot.remote.displayName != nil {
          Text(model.snapshot.remote.number ?? "").foregroundColor(DemoColor.muted)
        }
        Text(status).font(.subheadline.weight(.medium)).foregroundColor(DemoColor.teal)
        if model.snapshot.connectedAt != nil {
          TimelineView(.periodic(from: .now, by: 1)) { context in
            Text(
              DemoInput.duration(
                connected: model.snapshot.connectedAt, ended: model.snapshot.endedAt,
                now: context.date)
            )
            .font(.title3).monospacedDigit()
          }
        }
        if let line {
          Label(line, systemImage: "simcard").font(.caption).foregroundColor(DemoColor.muted)
        }
        Text(agent).font(.caption).foregroundColor(DemoColor.muted)
      }.frame(maxWidth: .infinity).padding(.vertical, 16)
      if !ended {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 24) {
          DemoCallControl(
            title: model.snapshot.muted ? "Bật mic" : "Tắt mic",
            symbol: model.snapshot.muted ? "mic.slash.fill" : "mic.fill",
            selected: model.snapshot.muted, disabled: !active || busy
          ) {
            run { try await model.call.setMuted(!model.snapshot.muted) }
          }
          DemoCallControl(
            title: model.snapshot.held ? "Tiếp tục" : "Giữ máy",
            symbol: model.snapshot.held ? "play.fill" : "pause.fill", selected: model.snapshot.held,
            disabled: !active || busy
          ) {
            run { try await model.call.setHeld(!model.snapshot.held) }
          }
          DemoCallControl(
            title: "Bàn phím", symbol: "circle.grid.3x3.fill", selected: panel == .keypad,
            disabled: !active || busy
          ) { panel = panel == .keypad ? nil : .keypad }
          DemoCallControl(
            title: model.audioRouteName, symbol: model.audioRouteIcon, selected: panel == .audio,
            disabled: !active || busy
          ) {
            panel = panel == .audio ? nil : .audio
            if panel == .audio { model.refreshRoutes() }
          }
        }
        if panel == .keypad && active {
          Text(digits.isEmpty ? "·" : digits).font(.title2).monospacedDigit()
          DemoKeypad(dtmf: true, disabled: busy) { digit in
            run {
              try await model.call.sendDTMF(digit)
              digits = String((digits + digit).suffix(32))
            }
          }
        }
        if panel == .audio && active {
          DemoCard(title: "Thiết bị âm thanh") {
            if model.routes.isEmpty { Text("Chưa có thiết bị âm thanh").font(.subheadline) }
            ForEach(model.routes, id: \.id) { route in
              DemoButton(
                title: (route.selected ? "✓ " : "") + route.name, tone: .light, disabled: busy
              ) {
                run {
                  try await model.call.setAudioRoute(id: route.id)
                  model.refreshRoutes()
                }
              }
            }
          }
        }
      }
      if busy { ProgressView("Đang xử lý…").font(.caption) }
      DemoNotice(message: error ?? model.error)
      if incoming {
        DemoCallControl(
          title: "Trả lời", symbol: "phone.fill", selected: true, disabled: busy || ending
        ) {
          run {
            let allowed = await withCheckedContinuation { continuation in
              AVAudioSession.sharedInstance().requestRecordPermission {
                continuation.resume(returning: $0)
              }
            }
            guard allowed else { throw VoiceError("PERMISSION_DENIED", operation: "answer") }
            try await model.call.answer()
          }
        }
      }
      if !ended {
        // Hangup remains available while answer/hold/DTMF is awaiting the server.
        DemoCallControl(
          title: incoming ? "Từ chối" : "Kết thúc", symbol: "phone.down.fill", selected: true,
          danger: true, disabled: ending, action: end)
      } else {
        Text(model.endReasonText ?? "Cuộc gọi đã kết thúc").font(.caption).foregroundColor(
          DemoColor.muted)
      }
    }
  }
}

private struct DemoCallControl: View {
  let title: String
  let symbol: String
  var selected = false
  var danger = false
  var disabled = false
  let action: () -> Void
  var body: some View {
    Button(action: action) {
      VStack(spacing: 10) {
        Image(systemName: symbol).font(.system(size: danger ? 30 : 25, weight: .medium))
          .frame(width: danger ? 76 : 66, height: danger ? 76 : 66)
          .foregroundColor(selected ? .white : DemoColor.teal)
          .background(danger ? DemoColor.red : selected ? DemoColor.teal : Color.white)
          .clipShape(Circle()).overlay(Circle().stroke(DemoColor.teal.opacity(0.1), lineWidth: 1))
        Text(title).font(.system(size: 13, weight: .medium)).foregroundColor(DemoColor.ink)
      }.frame(maxWidth: .infinity).contentShape(Rectangle())
    }.buttonStyle(.plain).disabled(disabled).opacity(disabled ? 0.4 : 1)
      .accessibilityLabel(title).accessibilityValue(selected ? "Đang bật" : "Đang tắt")
  }
}
