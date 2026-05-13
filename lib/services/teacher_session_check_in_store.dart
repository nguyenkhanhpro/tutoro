import 'package:flutter/foundation.dart';

import '../models/notification_model.dart';
import '../models/teaching_session_model.dart';

/// Lưu check-in theo `session.id` (demo) và sinh thông báo cho giáo viên.
class TeacherSessionCheckInStore extends ChangeNotifier {
  TeacherSessionCheckInStore._();
  static final TeacherSessionCheckInStore instance = TeacherSessionCheckInStore._();

  final Map<String, DateTime> _checkInAtBySessionId = <String, DateTime>{};
  final Set<String> _forgottenNotifiedSessionIds = <String>{};
  final List<NotificationModel> _notifications = <NotificationModel>[];
  int _nid = 6500;

  int _nextId() => _nid++;

  DateTime? checkInTime(String sessionId) => _checkInAtBySessionId[sessionId];

  bool hasCheckedIn(String sessionId) => _checkInAtBySessionId.containsKey(sessionId);

  /// `true` = trước hoặc đúng giờ vào lớp; `false` = trong giờ học (muộn).
  static bool wasCheckInOnTime(TeachingSessionModel session, DateTime when) {
    return !when.isAfter(session.start);
  }

  /// Ghi nhận bấm Check-in (một lần / buổi). Thêm thông báo cho GV.
  void recordCheckIn(TeachingSessionModel session, DateTime when) {
    if (_checkInAtBySessionId.containsKey(session.id)) return;
    _checkInAtBySessionId[session.id] = when;
    final onTime = wasCheckInOnTime(session, when);
    _notifications.insert(
      0,
      NotificationModel(
        id: _nextId(),
        title: onTime ? 'Check-in đúng giờ' : 'Check-in muộn',
        message: onTime
            ? 'Bạn đã check-in đúng giờ — "${session.className}" (${session.lessonLabel}).'
            : 'Bạn đã check-in muộn (trong giờ học) — "${session.className}" (${session.lessonLabel}).',
        isRead: false,
        kind: NotificationKind.attendance,
        createdAt: when,
      ),
    );
    notifyListeners();
  }

  /// Sau khi buổi kết thúc mà chưa check-in → một thông báo / buổi.
  void ensureForgottenNotification(TeachingSessionModel session, DateTime now) {
    if (now.isBefore(session.end)) return;
    if (_checkInAtBySessionId.containsKey(session.id)) return;
    if (_forgottenNotifiedSessionIds.contains(session.id)) return;
    _forgottenNotifiedSessionIds.add(session.id);
    _notifications.insert(
      0,
      NotificationModel(
        id: _nextId(),
        title: 'Thiếu check-in',
        message:
            'Bạn đã quên check-in buổi học "${session.className}" (${session.lessonLabel}) — buổi đã kết thúc.',
        isRead: false,
        kind: NotificationKind.attendance,
        createdAt: session.end,
      ),
    );
    notifyListeners();
  }

  List<NotificationModel> notificationsSnapshot() => List<NotificationModel>.unmodifiable(_notifications);
}
