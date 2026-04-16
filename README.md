# tutoro - Phần mềm quản lí giảng dạy

## Giới thiệu
**Tutoro** là ứng dụng di động được phát triển bằng Flutter, hỗ trợ quản lý hoạt động giảng dạy một cách hiệu quả và tiện lợi. Ứng dụng hướng đến giáo viên, trung tâm đào tạo và người dạy học tự do, giúp tổ chức lớp học, học viên và lịch giảng dạy một cách khoa học.

## Mục tiêu
- Hỗ trợ giáo viên quản lý lớp học dễ dàng
- Theo dõi tiến độ học tập của học viên
- Tối ưu hóa lịch giảng dạy
- Tăng hiệu quả quản lý và giảm thao tác thủ công

## Cách tạo dự án Flutter

### 1. Cài đặt Flutter
Tải Flutter SDK tại: https://flutter.dev

Kiểm tra môi trường:
```bash
flutter doctor
```

### 2. Cài đặt & chạy ứng dụng
- Clone repository
```bash
git clone https://github.com/nguyenkhanhpro/tutoro.git
cd tutoro
```

- Cài dependencies
```bash
flutter pub get
```

- Chạy ứng dụng : có thể chạy ứng dụng bằng cách bấm nút run bên phải của file main trong lib hoặc chạy câu lệnh

```bash
flutter run
```

### 3. Cấu trúc của dự án
```bash
tutoro/
│
├── lib/                # Code chính (UI, logic, state management)
├── docx/               # Tài liệu dự án
│   ├── BRD.md          # Business Requirements Document
│   └── SRS.md          # Software Requirements Specification
│
├── android/            # Native Android configuration
├── ios/                # Native iOS configuration
├── web/                # Web support
├── windows/            # Windows desktop
├── linux/              # Linux desktop
├── macos/              # macOS desktop
│
├── test/               # Unit và widget tests
│
├── pubspec.yaml        # Dependencies và cấu hình project
├── README.md           # Giới thiệu project
└── .gitignore
```

### 4.Ghi chú

- Toàn bộ logic và giao diện nằm trong thư mục lib/
- Tài liệu chi tiết:
    - Phân tích nghiệp vụ
    - Thiết kế hệ thống
    - Use case, database
        - Xem trong thư mục docx/