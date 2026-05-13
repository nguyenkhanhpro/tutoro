/// Buổi dạy (phía giáo viên). Danh sách học viên / học phí xem trong Điểm danh và tab Khóa học (demo).
class TeachingSessionModel {
  final String id;
  /// Nhóm lớp (cùng `classId` dùng chung `contractLessons`).
  final String classId;
  final String className;
  /// Buổi thứ mấy trong hợp đồng (so với `contractLessons`).
  final int lessonNumber;
  final int contractLessons;
  /// Nhãn ngắn (vd. `Buổi số 1 — tháng 5` theo ngày giờ buổi; sinh từ [formatLessonLabelForSessionStart]).
  final String lessonLabel;
  final DateTime start;
  final DateTime end;

  TeachingSessionModel({
    required this.id,
    required this.classId,
    required this.className,
    required this.lessonNumber,
    required this.contractLessons,
    required this.lessonLabel,
    required this.start,
    required this.end,
  });

  /// Buổi này vượt số buổi hợp đồng (khóa cả lớp: [TeacherScheduleService.isClassLocked]).
  bool get isThisLessonOverQuota => lessonNumber > contractLessons;

  bool isSameCalendarDay(DateTime day) {
    final a = DateTime(start.year, start.month, start.day);
    final b = DateTime(day.year, day.month, day.day);
    return a == b;
  }

  bool isInMonth(DateTime anchor) {
    return start.year == anchor.year && start.month == anchor.month;
  }
}

/// Tổng hợp theo lớp (tab Khóa học).
class TeacherClassSummary {
  final String classId;
  final String className;
  final int contractLessons;
  final int highestLessonNumber;
  final int completedSessionsCount;
  final bool locked;

  TeacherClassSummary({
    required this.classId,
    required this.className,
    required this.contractLessons,
    required this.highestLessonNumber,
    required this.completedSessionsCount,
    required this.locked,
  });
}
