# 📘 SRS — Hệ thống Quản lý Giảng dạy Tutoro

**Hệ thống**: Tutoro – Learning Management System  
**Phiên bản**: 1.0  
**Ngôn ngữ giao diện**: Tiếng Việt (mặc định), English  
**Công nghệ**: Flutter (Mobile) + Backend API (.NET / NodeJS)  

| Thông tin tài liệu | |
|---|---|
| **Tác giả** | PM Team |
| **Ngày tạo** | 23/04/2026 |
| **Dựa trên** | BRD Tutoro v1.0 |
| **Trạng thái** | Draft |

---

## 1. Tổng quan hệ thống

Tutoro là hệ thống hỗ trợ **quản lý hoạt động giảng dạy tại trung tâm lập trình**, bao gồm:

- Quản lý lớp học
- Quản lý giảng viên
- Quản lý học viên
- Lịch dạy
- Điểm danh
- Nhắc lịch học

---

### 👥 Vai trò hệ thống

| Vai trò | Quyền hạn |
|--------|---------|
| **Admin** | Quản lý toàn bộ hệ thống |
| **Giảng viên (Teacher)** | Xem lịch dạy, điểm danh |
| **Học viên (Student)** | Xem lịch học, nhận thông báo |

---

### ⚙️ Đặc điểm kỹ thuật

- Online-first (có thể cache offline)
- Dữ liệu lưu trên server (REST API)
- Notification: Push Notification
- Authentication: JWT
- Multi-user system
- Time lấy từ server + device sync

---

## 2. Danh sách yêu cầu (Functional Requirements)

---

### REQ-01: Đăng nhập / Authentication

| Mục | Nội dung |
|-----|---------|
| Mô tả | Người dùng đăng nhập hệ thống |
| Input | Email, mật khẩu |
| Quy tắc | Đúng → cấp JWT token |
| Lỗi | Sai thông tin / thiếu dữ liệu |
| Output | Điều hướng theo role |

---

### REQ-02: Quản lý lớp học

| Mục | Nội dung |
|-----|---------|
| Mô tả | Admin tạo và quản lý lớp học |
| Input | Tên lớp, khóa học, giảng viên |
| Chức năng | CRUD |
| Output | Danh sách lớp |

---

### REQ-03: Quản lý học viên

| Mục | Nội dung |
|-----|---------|
| Mô tả | Quản lý thông tin học viên |
| Input | Tên, email, số điện thoại |
| Quy tắc | Email unique |
| Output | Danh sách học viên |

---

### REQ-04: Quản lý giảng viên

| Mục | Nội dung |
|-----|---------|
| Mô tả | Quản lý thông tin giảng viên |
| Input | Tên, chuyên môn |
| Output | Danh sách giảng viên |

---

### REQ-05: Quản lý lịch học / Teaching Schedule

| Mục | Nội dung |
|-----|---------|
| Mô tả | Tạo và quản lý lịch học |
| Input | Lớp, thời gian, phòng |
| Quy tắc | Không trùng lịch |
| Output | Hiển thị theo ngày/tuần |

---

### REQ-06: Xem lịch (Student & Teacher)

| Mục | Nội dung |
|-----|---------|
| Mô tả | Người dùng xem lịch |
| Filter | Theo user |
| Sắp xếp | Theo thời gian |
| Không có | Hiển thị rỗng |

---

### REQ-07: Điểm danh / Attendance

| Mục | Nội dung |
|-----|---------|
| Mô tả | Giảng viên điểm danh học viên |
| Input | Trạng thái: Có mặt / Vắng |
| Output | Lưu vào hệ thống |

---

### REQ-08: Notification

| Mục | Nội dung |
|-----|---------|
| Mô tả | Nhắc lịch học |
| Thời gian | Trước 15 phút |
| Cơ chế | Push notification |
| Nội dung | "Sắp đến giờ học [Tên lớp]" |

---

### REQ-09: Tìm kiếm

| Mục | Nội dung |
|-----|---------|
| Mô tả | Tìm lớp / học viên |
| Quy tắc | Không phân biệt hoa/thường |
| Output | Danh sách kết quả |

---

### REQ-10: Quản lý tài khoản

| Mục | Nội dung |
|-----|---------|
| Mô tả | Quản lý thông tin user |
| Bảo mật | Hash password |
| Phân quyền | Theo role |

---

## 3. Yêu cầu phi chức năng (NFR)

| Mã | Yêu cầu |
|----|--------|
| NFR-01 | Response < 2s |
| NFR-02 | UI thân thiện |
| NFR-03 | Bảo mật JWT |
| NFR-04 | Scale > 1000 users |
| NFR-05 | Notification ổn định |

---

## 4. Mô hình dữ liệu

```json
User {
  id: string,
  email: string,
  password: string,
  role: string
}

Class {
  id: string,
  name: string,
  teacher_id: string
}

Schedule {
  id: string,
  class_id: string,
  time: datetime,
  room: string
}

Attendance {
  id: string,
  student_id: string,
  schedule_id: string,
  status: string
}
