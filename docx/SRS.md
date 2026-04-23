# SRS — Hệ thống Quản lý Giảng dạy Tutoro

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

### Vai trò hệ thống

| Vai trò | Quyền hạn |
|--------|---------|
| **Admin** | Quản lý toàn bộ hệ thống |
| **Giảng viên (Teacher)** | Xem lịch dạy, điểm danh |
| **Học viên (Student)** | Xem lịch học, nhận thông báo |

---

### Đặc điểm kỹ thuật

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

Student {
  id: string,
  name: string,
  email: string
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
```
---

## 5. Dữ liệu ban đầu / Seed Data

### 5.1. Tài khoản / Accounts

| Email | Mật khẩu | Vai trò | ID |
|-------|----------|---------|-----|
| `admin@tutoro.com` | `123456` | Admin | ADMIN001 |
| `teacher1@tutoro.com` | `123456` | Teacher | TCH001 |
| `student1@tutoro.com` | `123456` | Student | STD001 |

---

### 5.2. Lớp học / Classes

| ID | Tên lớp | Giảng viên | Khóa học |
|----|--------|-----------|----------|
| CLS001 | Flutter Basic | TCH001 | Mobile Development |
| CLS002 | Web Fullstack | TCH001 | Web Development |

---

### 5.3. Lịch học / Schedules

| ID | Lớp | Thời gian | Phòng |
|----|-----|-----------|-------|
| SCH001 | CLS001 | 2026-04-25 07:00 | A1 |
| SCH002 | CLS001 | 2026-04-27 07:00 | A1 |
| SCH003 | CLS002 | 2026-04-26 18:00 | B2 |

---

### 5.4. Tham số hệ thống / System Parameters

| Tham số | Giá trị |
|---------|---------|
| Thời gian nhắc mặc định | **15 phút trước giờ học** |
| Timezone | **UTC+7** |
| Định dạng thời gian | **YYYY-MM-DD HH:mm** |

---

## 6. Giao diện hệ thống / System Interface

### 6.1. Màn hình chính (sau đăng nhập)

| Tab | Mô tả |
|-----|------|
| **Dashboard** | Tổng quan hệ thống |
| **Lịch học** | Hiển thị lịch theo ngày/tuần |
| **Lớp học** | Danh sách lớp |
| **Tài khoản** | Thông tin người dùng |

---

### 6.2. Màn hình chức năng

| Màn hình | Mô tả |
|----------|------|
| Login | Đăng nhập |
| Dashboard | Tổng quan |
| Class Management | Quản lý lớp |
| Schedule | Quản lý lịch |
| Attendance | Điểm danh |
| User Management | Quản lý user |

---

## 7. Ràng buộc kỹ thuật / Technical Constraints

1. **Online-first** — Hệ thống yêu cầu kết nối internet
2. **Backend API** — Giao tiếp qua REST API
3. **Authentication** — JWT token
4. **Multi-user** — Hỗ trợ nhiều người dùng
5. **Platform** — Mobile (Flutter)
6. **Push Notification** — Firebase Cloud Messaging
7. **Time Sync** — Đồng bộ server time

---

## 8. Thiết kế dữ liệu / Data Design

### 8.1. Bảng Users

```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE,
  password TEXT,
  role TEXT
);
```
## 9. Luồng xử lý chính

### 9.1. Xem lịch

- User đăng nhập
- Gọi API lấy schedule theo user
- Hiển thị danh sách

---

### 9.2. Tạo lịch học

- Admin nhập:
  - Lớp học
  - Thời gian
  - Phòng học
- Validate:
  - Không trùng lịch
- Lưu vào database
- Cập nhật UI

---

### 9.3. Điểm danh

- Giảng viên chọn lớp
- Hiển thị danh sách học viên
- Tick trạng thái:
  - Present (Có mặt)
  - Absent (Vắng)
- Lưu dữ liệu

---

### 9.4. Notification

- Khi có lịch học:
  - Lấy thời gian học
  - Trừ 15 phút
- Gửi push notification
- Nội dung:
  - "Sắp đến giờ học [Tên lớp]"

---

### 9.5. CRUD

- **Create** → Insert DB  
- **Read** → API fetch  
- **Update** → Update theo ID  
- **Delete** → Xóa dữ liệu  

---

## 10. Xử lý lỗi

| Trường hợp | Xử lý |
|-----------|------|
| Sai login | Thông báo lỗi |
| Trùng lịch | Không cho tạo |
| Không có dữ liệu | Hiển thị rỗng |
| Lỗi server | Hiển thị lỗi |
| Mất kết nối | Hiển thị offline mode |

---

## 11. Bảo mật

- JWT Authentication  
- Hash password (bcrypt)  
- Role-based access control  
- API protected bằng token  
- Không expose dữ liệu nhạy cảm  

---

## 12. Hướng mở rộng

- Web Admin Dashboard  
- AI gợi ý lịch học  
- Thống kê tiến độ học  
- Thanh toán học phí  
- Chat Teacher - Student  
- Đồng bộ đa thiết bị  
