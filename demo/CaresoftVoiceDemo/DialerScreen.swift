import SwiftUI

struct DialerScreen: View {
  @ObservedObject var service: VoiceService
  @Binding var number: String
  let customUI: Bool
  let onSettings: () -> Void
  var body: some View {
    VStack(spacing: 20) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("Xin chào,").font(.subheadline).foregroundColor(DemoColor.muted)
          Text(service.agentLabel).font(.title3.bold())
        }
        Spacer()
        Button(action: onSettings) {
          Image(systemName: "gearshape").font(.title2).frame(width: 46, height: 46)
            .background(Color.white).cornerRadius(16)
        }.accessibilityLabel("Mở cấu hình")
      }
      HStack(spacing: 8) {
        Circle().fill(service.snapshot?.availability == .available ? DemoColor.teal : .orange)
          .frame(width: 7, height: 7)
        Text("\(service.availabilityLabel) · \(service.deviceLabel)").font(.caption)
        Spacer(minLength: 0)
      }.padding(12).background(DemoColor.soft).cornerRadius(12)
      VStack(spacing: 14) {
        Text("SỐ ĐIỆN THOẠI").font(.system(size: 10)).tracking(1.8).foregroundColor(DemoColor.muted)
        HStack {
          DemoNumberField(number: $number).frame(height: 48)
          Button {
            if !number.isEmpty { number.removeLast() }
          } label: {
            Image(systemName: "delete.left").font(.title2).frame(width: 44, height: 44)
          }.accessibilityLabel("Xóa một số")
            .highPriorityGesture(LongPressGesture().onEnded { _ in number = "" })
        }
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Label("Số gọi ra", systemImage: "simcard").font(.caption.weight(.semibold))
              .foregroundColor(DemoColor.muted)
            Spacer()
            Button {
              Task { await service.refreshCallingLines() }
            } label: {
              if service.loadingLines {
                ProgressView()
              } else {
                Image(systemName: "arrow.clockwise").frame(width: 32, height: 32)
              }
            }.disabled(service.loadingLines || service.busy).accessibilityLabel("Tải lại số gọi ra")
          }
          Picker("Số gọi ra", selection: $service.selectedLineId) {
            Text("Mặc định tổng đài").tag("0")
            ForEach(service.callingLines) { line in
              Text(line.label + (line.isDefault ? " · Mặc định" : "")).tag(line.id)
            }
          }.pickerStyle(.menu).tint(DemoColor.teal).disabled(service.busy)
          if let message = service.linesError {
            Text(message).font(.caption).foregroundColor(.orange)
          }
          if !service.loadingLines && service.callingLines.isEmpty && service.linesError == nil {
            Text("Tài khoản chưa có số gọi ra riêng.").font(.caption).foregroundColor(
              DemoColor.muted)
          }
        }.padding(14).background(Color.white).cornerRadius(16)
      }.padding(.top, 12)
      DemoKeypad(disabled: service.busy) { number = DemoInput.phone(number + $0) }
      DemoButton(
        title: service.busy ? "Đang xử lý…" : "Gọi điện", symbol: "phone.fill",
        disabled: number.isEmpty || service.busy
      ) {
        service.dial(number)
      }.padding(.top, 4)
      if service.snapshot?.callDevice != .mobile {
        Text("Chọn thiết bị Mobile trong cấu hình trước khi gọi.")
          .font(.caption).foregroundColor(.orange).multilineTextAlignment(.center)
      }
      DemoNotice(message: service.error)
      Text("Giao diện cuộc gọi: \(customUI ? "Tự dựng" : "Có sẵn của SDK")")
        .font(.caption2).foregroundColor(DemoColor.muted)
    }.padding(.top, 10)
  }
}
