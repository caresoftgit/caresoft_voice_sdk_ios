# Yêu cầu tích hợp

| Thành phần | Yêu cầu |
|---|---|
| SDK | 1.2.0 |
| iOS | 15.1 trở lên |
| Ngôn ngữ ứng dụng | Swift hoặc Objective-C |
| Toolchain binary | Xcode 26.4 / Swift 6.3 |
| Thiết bị | iPhone arm64 |
| Simulator | arm64 trên Mac Apple Silicon |
| UI tùy chọn | SwiftUI hoặc UIKit qua CaresoftVoiceUI |

Đặt **Build Settings → Architectures** của target ứng dụng là `arm64`, bao gồm khi build Simulator. Chọn Simulator cụ thể trên Mac Apple Silicon; khi CI build với destination generic Simulator, truyền `ARCHS=arm64` trong lệnh `xcodebuild` để áp dụng cho cả dependency. Binary cần compiler tương thích. Nếu Xcode không đọc được module, liên hệ Caresoft để nhận gói phù hợp. Cài toàn bộ package theo [hướng dẫn](ios-integration-guide.md); không thêm lại các framework đã đi kèm. Giấy phép bên thứ ba nằm trong package.

Giữ một client/agent và một cuộc gọi tại mỗi thời điểm trong ứng dụng. Đăng nhập không tự chuyển thiết bị sang mobile hoặc trạng thái sẵn sàng. Trong đợt kiểm tra tích hợp, dùng một thiết bị đăng nhập nhận cuộc gọi cho mỗi agent; nếu cần đồng thời nhiều thiết bị, xác nhận cấu hình và phạm vi hỗ trợ với Caresoft trước khi triển khai.

PushKit và CallKit cần kiểm tra trên iPhone có signing/APNs hợp lệ. Simulator phù hợp để kiểm tra build, giao diện và logic. Hệ điều hành quyết định việc đánh thức sau force-quit; Keychain có thể chưa truy cập được trước lần mở khóa đầu tiên sau reboot.

Hoàn thành [checklist tích hợp](testing.md) trên thiết bị và hạ tầng sẽ sử dụng thực tế trước khi phát hành ứng dụng.
