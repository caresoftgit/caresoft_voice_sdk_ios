# Nội dung gói cài đặt 1.0.0

| Đường dẫn | Nội dung |
|---|---|
| `packages/CaresoftVoice-1.0.0-binary.zip` | SDK binary và dependency |
| `packages/SHA256SUMS` | SHA-256 của ZIP |
| `packages/release.json` | Phiên bản, tên file, kích thước và checksum |
| `scripts/setup-sdk.py` | Kiểm tra checksum và giải nén package |
| `demo/` | Ứng dụng mẫu SwiftUI |
| `Examples/` | Ví dụ import Swift và Objective-C |
| `docs/` | Tài liệu tích hợp và API |

Sau khi chạy setup, `packages/CaresoftVoice` chứa `Package.swift`, CaresoftVoice.xcframework, WebRTC.xcframework, UI tùy chọn, dSYM, giấy phép và thông báo bên thứ ba. Thêm thư mục này bằng **Add Local Package** trong Xcode.

Giữ nguyên cấu trúc package để dependency và symbols được nhận diện. Khi archive/export ứng dụng, kiểm tra dSYM được đưa vào archive để phục vụ symbolication. Không liên kết đồng thời nhiều bản WebRTC.

Khi cập nhật SDK: tải phiên bản mong muốn, chạy lại setup, build ứng dụng và chạy [checklist tích hợp](testing.md). Script thay thế thư mục `packages/CaresoftVoice`; không đặt code tùy chỉnh của app trong thư mục này.
