import CaresoftVoiceUI
import SwiftUI

struct DemoRootView: View {
  @ObservedObject var service: VoiceService
  @AppStorage("VoiceDemoCustomUI") private var customUI = false
  @State private var loginOpen = false
  @State private var settingsOpen = false
  @State private var number = ""
  private var modePicker: some View {
    Picker("Giao diện nghe gọi", selection: $customUI) {
      Text("UI của SDK").tag(false)
      Text("UI tự dựng").tag(true)
    }.pickerStyle(.segmented)
  }
  private var callFooter: some View {
    VStack(spacing: 12) {
      DemoNotice(message: service.error)
      if service.callSnapshot?.state == .ended {
        DemoButton(title: "Về bàn phím", symbol: "circle.grid.3x3.fill") { service.dismissCall() }
      }
    }
  }
  var body: some View {
    Group {
      if let call = service.call, !customUI {
        // The SDK view owns its ScrollView and needs a bounded viewport.
        VStack(spacing: 16) {
          modePicker
          VoiceCallView(call: call, lineLabel: service.callLineLabel).id(service.callSnapshot?.id)
          callFooter
        }.padding(22).frame(maxWidth: 560).frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        ScrollView {
          VStack(alignment: .leading, spacing: 20) {
            if let call = service.call {
              modePicker
              CustomCallScreen(call: call, agent: service.agentLabel, line: service.callLineLabel)
                .id(service.callSnapshot?.id)
              callFooter
            } else if service.phase == .checking {
              ProgressView("Đang kiểm tra phiên đăng nhập…").frame(maxWidth: .infinity).padding(
                .top, 80)
            } else if service.phase == .unknown {
              Text("Chưa xác minh được phiên").font(.title.bold()).padding(.top, 50)
              Text("Kiểm tra kết nối mạng rồi thử lại. Phiên chưa được xác nhận với tổng đài.")
                .foregroundColor(DemoColor.muted)
              DemoNotice(message: service.error)
              DemoButton(title: "Kiểm tra lại", disabled: service.busy) { service.refreshSession() }
              DemoButton(title: "Đăng xuất trên máy", tone: .quiet, disabled: service.busy) {
                service.logout()
              }
            } else if service.phase == .signedOut {
              LoginScreen(service: service, open: $loginOpen)
            } else if settingsOpen {
              SettingsScreen(service: service, customUI: $customUI) { settingsOpen = false }
            } else {
              DialerScreen(service: service, number: $number, customUI: customUI) {
                settingsOpen = true
              }
            }
          }.padding(22).padding(.bottom, 14).frame(maxWidth: 560).frame(maxWidth: .infinity)
        }
      }
    }.background(DemoColor.background.ignoresSafeArea()).foregroundColor(DemoColor.ink)
      .tint(DemoColor.teal).preferredColorScheme(.light)
      .sheet(isPresented: $loginOpen) { LoginForm(service: service, open: $loginOpen) }
      .onChange(of: service.phase) { phase in
        if phase == .ready { loginOpen = false }
        if phase == .signedOut { settingsOpen = false }
      }
      .onChange(of: service.callSnapshot?.id) { id in if id != nil { loginOpen = false } }
      .task { service.start() }
  }
}
