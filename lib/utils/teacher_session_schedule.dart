import '../models/teaching_session_model.dart';
import '../utils/constants.dart';

/// Mở check-in: cùng khoảng **15 phút trước giờ vào lớp** như nhắc lịch (REQ-08).
DateTime teacherCheckInOpensAt(TeachingSessionModel s) {
  return s.start.subtract(Duration(minutes: AppConstants.reminderMinutesBeforeClass));
}

bool teacherSessionHasEnded(TeachingSessionModel s, DateTime now) {
  return !now.isBefore(s.end);
}

bool teacherSessionIsInProgress(TeachingSessionModel s, DateTime now) {
  return !now.isBefore(s.start) && now.isBefore(s.end);
}

/// Được phép check-in: từ [teacherCheckInOpensAt] đến trước [s.end].
bool teacherCanCheckInNow(TeachingSessionModel s, DateTime now) {
  if (teacherSessionHasEnded(s, now)) return false;
  return !now.isBefore(teacherCheckInOpensAt(s));
}

/// Trạng thái hiển thị (đồng bộ thẻ lịch + màn chi tiết).
enum TeacherSessionPhase {
  ended,
  inProgress,
  checkInOpenBeforeClass,
  upcoming,
}

TeacherSessionPhase teacherSessionPhase(TeachingSessionModel s, DateTime now) {
  if (teacherSessionHasEnded(s, now)) return TeacherSessionPhase.ended;
  if (teacherSessionIsInProgress(s, now)) return TeacherSessionPhase.inProgress;
  if (!now.isBefore(teacherCheckInOpensAt(s))) {
    return TeacherSessionPhase.checkInOpenBeforeClass;
  }
  return TeacherSessionPhase.upcoming;
}

String teacherSessionPhaseLabel(TeacherSessionPhase p) {
  switch (p) {
    case TeacherSessionPhase.ended:
      return 'Đã kết thúc';
    case TeacherSessionPhase.inProgress:
      return 'Đang diễn ra';
    case TeacherSessionPhase.checkInOpenBeforeClass:
      return 'Mở check-in';
    case TeacherSessionPhase.upcoming:
      return 'Sắp diễn ra';
  }
}

/// Nhãn buổi theo **ngày giờ thực của buổi** (không dùng dạng số/số dễ nhầm ngày).
String formatLessonLabelForSessionStart({
  required int lessonNumber,
  required DateTime sessionStart,
}) {
  return 'Buổi số $lessonNumber — tháng ${sessionStart.month}';
}
