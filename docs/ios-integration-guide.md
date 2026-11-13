# Caresoft Voice SDK — Hướng dẫn tích hợp iOS

**1.2.0 · iOS 15.1+ · 13/11/2026**

Hướng dẫn cài đặt SDK, cấu hình ứng dụng và triển khai cuộc gọi trên iOS bằng Swift hoặc Objective-C.

[TOC]

## 1. Phạm vi tích hợp

SDK cung cấp đăng nhập, gọi đi/nhận cuộc gọi, lưu phiên an toàn, CallKit, PushKit và giao diện cuộc gọi tùy chọn cho ứng dụng Swift hoặc Objective-C.

| Bên | Cần chuẩn bị |
|---|---|
| Caresoft | App ID, domain, thông tin kết nối, quyền gọi và cấu hình push |
| Backend của bạn | Xác thực người dùng, cấp C2C token, giữ Voice API signing secret |
| Ứng dụng iOS | Signing, quyền microphone, khởi động PushKit, giữ client và xử lý giao diện |

Giữ một client và một cuộc gọi tại mỗi thời điểm trong ứng dụng. Đăng nhập không tự chuyển agent sang thiết bị mobile hoặc trạng thái sẵn sàng. Chỉ hiển thị đã kết nối khi trạng thái cuộc gọi là `active`; theo dõi thêm trạng thái media để xử lý trường hợp mất âm thanh.

## 2. Phiếu cấu hình theo domain/build

Thu thập domain, API base HTTPS URL, appId, agent test, bundle ID, Apple Team ID, APNs key ID, môi trường APNs, installation ID ổn định, appVersionCode, ICE/TURN URLs và credential ngắn hạn. Cần hai thiết bị/số đối ứng được phép gọi để nghiệm thu.

| Giá trị | Nơi dùng | Bí mật |
|---|---|---|
| C2C token | `tokenProvider`, đăng nhập app và voice | Có, không log |
| Voice API token | Ký HS256 trên backend | Có, không nhúng production app |
| APNs VoIP registration token | Đăng ký thiết bị nhận cuộc gọi | Không đưa vào log công khai |
| APNs `.p8` | Caresoft cấu hình server | Tuyệt đối không đóng gói app |
| ICE credential | Truyền qua `VoiceOptions.iceServers` | Không log hoặc xuất diagnostics |

`environment` chỉ nhận `sandbox` hoặc `production`. Chọn theo provisioning của build đã ký, không suy từ `DEBUG`. Development entitlement dùng `development` nhưng SDK gửi `sandbox`; distribution dùng `production` ở cả hai.

<a id="admin"></a>
## 3. Đăng ký app và cấu hình push trên Caresoft

### 3.1. Tạo ứng dụng trên Caresoft

1. Đăng nhập trang quản trị trên **đúng domain và môi trường** của khách hàng.
2. Vào **Admin Settings → Cơ bản → Voice SDK**. Tài khoản cần được cấp quyền cấu hình Voice SDK; nếu không thấy mục này, liên hệ quản trị viên để được cấp quyền.
3. Tạo app với tên dễ nhận biết, ví dụ “Ứng dụng CSKH”; bật trạng thái **Hoạt động**.
4. Lưu và sao chép **App ID** do Caresoft sinh. Dùng giá trị này cho `VoiceOptions.appId`; đây không phải Apple App ID, Bundle ID hay Team ID.
5. Mở **Cấu hình push** của app, thêm cấu hình **iOS (APNs VoIP)**.

### 3.2. Chuẩn bị trên Apple Developer

1. Tạo hoặc chọn App ID có **Bundle ID trùng ứng dụng iOS**, ví dụ `com.customer.support`, và bật **Push Notifications**.
2. Tạo APNs authentication key `.p8` có quyền gửi tới ứng dụng. Ghi lại **Key ID** và **Team ID**; lưu khóa ở nơi an toàn theo quy định tải key của Apple.
3. Tạo hoặc cập nhật provisioning profile có capability Push Notifications. Trong Xcode, chọn đúng Apple Team và Bundle Identifier khi ký app.
4. Bật **Push Notifications** và **Background Modes → Voice over IP, Audio** cho target ứng dụng.

Khóa `.p8` dùng trên server để gửi APNs; không thêm khóa này vào Xcode project, gói ứng dụng hoặc Git. VoIP token được PushKit cấp trên thiết bị là giá trị khác với khóa `.p8`.

### 3.3. Điền cấu hình iOS trên Caresoft

Trong **Cấu hình push** của app vừa tạo, điền:

| Ô cấu hình | Giá trị điền |
|---|---|
| Platform | **iOS (APNs VoIP)** |
| Bundle ID | Bundle Identifier của ứng dụng, ví dụ `com.customer.support` |
| Team ID | Team ID của tài khoản Apple Developer sở hữu ứng dụng/key |
| Key ID | Key ID của APNs authentication key đã tạo |
| File credentials | File APNs authentication key **`.p8`** tương ứng |
| Environment | **`sandbox`** hoặc **`production`**, theo bảng bên dưới |
| Trạng thái | **Hoạt động** |

Lưu cấu hình. Bundle ID điền là bundle gốc, **không thêm `.voip`**; server tự dùng APNs topic `<bundle>.voip`. Lưu thành công chưa thay thế việc kiểm tra nhận cuộc gọi trên thiết bị thật.

### 3.4. Chọn đúng môi trường APNs

| Bản build | Entitlement `aps-environment` thực tế | Environment trên Caresoft | Giá trị truyền vào SDK |
|---|---|---|---|
| Ký development | `development` | `sandbox` | `.sandbox` |
| Ký distribution / TestFlight / App Store | `production` | `production` | `.production` |

Nếu dùng cả development và TestFlight, tạo **hai cấu hình iOS**, cùng Bundle ID nhưng khác environment. Chọn theo entitlement của build đã ký; không chỉ dựa vào tên Debug/Release.

Trong ứng dụng, đặt **cùng environment** cho `AppPushConfig` khi tạo client và `PushRegistration` khi đăng ký VoIP token. Ví dụ với TestFlight:

```swift
let pushConfig = AppPushConfig(
    applicationId: "com.customer.support",
    environment: .production
)
// Truyền pushConfig vào VoiceOptions khi khởi tạo client.

let registration = PushRegistration(
    token: voipToken,
    environment: .production,
    installationId: installationID,
    applicationId: "com.customer.support"
)
// Đăng ký sau khi client đã xác thực thành công.
try await client.registerPushToken(registration)
```

Thay Bundle ID bằng giá trị thực tế của ứng dụng. `voipToken` lấy từ PushKit; `installationID` là định danh cài đặt ổn định của app. Với development, đổi cả hai environment thành `.sandbox`.

Riêng ứng dụng mẫu đọc `VoicePushEnvironment` từ Info.plist để thiết lập environment. SDK không tự đọc key này; app tích hợp cần truyền đúng các giá trị API ở trên. Xem mục 6 để khởi động PushKit trước UI và mục 9 để xử lý token sau đăng nhập.

### 3.5. Sửa cấu hình, thay key hoặc ngừng sử dụng

- Giữ nguyên file credentials khi chỉ sửa metadata; upload file `.p8` mới nếu thay key.
- Các trường định danh cấu hình đã tạo được bảo vệ/read-only. Khi cần đổi định danh, tạo cấu hình phù hợp, cập nhật app rồi đăng nhập/đăng ký token lại.
- Bật cả **app** và **cấu hình push**. Cấu hình bị tắt hoặc không hợp lệ sẽ không được dùng để gửi push.
- Thay đổi cấu hình push có thể cần tới **30 giây** để có hiệu lực khi gửi cuộc gọi. Sau khi lưu, chờ khoảng thời gian này rồi kiểm tra lại.
- App không truyền `push_config_id`; server chọn cấu hình theo account/domain, App ID, iOS, Bundle ID và environment.
- Khi ngừng sử dụng app/agent, thu hồi phiên/token và ngừng định tuyến ở backend; xóa Keychain trong app không thay thế bước này.

### 3.6. Kiểm tra sau cấu hình

1. Cài build có Bundle ID và provisioning đúng trên iPhone; đăng nhập bằng App ID/domain đã cấu hình.
2. Xin quyền microphone, nhận VoIP token từ PushKit và đăng ký token sau khi client xác thực thành công.
3. Chọn thiết bị mobile và trạng thái sẵn sàng, thử nhận cuộc gọi khi app mở, ở nền và khóa màn hình.
4. Nếu gặp `INVALID_PUSH_CONFIG`, đối chiếu App ID, domain, Bundle ID, environment, trạng thái hoạt động và APNs key trên Caresoft. Không dùng token từ app hoặc môi trường khác.
5. Khi thử TestFlight, dùng cấu hình `production` ở cả server và SDK; kiểm tra lại sau khi thay key hoặc provisioning.

## 4. Cài SDK

Gói binary 1.2.0 yêu cầu iOS 15.1 trở lên. Binary được build bằng Xcode 26.4 / Swift 6.3; sử dụng toolchain tương thích. Nếu gặp lỗi compiler không đọc được module, liên hệ Caresoft để được cung cấp gói phù hợp.

```sh
git clone --branch v1.2.0 https://github.com/caresoftgit/caresoft_voice_sdk_ios.git
cd caresoft_voice_sdk_ios
python3 scripts/setup-sdk.py
```

1. Script kiểm tra SHA-256 và giải nén vào `packages/CaresoftVoice`.
2. Trong project ứng dụng, chọn **File → Add Package Dependencies → Add Local**, chọn thư mục đó.
3. Chọn product **CaresoftVoice** cho target ứng dụng; thêm **CaresoftVoiceUI** nếu cần giao diện có sẵn.
4. Trong **Build Settings → Architectures**, chọn `arm64` cho target ứng dụng (iPhone và Simulator trên Mac Apple Silicon), chọn một Simulator cụ thể trên Mac Apple Silicon rồi build. Với CI dùng destination `generic/platform=iOS Simulator`, thêm `ARCHS=arm64` vào lệnh `xcodebuild` để áp dụng cho cả package dependencies. Không thêm lại các framework đã có trong package vào cùng target.

Đưa toàn bộ thư mục package vào nơi lưu dependency của dự án và giữ đường dẫn ổn định cho máy phát triển/CI. Không chỉ sao chép riêng `CaresoftVoice.xcframework`. Có thể mở `demo/CaresoftVoiceDemo.xcodeproj` để tham khảo cách cấu hình, hoặc các scheme `ConsumerSwift` / `ConsumerObjC` để xem cách import SDK.

## 5. Xcode và signing

App host bật Push Notifications và Background Modes: Voice over IP, Audio. Thêm `NSMicrophoneUsageDescription` rõ mục đích và giữ `NSCameraUsageDescription` như template demo để đáp ứng kiểm tra quyền riêng tư khi upload. Thành phần gọi điện có tham chiếu API camera, dù demo chỉ gọi thoại và không yêu cầu quyền camera. Thiếu mô tả camera có thể gây lỗi `90683` từ Apple. Chọn provisioning với bundle ID trùng cấu hình Caresoft/APNs. Xin quyền microphone trong UI foreground trước khi cần trả lời; `checkReadiness()` chỉ đọc trạng thái, không tự hiện hộp thoại.

Simulator dùng để build/test logic và media offer; không nghiệm thu VoIP push, audio route hoặc cuộc gọi CallKit thật. Không có fallback âm thầm bỏ CallKit trên máy thật. Khi cài demo để đăng nhập trên Simulator, bật ad-hoc signing (`CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=-`) để Keychain có entitlement; xem [hướng dẫn demo](../demo/README.md#build-để-chạy-trên-simulator).

## 6. PushKit trước UI

Gọi trong `application(_:didFinishLaunchingWithOptions:)`:

```swift
CaresoftVoicePush.shared.start(appName: "Tên ứng dụng")
CaresoftVoicePush.shared.onToken = { token in
    // Giữ token mới nhất; chỉ đăng ký sau session authenticated.
}
CaresoftVoicePush.shared.onInvalidated = {
    // Unregister registration trước đó; không tự tạo token rỗng.
}
```

Nếu host đã sở hữu `PKPushRegistry`, không tạo registry thứ hai. Forward payload và completion vào `CaresoftVoicePush.shared.receive(payload.dictionaryPayload, completion: completion)` trong delegate của host. Giữ callback đúng một lần.

Native entrypoint báo CallKit sớm rồi xử lý phiên; incoming/actions được giữ tạm trước khi client attach. Không chờ tokenProvider hoặc navigation để report incoming. Không dùng `receivePush` ở UI để xử lý lại cùng PushKit callback; API đó dành cho đường forwarding chủ động/test.

VoIP push chỉ dùng cho cuộc gọi thật theo chính sách iOS. Kiểm tra nhận và hủy cuộc gọi khi ứng dụng ở nền hoặc khóa màn hình với cấu hình thực tế của bạn.

## 7. Khởi tạo client và lưu phiên

```swift
let options = VoiceOptions(
    domain: "tenant", appId: "app-id",
    apiBaseURL: URL(string: "https://api.example.test")!,
    installationId: installationID, appVersionCode: "1",
    tokenProvider: { try await yourBackend.fetchC2CToken() },
    iceServers: [IceServer(urls: ["turns:turn.example.test:443"],
                           username: turnUser, credential: turnCredential)],
    pushConfig: AppPushConfig(applicationId: Bundle.main.bundleIdentifier!,
                             environment: .sandbox)
)
let client = try CaresoftVoiceClient(options: options)
```

Mẫu `yourBackend` là service của app, không phải API SDK. Demo/consumer trong bộ bàn giao là ví dụ build được. Giữ client ở tầng service sống suốt app, không tạo trong mỗi màn hình.

Keychain mặc định: namespace domain/appId/applicationId, schema riêng iOS v1, `AfterFirstUnlockThisDeviceOnly`. Không dùng UserDefaults lưu token. App có thể inject `VoiceCredentialStore`; dữ liệu `Data` là bí mật, phải bảo vệ tương đương Keychain. Trước first unlock, Keychain có thể chưa đọc được.

## 8. Login và kiểm tra phiên

Gắn observer trước khi restore. `checkSession()` đọc/check phiên hiện có và **không gọi tokenProvider**. `unknown` khi offline/5xx/403 không được biến thành tự động logout hoặc đăng nhập lại. `connect()` gọi tokenProvider khi cần login; các connect đồng thời chia sẻ một tác vụ.

Backend của bạn xác thực người dùng và cấp C2C token. `tokenProvider` gọi dịch vụ này qua HTTPS, trả chuỗi token cho SDK. Không ký token bằng Voice API secret trong ứng dụng phát hành. Xem [cấu hình backend](backend-contract.md).

```swift
try await client.connect()
try await client.selectCallDevice(.mobile)
try await client.setAvailability(.available)
```

Chỉ chuyển trạng thái sẵn sàng khi người dùng bắt đầu nhận cuộc gọi. Kiểm tra quyền microphone và readiness trước khi gọi.

## 9. Đăng ký và thay token push

Hai ví dụ `AppPushConfig` và `PushRegistration` dùng `.sandbox` cho development. Khi phát hành TestFlight/App Store, đổi **cả hai** thành `.production`, khớp provisioning và cấu hình Caresoft. SDK nhận environment qua các API này; key `VoicePushEnvironment` trong Info.plist chỉ là cách ứng dụng mẫu đọc cấu hình.

```swift
let registration = PushRegistration(
    token: token, environment: .sandbox,
    installationId: installationID,
    applicationId: Bundle.main.bundleIdentifier!
)
try await client.registerPushToken(registration)
```

Chỉ đăng ký sau authenticated; token nhận trước login phải được giữ để đăng ký sau. Khi restore, token lưu cũ không tự làm readiness push thành ready: cần ACK đăng ký. Rotation gửi token mới; invalidation gọi `unregisterPushToken` với registration cũ chính xác. Backend cần đảm bảo registration cũ không tiếp tục routing sau rotation/revoke.

Nếu không có configured push contract, dùng Swift `VoicePushBackend` do bên tích hợp cung cấp; SDK không đoán backend legacy. Hook nhận voice credential, phải giữ kín và resolve chỉ khi server ACK thật.

## 10. Trạng thái agent, thiết bị và logout

`getAvailability` / `setAvailability(.available/.unavailable)`; `getCallDevice` / `selectCallDevice(.mobile/.browser)`. Mutations chỉ cập nhật theo ACK và readback. Gọi ra yêu cầu mobile; login không thay đổi ca làm việc. Không switch device/logout khi có active/reserved call.

`logout()` thử cả app logout và voice unregister, rồi xóa local. Kết quả có `appSession`, `voiceSession` (`confirmed`/`unconfirmed`), `localCredentials`, `errors`. HTTP 200 không đủ nếu body không ACK. Nếu xóa Keychain không thành công, nhận `LOCAL_CLEANUP_FAILED`; không tuyên bố logout sạch. `dispose()` dọn local engine/observers, giữ phiên để restore, không gọi server logout.

## 11. Gọi ra, nhận cuộc gọi, điều hướng

```swift
let subscription = client.observe { event, meta in
    switch event {
    case .incomingCall(let call), .callRestored(let call): showCall(call)
    default: break
    }
}
let call = try client.createCall(options: CallOptions(to: "123456"))
try await call.start()
```

`createCall` giữ slot ngay, chưa mở media/network call. `start` kiểm tra thiết bị và microphone rồi bắt đầu gọi. Khi nhận `.incomingCall`, hiển thị cuộc gọi và để người dùng trả lời hoặc từ chối. Chỉ trạng thái `active` xác nhận cuộc gọi đã kết nối; media có trạng thái độc lập.

Answer từ CallKit không được app gọi lại vì thấy event UI. Các answer đồng thời dùng chung task. End/reject làm local terminal ngay; kết quả server ACK riêng. Call ID local cố định, `serverCallId` đến từ metadata không đổi ID.

## 12. UI Caresoft hoặc UI riêng

```swift
import CaresoftVoiceUI
let screen = VoiceCallViewController(call: call)  // UIKit
let content = VoiceCallView(call: call)          // SwiftUI
```

UI có answer/reject/end, mute/hold, keypad DTMF, route và timer từ connectedAt. Font theo Dynamic Type, nút native có accessibility label. Cần kiểm tra VoiceOver và Bluetooth trên thiết bị thật.

Custom UI đọc snapshot, subscribe, đọc lại snapshot sau subscribe để tránh race. Giữ `VoiceSubscription`, cancel khi detach; cancel subscription/đóng màn hình không dừng call. Mute trước active cho phép khóa mic sớm; unmute chỉ active sau ACK. Hold không tự giả thay đổi trạng thái khi server timeout.

## 13. API, events và lỗi

Toàn bộ method/type/event tại [API reference](api.md). Client/call public trên MainActor; completion/delegate Objective-C trên main. Snapshots và lỗi chỉ chứa thông tin phục vụ tích hợp; không chứa token hay nội dung cuộc gọi.

`EventMeta` có clientId, callId optional, sequence tăng chung theo client, timestamp. Swift timestamp là Date; Objective-C dictionary dùng milliseconds từ Unix epoch. Không dùng event sequence làm server call ID.

## 14. Background và trạng thái OS

| Trạng thái | Cách tích hợp / giới hạn |
|---|---|
| Foreground | Xin mic trước; CallKit giữ quyền audio |
| Background/lock | PushKit report sớm; restore session; không phụ thuộc UI |
| Cold start do OS | AppDelegate khởi động native entrypoint trước UI |
| OS-killed | Cần thử push thật với provisioning và session |
| User force-quit | Không cam kết hệ điều hành sẽ đánh thức app |
| Reboot trước first unlock | Keychain có thể không truy cập được |
| GSM/interruption, Wi-Fi ↔ cellular | Media state phản ánh thực tế; không tự gọi lại |

APNs delivery, policy wakeup và quyền audio không thể chứng minh bằng simulator. Xem [checklist tích hợp](testing.md).

## 15. Build, kiểm thử và xử lý lỗi

Chạy ứng dụng trên iPhone có provisioning và APNs đúng môi trường. Kiểm tra gọi hai chiều, microphone, DTMF, loa/tai nghe, nhận cuộc gọi khi ứng dụng ở nền và khóa màn hình theo [checklist](testing.md).

| Lỗi | Kiểm tra |
|---|---|
| AUTH_REQUIRED | Session/C2C đã hết hạn hoặc server revoke; xin token qua backend |
| INVALID_PUSH_CONFIG | App/bundle/environment/tenant và cấu hình Caresoft |
| STORAGE_FAILED | Kiểm tra signing và entitlement Keychain; không cài bản Simulator build với signing tắt |
| SIP_ENGINE_ERROR | Kiểm tra kết nối SIP WebSocket/TLS; xem [hướng dẫn cấu hình TLS theo host](../demo/README.md#sip_engine_error-trên-máy-chủ-test) |
| DEVICE_NOT_MOBILE | Chọn mobile có chủ đích rồi đọc lại agentStatus |
| PERMISSION_DENIED | Microphone hoặc REST 403; không tự kết luận mất phiên |
| TIMEOUT | Kiểm tra mạng và tên operation; không tự gửi lại thao tác thay đổi trạng thái đã gửi |
| CALLKIT_FAILED | Device/signing/CallKit policy; simulator không nghiệm thu |
| MEDIA_FAILED | Kiểm tra microphone, đường âm thanh, mạng và thông tin kết nối được cấp |
| LOCAL_CLEANUP_FAILED | Keychain clear chưa được xác minh; cần xử lý tại host |

Không gửi token, khóa ký hoặc nội dung cuộc gọi khi báo lỗi. Chỉ gửi version, OS/device, safe error code, bước tái hiện và kết quả test được phép chia sẻ.

## 16. Kiểm tra trước khi phát hành

Hoàn thành [checklist tích hợp](testing.md) với App ID, Bundle ID, APNs environment và backend sẽ sử dụng thực tế. Đảm bảo dịch vụ cấp token xác thực người dùng, hỗ trợ hết hạn/thu hồi token và không ghi secret vào log.

## 17. Mẫu tích hợp

- [Swift](integration-examples/swift/Integration.swift)
- [Objective-C](integration-examples/objective-c/Consumer.m)
- [Giao diện tùy chỉnh](integration-examples/custom-ui/CustomCallView.swift)
- [Ứng dụng mẫu](../demo/README.md)

Để chọn số gọi ra, truyền ID được cấp quyền vào `CallOptions(to: number, callerId: selectedLineID)`. `VoiceCallView(call: call, lineLabel: selectedLineLabel)` hiển thị nhãn số gọi ra; nhãn không thay đổi tuyến gọi.

## 18. Chẩn đoán

Khi cần hỗ trợ, cung cấp phiên bản SDK, iOS/device, thời điểm, chiều gọi, mã lỗi và các bước tái hiện. Không gửi token, khóa APNs hoặc nội dung cuộc gọi.

Có thể bật boolean `CaresoftVoiceDiagnosticsEnabled` trong Info.plist rồi build lại để thu log chẩn đoán. Log được lưu trong cache, giới hạn 512 KiB, không tự upload. Tắt cấu hình này sau khi hoàn tất kiểm tra. Xem [các lỗi thường gặp](testing.md).
