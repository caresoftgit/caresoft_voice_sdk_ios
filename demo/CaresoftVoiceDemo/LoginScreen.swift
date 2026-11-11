import SwiftUI

struct LoginScreen: View {
  @ObservedObject var service: VoiceService
  @Binding var open: Bool
  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      Text("C").font(.system(size: 42, weight: .bold)).foregroundColor(.white)
        .frame(width: 76, height: 76).background(DemoColor.teal).cornerRadius(24)
        .accessibilityHidden(true)
      Text("CARESOFT VOICE DEMO").font(.system(size: 11, weight: .bold)).tracking(2)
        .foregroundColor(DemoColor.teal)
      Text("Sẵn sàng cho\ncuộc gọi tiếp theo.").font(.system(size: 36, weight: .bold)).tracking(-1)
      Text("Đăng nhập bằng tài khoản Caresoft để thử gọi ra và nhận cuộc gọi từ tổng đài.")
        .font(.system(size: 16)).lineSpacing(5).foregroundColor(DemoColor.muted)
      HStack(spacing: 10) {
        Circle().fill(DemoColor.teal).frame(width: 7, height: 7)
        Text("Hai giao diện · Cùng một Voice SDK").font(.subheadline)
      }.padding(.bottom, 12)
      DemoButton(title: "Đăng nhập Caresoft", disabled: service.busy) { open = true }
      Text("API mặc định: \(service.configuration.api)").font(.caption).foregroundColor(
        DemoColor.muted
      )
      .frame(maxWidth: .infinity)
      DemoNotice(message: service.error)
    }.padding(.top, 36)
  }
}

struct LoginForm: View {
  @ObservedObject var service: VoiceService
  @Binding var open: Bool
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        HStack {
          Text("Đăng nhập Caresoft").font(.title.bold())
          Spacer()
          Button {
            open = false
          } label: {
            Image(systemName: "xmark.circle.fill").font(.title2)
          }
          .accessibilityLabel("Đóng đăng nhập").disabled(service.busy)
        }
        Text("Nhập Agent ID và Voice API token để SDK tự tạo C2C token đăng nhập.")
          .font(.subheadline).foregroundColor(DemoColor.muted)
        Picker("Phương thức đăng nhập", selection: $service.configuration.method) {
          ForEach(DemoAuthentication.allCases, id: \.self) { Text($0.rawValue).tag($0) }
        }.pickerStyle(.menu)
        DemoField(
          title: "Domain / tenant", placeholder: "domain của đơn vị",
          text: $service.configuration.domain)
        if service.configuration.method == .agent {
          DemoField(
            title: "Agent ID", placeholder: "ID nhân viên Caresoft",
            text: $service.configuration.agentId)
          DemoField(
            title: "Voice API token", placeholder: "Token voice api của đơn vị",
            text: $service.configuration.voiceToken, secure: true)
          Text("Lấy tại Admin → API → Token voice api.").font(.caption).foregroundColor(
            DemoColor.muted)
        } else if service.configuration.method == .c2c {
          DemoField(
            title: "C2C token", placeholder: "C2C token đã được cấp",
            text: $service.configuration.c2cToken, secure: true)
        } else {
          DemoField(
            title: "Token endpoint", placeholder: "https://…", text: $service.configuration.endpoint
          )
        }
        DemoField(title: "API URL", text: $service.configuration.api)
        DisclosureGroup("Cấu hình nâng cao") {
          VStack(spacing: 16) {
            DemoField(title: "App ID", text: $service.configuration.appId)
            DemoField(title: "ICE servers JSON", text: $service.configuration.iceJSON)
          }.padding(.top, 12)
        }
        DemoNotice(message: service.error)
        DemoButton(
          title: service.busy ? "Đang xác thực…" : "Đăng nhập",
          disabled: service.busy || service.configuration.validationError != nil
        ) {
          service.login()
        }
        DemoButton(title: "Để sau", tone: .quiet, disabled: service.busy) { open = false }
      }.disabled(service.busy).padding(24).padding(.top, 20).frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
    }.background(DemoColor.background).foregroundColor(DemoColor.ink)
      .interactiveDismissDisabled(service.busy)
      .onChange(of: service.configuration.method) { _ in
        service.configuration.voiceToken = ""
        service.configuration.c2cToken = ""
      }
      .onDisappear {
        service.configuration.voiceToken = ""
        service.configuration.c2cToken = ""
      }
  }
}
