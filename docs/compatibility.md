# Yêu cầu và khả năng tương thích

| Thành phần | Yêu cầu |
|---|---|
| iOS | 15.1 trở lên |
| Ngôn ngữ ứng dụng | Swift hoặc Objective-C |
| Toolchain binary | Xcode 26.4 / Swift 6.3 |
| Thiết bị | arm64 |
| Simulator | arm64 / x86_64 |
| UI tùy chọn | SwiftUI hoặc UIKit wrapper qua CaresoftVoiceUI |

Binary Swift module cần compiler tương thích. Nếu Xcode không đọc được module, liên hệ Caresoft để nhận gói phù hợp phiên bản Xcode của bạn.

Package chứa WebRTC 124.0.2; Socket.IO Swift 16.1.1 và Starscream 4.0.8 được liên kết trong core. Không liên kết thêm bản WebRTC khác vào cùng ứng dụng. Giấy phép bên thứ ba nằm trong `Licenses/` của package.

SDK hỗ trợ một client/agent và một cuộc gọi được giữ chỗ trong mỗi process. Đăng nhập không tự chuyển thiết bị sang mobile hoặc trạng thái sẵn sàng.

PushKit và CallKit cần kiểm tra trên iPhone có signing/APNs hợp lệ. Simulator sử dụng audio trong ứng dụng, không thay thế kiểm tra cuộc gọi hệ thống. Hệ điều hành quyết định việc đánh thức sau force-quit; Keychain có thể chưa truy cập được trước lần mở khóa đầu tiên sau reboot.

SDK thu thập ICE trước khi gửi SDP, thời gian chờ tối đa 10 giây. Hạ tầng cần tương thích SIP-over-WSS; 100rel/PRACK và offerless in-dialog INVITE không được hỗ trợ. Kiểm tra TURN, mạng di động và chuyển mạng theo [checklist](testing.md) với hệ thống của bạn.
