# Chạy ứng dụng mẫu iOS

Ứng dụng mẫu dùng SDK **1.2.0** từ package đi kèm; không cần thay đổi mã gọi API khi cập nhật từ 1.0.0.

## 1. Cài SDK và mở project

Chạy từ thư mục gốc repo:

```sh
python3 scripts/setup-sdk.py
open demo/CaresoftVoiceDemo.xcodeproj
```

Chọn scheme **CaresoftVoiceDemo** và một iPhone hoặc Simulator trên Mac Apple Silicon. Các scheme **ConsumerSwift** và **ConsumerObjC** minh họa cách import SDK.

## 2. Cấu hình ứng dụng

Trong **Signing & Capabilities**, chọn Apple Team và thay Bundle Identifier bằng ID của ứng dụng đã đăng ký với Caresoft. Bật Push Notifications, Background Modes → Voice over IP và Audio.

Debug dùng `VoicePushEnvironment=sandbox`; Release/TestFlight dùng `production`. Provisioning và cấu hình APNs phía Caresoft phải trùng môi trường này. `Config/Example.xcconfig` là mẫu tham khảo; project không tự nạp file đó.

Giữ `NSMicrophoneUsageDescription` và `NSCameraUsageDescription` trong Info.plist của app host. Thành phần gọi điện đi kèm có tham chiếu API camera nên Apple yêu cầu mô tả camera ngay cả khi demo chỉ gọi thoại; demo không yêu cầu quyền hoặc sử dụng camera. Script `scripts/check-demo-archive.py` kiểm tra cả hai purpose string trên archive trước khi upload để tránh lỗi `90683`.

Backend vẫn kiểm tra App ID, Bundle ID và environment khi đăng nhập trên Simulator, dù Simulator chưa nhận VoIP push. Với `INVALID_PUSH_CONFIG`, đối chiếu `PRODUCT_BUNDLE_IDENTIFIER` và `VOICE_PUSH_ENVIRONMENT` của target với cấu hình iOS đã đăng ký cho App ID. Bundle mặc định `com.example.CaresoftVoiceDemo` là placeholder; thay bằng bundle thực tế trước khi thử đăng nhập. Nếu môi trường test chỉ đăng ký `production`, đặt cấu hình Simulator tương ứng và `APNS_ENTITLEMENT_ENVIRONMENT=production` cho Simulator. iPhone thật cần provisioning/APNs đúng môi trường; xem [hướng dẫn push](../docs/ios-integration-guide.md).

## 3. Đăng nhập

Nhập API URL, domain, App ID và thông tin ICE/TURN được cấp. Chọn **C2C token** để dùng token do backend cấp, hoặc endpoint HTTPS cấp token theo cấu hình ứng dụng. Không nhúng Voice API signing secret hoặc khóa APNs `.p8` vào ứng dụng phát hành.

Sau khi đăng nhập, chọn thiết bị mobile và trạng thái sẵn sàng để nhận cuộc gọi. Sử dụng số/agent được cấp quyền để thử gọi đi và nhận cuộc gọi.

## 4. Tham khảo tích hợp

Ứng dụng mẫu minh họa UI có sẵn và UI tùy chỉnh, trả lời/kết thúc, mute/hold, DTMF, chọn audio route và số gọi ra. Xem [hướng dẫn tích hợp](../docs/ios-integration-guide.md) để áp dụng vào app của bạn và [checklist](../docs/testing.md) để kiểm tra trên iPhone.

## Build để chạy trên Simulator

Bật ad-hoc signing để Xcode cấp entitlement cho Keychain; không cần provisioning của iPhone thật:

```sh
xcodebuild -project demo/CaresoftVoiceDemo.xcodeproj -scheme CaresoftVoiceDemo \
  -destination 'generic/platform=iOS Simulator' ARCHS=arm64 \
  CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- build
```

Tham số `ARCHS=arm64` áp dụng cho cả package dependencies khi dùng destination generic. Dùng cùng tham số với các scheme consumer.

`CODE_SIGNING_ALLOWED=NO` chỉ dùng để kiểm tra biên dịch trên CI. Không cài bản đó để đăng nhập: app thiếu entitlement `application-identifier`/`keychain-access-groups`, khiến Keychain trả `-34018` và SDK báo `STORAGE_FAILED`. Build lại với signing bật rồi cài đè; không cần xóa phiên đã lưu.

Kiểm thử Keychain của app dùng một session giả với namespace riêng, xác minh đọc, ghi, cập nhật và xóa qua SDK:

```sh
xcodebuild -project demo/CaresoftVoiceDemo.xcodeproj -scheme CaresoftVoiceDemo \
  -destination 'platform=iOS Simulator,id=<UUID>' ARCHS=arm64 \
  CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- test
```

## SIP_ENGINE_ERROR trên máy chủ test

Nếu system log có `NSURLErrorDomain -1200` / `HANDSHAKE_FAILURE_ON_CLIENT_HELLO` tại `wss://test.caresoft.vn:10445`, lỗi xảy ra trước SIP REGISTER. Endpoint test này dùng TLS 1.2 với `AES256-GCM-SHA384` (RSA key exchange, không có Forward Secrecy), nên chính sách ATS mặc định của URLSession từ chối kết nối.

Chỉ khi dùng đúng endpoint này, thêm cấu hình sau vào dictionary `NSAppTransportSecurity` trong **Info.plist của app host** (`demo/Config/Info.plist` với demo). URL API có thể là `https://test2.caresoft.vn`; ngoại lệ phải theo hostname SIP do backend trả về, không theo URL API.

```xml
<key>NSAllowsArbitraryLoads</key>
<false/>
<key>NSExceptionDomains</key>
<dict>
    <key>test.caresoft.vn</key>
    <dict>
        <key>NSExceptionMinimumTLSVersion</key>
        <string>TLSv1.2</string>
        <key>NSExceptionRequiresForwardSecrecy</key>
        <false/>
    </dict>
</dict>
```

Ngoại lệ chỉ áp dụng cho host trên; giữ kiểm tra chứng chỉ/hostname, không bật arbitrary loads, HTTP hay wildcard subdomain. Đây là cấu hình tương thích của môi trường test, không phải thay đổi trust trong SDK. Nên nâng máy chủ lên ECDHE rồi gỡ ngoại lệ. Template demo không tự bật ngoại lệ cho khách hàng khác.

Kiểm tra WebSocket thực tế bằng test opt-in, không dùng credential, không đăng ký SIP và không phát sinh cuộc gọi:

```sh
TEST_RUNNER_CARESOFT_SIP_PREFLIGHT=1 xcodebuild \
  -project demo/CaresoftVoiceDemo.xcodeproj -scheme CaresoftVoiceDemo \
  -destination 'platform=iOS Simulator,id=<UUID>' ARCHS=arm64 \
  CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- \
  -only-testing:CaresoftVoiceDemoTests/SIPConnectivityTests test
```

Test kiểm tra HTTP 101 và WebSocket ping/pong tới endpoint test; mặc định được bỏ qua và cần mạng khi bật. Kết quả này không thay thế kiểm tra đăng ký SIP, gọi và âm thanh hai chiều.

## Archive và TestFlight

Chọn scheme **CaresoftVoiceDemo** và destination **Any iOS Device (arm64)**, đặt version/build mới, rồi **Product → Archive**. Chỉ target app được archive; target test chỉ chạy trong bước Test. Giữ mô tả microphone/camera, AppIcon và symbols đi kèm package.

Trước khi upload, chạy từ thư mục gốc repo:

```sh
python3 scripts/check-demo-archive.py /duong-dan/CaresoftVoiceDemo.xcarchive
```

Script kiểm tra purpose strings, icons, iPad, symbols và chữ ký. Khi export/upload TestFlight, Xcode ký lại bằng distribution profile: kiểm tra entitlement `aps-environment=production`, `VoicePushEnvironment=production`, Bundle ID và cấu hình Caresoft tương ứng. Archive ký development chưa phải bản phân phối cuối cùng.

Gói SDK và demo không chứa token, khóa ký hoặc cấu hình tài khoản mẫu. Nhập thông tin được cấp khi chạy app; với ứng dụng phát hành, dùng backend cấp C2C token.
