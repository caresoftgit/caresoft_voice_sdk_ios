#if os(iOS)
  import CaresoftVoice
  import CaresoftVoiceUI
  import SwiftUI
  @MainActor func makeBinaryConsumerView(call: VoiceCall) -> some View { VoiceCallView(call: call) }
#endif
