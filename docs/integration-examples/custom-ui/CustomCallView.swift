import SwiftUI
import CaresoftVoice
import CaresoftVoiceUI
struct CustomCallView: View {
  @StateObject private var model: VoiceCallViewModel
  init(call: VoiceCall) { _model = StateObject(wrappedValue: VoiceCallViewModel(call: call)) }
  var body: some View {
    VStack(spacing: 20) {
      Text("Custom call screen").font(.title)
      Text(model.snapshot.remote.number ?? "Unknown")
      Text(model.snapshot.state.rawValue)
      Button("Answer") { model.perform { try await $0.answer() } }.disabled(
        model.snapshot.direction != .incoming || model.snapshot.state != .ringing)
      Button("Mute") { model.perform { try await $0.setMuted(true) } }
      Button("Hang up") { model.perform { _ = try await $0.hangup() } }
      if let error = model.error { Text(error) }
    }.padding()
  }
}
