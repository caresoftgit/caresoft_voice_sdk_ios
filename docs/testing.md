# Kiểm tra tích hợp và xử lý lỗi

## Checklist trước phát hành

- Đăng nhập, khôi phục phiên, token hết hạn và đăng xuất.
- Chuyển thiết bị sang mobile và trạng thái sẵn sàng khi người dùng yêu cầu.
- Gọi đi/nhận cuộc gọi, âm thanh hai chiều và kết thúc từ cả hai phía.
- Mute/unmute, hold/resume, DTMF, loa thoại, loa ngoài và tai nghe Bluetooth.
- Cuộc gọi kéo dài, gọi liên tiếp, từ chối, máy bận và cuộc gọi nhỡ.
- Wi-Fi, mạng di động, TURN và chuyển mạng trong cuộc gọi.
- PushKit khi app ở foreground, background, khóa màn hình và khởi động lại do OS.
- APNs sandbox trên development build và production trên bản phân phối.
- Đổi VoIP token, thu hồi phiên, nhiều thiết bị và xử lý cuộc gọi đã được trả lời ở thiết bị khác.

Chạy trên iPhone có Bundle ID, provisioning, APNs và backend của ứng dụng thực tế. Simulator phù hợp kiểm tra giao diện và logic; không thay thế thử PushKit/CallKit trên thiết bị.

## Các lỗi thường gặp

| Hiện tượng / mã lỗi | Cách kiểm tra |
|---|---|
| Xcode không tìm thấy package | Chạy `python3 scripts/setup-sdk.py`; kiểm tra local package trỏ đến `packages/CaresoftVoice` |
| Không đọc được Swift module | Dùng toolchain tương thích với Xcode 26.4 / Swift 6.3 hoặc liên hệ Caresoft |
| AUTH_REQUIRED | Kiểm tra phiên người dùng và cấp lại C2C token qua backend |
| INVALID_PUSH_CONFIG | Đối chiếu App ID, Bundle ID, APNs key và environment trên app/server |
| DEVICE_NOT_MOBILE | Chọn thiết bị mobile trước khi gọi |
| Không có tiếng | Kiểm tra quyền microphone, audio route, cấu hình kết nối và mạng |
| SIP_403 / SIP_404 | Kiểm tra quyền agent, số đích và tuyến gọi trên tổng đài |
| SIP_480 / SIP_486 | Đích tạm không sẵn sàng / máy bận |
| SIP_488 | Liên hệ Caresoft kiểm tra tuyến gọi với mã lỗi và thời điểm |
| TIMEOUT / controlMetadata | Kiểm tra kết nối mạng và tên operation; không tự gửi lại thao tác thay đổi trạng thái đã gửi |
| LOCAL_CLEANUP_FAILED | Kiểm tra kết quả xóa Keychain; thông báo cho người dùng nếu đăng xuất chưa hoàn tất |

Trong ứng dụng của bạn, đặt `AppPushConfig.environment` và `PushRegistration.environment` cùng giá trị: `.sandbox` cho development, `.production` cho TestFlight/App Store. Riêng ứng dụng mẫu đọc custom Info.plist key `VoicePushEnvironment` để cấu hình các giá trị này; SDK không tự đọc key đó. Export lại provisioning không tự đổi cấu hình environment.

Khi liên hệ hỗ trợ, gửi phiên bản SDK, phiên bản iOS, thiết bị, thời điểm, mã lỗi và các bước tái hiện. Không gửi credential, khóa ký, nội dung cuộc gọi.
