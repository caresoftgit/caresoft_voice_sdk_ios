# Cấu hình backend và xác thực

## Thông tin cần chuẩn bị

Liên hệ Caresoft để nhận domain, API base URL, App ID, quyền gọi của agent, cấu hình APNs và thông tin ICE/TURN phù hợp hạ tầng của bạn.

| Thành phần | Cấu hình |
|---|---|
| Ứng dụng iOS | App ID, domain, API URL, Bundle ID, installation ID ổn định |
| Backend của bạn | Xác thực người dùng, cấp C2C token, bảo vệ Voice API signing secret |
| Cấu hình Caresoft | Bundle ID, APNs VoIP key, môi trường sandbox/production, định tuyến cuộc gọi |

## Cấp C2C token

Ứng dụng gọi endpoint HTTPS trên backend của bạn sau khi xác thực người dùng. Backend kiểm tra quyền agent và trả token có phạm vi/thời hạn phù hợp. Trong `VoiceOptions.tokenProvider`, gọi endpoint này và trả chuỗi C2C token cho SDK.

Ví dụ response từ endpoint của bạn:

```json
{"token":"<C2C_TOKEN>"}
```

Tên endpoint và cơ chế xác thực endpoint do ứng dụng của bạn quản lý. Token không được hardcode, đưa vào URL query hoặc ghi vào log.

Nếu backend tự ký C2C theo cấu hình Caresoft: sử dụng HS256 với Voice API signing secret dạng UTF-8 raw; giữ agent ID dạng chuỗi, bao gồm số 0 đầu. Trường `expired` nếu dùng có định dạng `YYYY-MM-DD HH:mm:ss`; `callout_id` giới hạn số gọi ra. Xác nhận payload và thời gian hết hạn với Caresoft cho tenant của bạn; không tự thay bằng các trường `exp`/`iat`.

## APNs và vòng đời token

Cấu hình khóa APNs `.p8`, Key ID, Team ID và Bundle ID ở phía server. Không đưa khóa `.p8` vào ứng dụng. Development provisioning tương ứng SDK environment `sandbox`; TestFlight/App Store tương ứng `production`.

Ứng dụng nhận VoIP token từ PushKit, đăng ký sau khi phiên xác thực thành công và cập nhật khi token đổi. Backend cần ngừng định tuyến đến registration cũ khi token bị thu hồi, agent đăng xuất hoặc chuyển thiết bị.

## Kết nối mạng

REST và dịch vụ cấp token sử dụng HTTPS; SIP dùng WSS với chứng chỉ hợp lệ và TLS tương thích ATS. ICE/TURN credential nên có thời hạn và chỉ cấp cho người dùng được xác thực. Kiểm tra kết nối trên Wi-Fi và mạng di động; tránh cài thêm một bản WebRTC khác trong cùng ứng dụng.
