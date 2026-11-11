# Caresoft Voice SDK for iOS

Tích hợp gọi điện vào ứng dụng iOS với Swift hoặc Objective-C. SDK cung cấp đăng nhập, gọi đi/nhận cuộc gọi, CallKit, PushKit và giao diện cuộc gọi tùy chọn.

**Phiên bản 1.0.0 · iOS 15.1 trở lên · Binary được build bằng Xcode 26.4 / Swift 6.3**

## Bắt đầu

1. Chuẩn bị App ID, domain, API URL và dịch vụ cấp C2C token từ backend của bạn. Liên hệ Caresoft để đăng ký ứng dụng và cấu hình APNs.
2. Tải repo và cài gói SDK:

```sh
git clone https://github.com/caresoftgit/caresoft_voice_sdk_ios.git
cd caresoft_voice_sdk_ios
python3 scripts/setup-sdk.py
```

3. Trong Xcode, chọn **File → Add Package Dependencies → Add Local**, chọn thư mục `packages/CaresoftVoice`.
4. Thêm product **CaresoftVoice** vào target ứng dụng. Thêm **CaresoftVoiceUI** nếu sử dụng giao diện cuộc gọi có sẵn.
5. Làm theo [hướng dẫn tích hợp](docs/ios-integration-guide.md) để cấu hình microphone, PushKit, đăng nhập và cuộc gọi đầu tiên.

Script cài đặt xác minh SHA-256 trước khi giải nén. Giữ nguyên cấu trúc package để Xcode liên kết đầy đủ framework và dependency. Repo này cung cấp gói cài đặt qua local Swift Package; không thêm URL repo trực tiếp vào Xcode như một remote Swift Package.

## Chạy ứng dụng mẫu

```sh
open demo/CaresoftVoiceDemo.xcodeproj
```

Chọn scheme `CaresoftVoiceDemo`, đặt Bundle Identifier và Apple Team của bạn, sau đó nhập thông tin kết nối. Xem [hướng dẫn ứng dụng mẫu](demo/README.md).

## Tài liệu

- [Hướng dẫn tích hợp từng bước](docs/ios-integration-guide.md) · [Bản HTML tải về để đọc offline](docs/caresoft-voice-ios.html)
- [API Swift / Objective-C](docs/api.md)
- [Cấu hình backend và token](docs/backend-contract.md)
- [Yêu cầu và khả năng tương thích](docs/compatibility.md)
- [Kiểm tra tích hợp và xử lý lỗi](docs/testing.md)
- [Nội dung gói cài đặt](docs/integration-delivery.md)

Voice API signing secret và khóa APNs `.p8` được cấu hình phía backend; ứng dụng nhận C2C token qua HTTPS. Giấy phép và thông báo thư viện bên thứ ba nằm trong package đã giải nén.
