/// Tham số & seed theo SRS (mục 5.4, 5.2, 5.3).
class AppConstants {
  AppConstants._();

  static const String baseApiUrl = 'http://localhost:3000/api';

  /// Nhắc lịch & **mở check-in**: N phút trước giờ vào lớp (REQ-08, đồng bộ cửa sổ check-in GV).
  static const int reminderMinutesBeforeClass = 15;

  static const String timezoneLabel = 'UTC+7';

  /// Thời gian hiệu lực mã QR check-in (giây).
  static const int qrValiditySeconds = 120;

  static const int demoStudentId = 1;
  static const String demoStudentCode = 'STD001';

  static const int demoClassFlutter = 101;
  static const String demoClassName = 'Flutter Basic';

  static const int demoScheduleId = 1;

  /// Buổi học demo bắt đầu sau N phút (kể từ lần đầu đọc lịch trong app).
  /// Ví dụ 25 → ~10 phút đầu là "sắp diễn ra", sau đó 15 phút trước giờ học mở check-in.
  static const int demoMinutesUntilClassStart = 25;

  /// `false`: học viên không nợ học phí → không cần màn thanh toán. Đặt `true` để demo nợ tiền.
  static const bool demoStudentOwesFees = false;
}
