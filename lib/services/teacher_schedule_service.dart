import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/teaching_session_model.dart';
import '../utils/teacher_session_schedule.dart';

/// Lịch buổi dạy demo (chỉ GV). Lớp vượt số buổi hợp đồng → khóa (xem [isClassLocked]).
class TeacherScheduleService extends ChangeNotifier {
  TeacherScheduleService._();
  static final TeacherScheduleService instance = TeacherScheduleService._();

  final List<TeachingSessionModel> _sessions = [];

  static const String _checkinDemoSessionId = 'ses_checkin_demo';

  List<TeachingSessionModel> get sessions => List.unmodifiable(_sessions);

  void ensureSeeded() {
    if (_sessions.isEmpty) {
      _seedInitialSessions();
    }
    _upsertCheckinDemoSession();
  }

  void _seedInitialSessions() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final eveningStart = today.add(const Duration(hours: 19));
    _sessions.add(
      TeachingSessionModel(
        id: 'ses_evening_scratch',
        classId: 'cls_scratch',
        className: 'Luyện thi HKICO - Scratch',
        lessonNumber: 12,
        contractLessons: 12,
        lessonLabel: formatLessonLabelForSessionStart(lessonNumber: 12, sessionStart: eveningStart),
        start: eveningStart,
        end: eveningStart.add(const Duration(hours: 2)),
      ),
    );

    final morning = today.add(const Duration(hours: 8));
    _sessions.add(
      TeachingSessionModel(
        id: 'ses_morning_flutter',
        classId: 'cls_flutter',
        className: 'Flutter Basic',
        lessonNumber: 5,
        contractLessons: 20,
        lessonLabel: formatLessonLabelForSessionStart(lessonNumber: 5, sessionStart: morning),
        start: morning,
        end: morning.add(const Duration(hours: 2)),
      ),
    );

    final nextWeek = today.add(const Duration(days: 5));
    final wStart = DateTime(nextWeek.year, nextWeek.month, nextWeek.day, 18, 30);
    _sessions.add(
      TeachingSessionModel(
        id: 'ses_nextweek_web',
        classId: 'cls_web',
        className: 'Web Fullstack',
        lessonNumber: 4,
        contractLessons: 3,
        lessonLabel: formatLessonLabelForSessionStart(lessonNumber: 4, sessionStart: wStart),
        start: wStart,
        end: wStart.add(const Duration(hours: 2, minutes: 30)),
      ),
    );

    final py = today.add(const Duration(days: 2));
    final pyStart = DateTime(py.year, py.month, py.day, 14, 0);
    _sessions.add(
      TeachingSessionModel(
        id: 'ses_python_over',
        classId: 'cls_python',
        className: 'Ôn thi Python',
        lessonNumber: 6,
        contractLessons: 5,
        lessonLabel: formatLessonLabelForSessionStart(lessonNumber: 6, sessionStart: pyStart),
        start: pyStart,
        end: pyStart.add(const Duration(hours: 2)),
      ),
    );

    _sessions.sort((a, b) => a.start.compareTo(b.start));
  }

  /// Buổi **Demo Check-in** bắt đầu ~2 phút nữa (thử nút check-in T-15). Tạo lại khi buổi cũ đã kết thúc.
  void _upsertCheckinDemoSession() {
    final now = DateTime.now();
    final idx = _sessions.indexWhere((s) => s.id == _checkinDemoSessionId);

    TeachingSessionModel build() {
      final start = now.add(const Duration(minutes: 2));
      return TeachingSessionModel(
        id: _checkinDemoSessionId,
        classId: 'cls_checkin_demo',
        className: 'Demo Check-in (gần giờ)',
        lessonNumber: 1,
        contractLessons: 10,
        lessonLabel: formatLessonLabelForSessionStart(lessonNumber: 1, sessionStart: start),
        start: start,
        end: start.add(const Duration(hours: 2)),
      );
    }

    if (idx < 0) {
      _sessions.add(build());
      _sessions.sort((a, b) => a.start.compareTo(b.start));
      notifyListeners();
      return;
    }

    final existing = _sessions[idx];
    if (now.isAfter(existing.end)) {
      _sessions[idx] = build();
      _sessions.sort((a, b) => a.start.compareTo(b.start));
      notifyListeners();
    }
  }

  TeachingSessionModel? getById(String id) {
    try {
      return _sessions.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// `true` khi buổi cao nhất của lớp vượt số buổi trong hợp đồng (cần admin xử lý trên web).
  bool isClassLocked(String classId) {
    final grp = _sessions.where((s) => s.classId == classId).toList();
    if (grp.isEmpty) return false;
    final maxLesson = grp.map((e) => e.lessonNumber).reduce(math.max);
    final limit = grp.first.contractLessons;
    return maxLesson > limit;
  }

  bool sessionBelongsToLockedClass(TeachingSessionModel s) => isClassLocked(s.classId);

  List<TeachingSessionModel> todaySessions(DateTime now) {
    return _sessions.where((s) => s.isSameCalendarDay(now)).toList();
  }

  List<TeachingSessionModel> monthSessions(DateTime now) {
    return _sessions.where((s) => s.isInMonth(now)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  TeachingSessionModel? currentSession(DateTime now) {
    for (final s in _sessions) {
      if (!now.isBefore(s.start) && now.isBefore(s.end)) {
        return s;
      }
    }
    return null;
  }

  /// Thông tin từng lớp (cho tab Khóa học).
  List<TeacherClassSummary> classSummaries() {
    final byId = <String, List<TeachingSessionModel>>{};
    for (final s in _sessions) {
      byId.putIfAbsent(s.classId, () => []).add(s);
    }
    final out = <TeacherClassSummary>[];
    for (final e in byId.entries) {
      final list = e.value;
      final name = list.first.className;
      final limit = list.first.contractLessons;
      final maxLesson = list.map((x) => x.lessonNumber).reduce(math.max);
      final done = list.where((x) => x.end.isBefore(DateTime.now())).length;
      out.add(
        TeacherClassSummary(
          classId: e.key,
          className: name,
          contractLessons: limit,
          highestLessonNumber: maxLesson,
          completedSessionsCount: done,
          locked: maxLesson > limit,
        ),
      );
    }
    out.sort((a, b) => a.className.compareTo(b.className));
    return out;
  }
}
