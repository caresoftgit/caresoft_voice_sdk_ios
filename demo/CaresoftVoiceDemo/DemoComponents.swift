import SwiftUI
import UIKit

enum DemoColor {
  static let ink = Color(red: 18 / 255, green: 48 / 255, blue: 71 / 255)
  static let muted = Color(red: 100 / 255, green: 119 / 255, blue: 135 / 255)
  static let background = Color(red: 243 / 255, green: 246 / 255, blue: 248 / 255)
  static let teal = Color(red: 8 / 255, green: 126 / 255, blue: 117 / 255)
  static let line = Color(red: 223 / 255, green: 231 / 255, blue: 235 / 255)
  static let soft = Color(red: 229 / 255, green: 243 / 255, blue: 239 / 255)
  static let red = Color(red: 198 / 255, green: 64 / 255, blue: 70 / 255)
}

struct DemoButton: View {
  let title: String
  var symbol: String? = nil
  var tone: Tone = .primary
  var disabled = false
  let action: () -> Void
  enum Tone { case primary, light, danger, quiet }
  var body: some View {
    Button(action: action) {
      HStack(spacing: 10) {
        if let symbol { Image(systemName: symbol) }
        Text(title).font(.system(size: 16, weight: .semibold))
      }.frame(maxWidth: .infinity).padding(.horizontal, 14).padding(.vertical, 15)
        .frame(minHeight: 52)
        .foregroundColor(tone == .primary || tone == .danger ? .white : DemoColor.ink)
        .background(
          tone == .primary
            ? DemoColor.teal
            : tone == .danger ? DemoColor.red : tone == .light ? DemoColor.soft : .clear
        )
        .cornerRadius(16)
    }.buttonStyle(.plain).disabled(disabled).opacity(disabled ? 0.45 : 1)
  }
}

struct DemoCard<Content: View>: View {
  let title: String
  @ViewBuilder let content: Content
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(title.uppercased()).font(.system(size: 12, weight: .bold)).tracking(1.2).foregroundColor(
        DemoColor.muted)
      content
    }.frame(maxWidth: .infinity, alignment: .leading).padding(20).background(Color.white)
      .cornerRadius(22).overlay(RoundedRectangle(cornerRadius: 22).stroke(DemoColor.line))
  }
}

struct DemoNotice: View {
  let message: String?
  var body: some View {
    if let message, !message.isEmpty {
      Text(message).font(.subheadline).foregroundColor(
        Color(red: 133 / 255, green: 59 / 255, blue: 40 / 255)
      )
      .frame(maxWidth: .infinity, alignment: .leading).padding(14)
      .background(Color(red: 1, green: 240 / 255, blue: 234 / 255)).cornerRadius(12)
      .accessibilityIdentifier("demo.error")
    }
  }
}

struct DemoField: View {
  let title: String
  var placeholder = ""
  @Binding var text: String
  var secure = false
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title).font(.subheadline.weight(.semibold))
      Group {
        if secure {
          SecureField(placeholder, text: $text)
        } else {
          TextField(placeholder, text: $text)
        }
      }.textInputAutocapitalization(.never).autocorrectionDisabled()
        .accessibilityLabel(title).padding(14).frame(minHeight: 50)
        .background(Color.white).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(DemoColor.line))
    }
  }
}

struct DemoKeypad: View {
  var dtmf = false
  var disabled = false
  let onDigit: (String) -> Void
  private let keys = [
    ("1", ""), ("2", "ABC"), ("3", "DEF"), ("4", "GHI"), ("5", "JKL"), ("6", "MNO"), ("7", "PQRS"),
    ("8", "TUV"), ("9", "WXYZ"), ("*", ""), ("0", "+"), ("#", ""),
  ]
  var body: some View {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 10)
    {
      ForEach(keys, id: \.0) { digit, letters in
        Button {
          onDigit(digit)
        } label: {
          VStack(spacing: 2) {
            Text(digit).font(.system(size: 28)).foregroundColor(DemoColor.ink)
            Text(letters.isEmpty ? " " : letters).font(.system(size: 9)).tracking(2)
              .foregroundColor(DemoColor.muted)
          }.frame(maxWidth: .infinity).frame(height: 68).background(Color.white).cornerRadius(22)
        }.buttonStyle(.plain).accessibilityLabel("\(dtmf ? "DTMF" : "Phím") \(digit)")
          .highPriorityGesture(
            LongPressGesture().onEnded { _ in
              if !disabled { onDigit(!dtmf && digit == "0" ? "+" : digit) }
            })
      }
    }.frame(maxWidth: 320).disabled(disabled).opacity(disabled ? 0.45 : 1)
  }
}

// Preserve native selection/paste and hardware-keyboard input without showing a second keypad.
struct DemoNumberField: UIViewRepresentable {
  @Binding var number: String
  func makeUIView(context: Context) -> UITextField {
    let field = UITextField()
    field.placeholder = "Nhập số cần gọi"
    field.accessibilityLabel = "Số điện thoại"
    field.font = .systemFont(ofSize: 29)
    field.textColor = UIColor(DemoColor.ink)
    field.textAlignment = .center
    field.keyboardType = .phonePad
    field.inputView = UIView(frame: .zero)
    field.addTarget(
      context.coordinator, action: #selector(Coordinator.change(_:)), for: .editingChanged)
    field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    return field
  }
  func updateUIView(_ view: UITextField, context: Context) {
    context.coordinator.parent = self
    if view.text != number { view.text = number }
  }
  func makeCoordinator() -> Coordinator { Coordinator(self) }
  final class Coordinator: NSObject {
    var parent: DemoNumberField
    init(_ parent: DemoNumberField) { self.parent = parent }
    @objc func change(_ field: UITextField) {
      let filtered = DemoInput.phone(field.text ?? "")
      field.text = filtered
      parent.number = filtered
    }
  }
}
