import '../utils/constants.dart';

/// Lịch buổi học demo (một lần trong phiên app) để minh hoạ cửa 15 phút trước giờ học.
class DemoScheduleStore {
  DemoScheduleStore._();
  static final DemoScheduleStore instance = DemoScheduleStore._();

  DateTime? _sessionStart;

  /// Thời điểm bắt đầu buổi học (theo máy, local).
  DateTime get classSessionStart {
    _sessionStart ??= DateTime.now().add(
      const Duration(minutes: AppConstants.demoMinutesUntilClassStart),
    );
    return _sessionStart!;
  }

  /// Thời điểm mở cửa check-in: 15 phút trước giờ vào lớp.
  DateTime checkInWindowOpensAt(DateTime classStart) {
    return classStart.subtract(
      const Duration(minutes: AppConstants.reminderMinutesBeforeClass),
    );
  }

  /// Chưa tới 15 phút trước giờ học → chỉ hiển thị trạng thái "buổi học sắp diễn ra".
  bool isTooEarlyForCheckIn(DateTime now) {
    return now.isBefore(checkInWindowOpensAt(classSessionStart));
  }

  /// Hết cửa sổ check-in demo (sau giờ vào lớp + buffer).
  DateTime get checkInWindowEnd =>
      classSessionStart.add(const Duration(hours: 2));

  bool isAfterCheckInSlot(DateTime now) {
    return !now.isBefore(checkInWindowEnd);
  }

  /// Đã vào cửa sổ check-in (từ T-15 trở đi, đến hết buffer).
  bool isCheckInWindowOpen(DateTime now) {
    final open = checkInWindowOpensAt(classSessionStart);
    return !now.isBefore(open) && now.isBefore(checkInWindowEnd);
  }
}
