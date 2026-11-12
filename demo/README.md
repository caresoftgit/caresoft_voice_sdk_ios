# Chạy ứng dụng mẫu iOS

Ứng dụng mẫu dùng SDK **1.2.0-libre.1** từ package đi kèm; không cần thay đổi mã gọi API khi cập nhật từ 1.0.0.

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

## 3. Đăng nhập

Nhập API URL, domain, App ID và thông tin ICE/TURN được cấp. Chọn **C2C token** để dùng token do backend cấp, hoặc endpoint HTTPS cấp token theo cấu hình ứng dụng. Không nhúng Voice API signing secret hoặc khóa APNs `.p8` vào ứng dụng phát hành.

Sau khi đăng nhập, chọn thiết bị mobile và trạng thái sẵn sàng để nhận cuộc gọi. Sử dụng số/agent được cấp quyền để thử gọi đi và nhận cuộc gọi.

## 4. Tham khảo tích hợp

Ứng dụng mẫu minh họa UI có sẵn và UI tùy chỉnh, trả lời/kết thúc, mute/hold, DTMF, chọn audio route và số gọi ra. Xem [hướng dẫn tích hợp](../docs/ios-integration-guide.md) để áp dụng vào app của bạn và [checklist](../docs/testing.md) để kiểm tra trên iPhone.

## Build trên CI không signing

```sh
xcodebuild -project demo/CaresoftVoiceDemo.xcodeproj -scheme CaresoftVoiceDemo \
  -destination 'generic/platform=iOS Simulator' ARCHS=arm64 CODE_SIGNING_ALLOWED=NO build
```

Tham số `ARCHS=arm64` áp dụng cho cả package dependencies khi dùng destination generic. Dùng cùng tham số với các scheme consumer.
