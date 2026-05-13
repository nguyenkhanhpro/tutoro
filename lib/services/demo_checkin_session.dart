import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

/// Phiên check-in do **giảng viên mở** (demo in-process, không cần backend).
class DemoCheckInSession extends ChangeNotifier {
  DemoCheckInSession._();
  static final DemoCheckInSession instance = DemoCheckInSession._();

  DateTime? _endsAt;
  String? _qrPayload;

  DateTime? get endsAt => _endsAt;
  String? get qrPayload => _qrPayload;

  bool get isActive {
    final end = _endsAt;
    if (end == null) return false;
    return DateTime.now().isBefore(end);
  }

  int secondsRemaining() {
    final end = _endsAt;
    if (end == null) return 0;
    final s = end.difference(DateTime.now()).inSeconds;
    return s < 0 ? 0 : s;
  }

  /// GV bấm "Check-in" → sinh mã QR có hạn [AppConstants.qrValiditySeconds].
  void openByTeacher({String? teachingSessionId}) {
    final end = DateTime.now().add(
      const Duration(seconds: AppConstants.qrValiditySeconds),
    );
    final exp = end.millisecondsSinceEpoch ~/ 1000;
    _endsAt = end;
    _qrPayload = jsonEncode({
      'issuer': 'TUTERO',
      'role': 'class_session',
      'class_id': AppConstants.demoClassFlutter,
      'schedule_id': AppConstants.demoScheduleId,
      if (teachingSessionId != null && teachingSessionId.isNotEmpty) 'teaching_session_id': teachingSessionId,
      'exp': exp,
    });
    notifyListeners();
  }

  void close() {
    _endsAt = null;
    _qrPayload = null;
    notifyListeners();
  }
}
