import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/attendance_model.dart';
import '../utils/constants.dart';

class AttendanceService {
  static final AttendanceService _instance = AttendanceService._();
  factory AttendanceService() => _instance;
  AttendanceService._();

  String get _base => AppConstants.baseApiUrl;

  /// Điểm danh mock **theo từng buổi** (`teachingSessionId`), mặc định tất cả vắng.
  final Map<String, List<SessionAttendanceRow>> _mockSessionRosters = {};

  String _rosterStorageKey(int scheduleId, String? teachingSessionId) {
    if (teachingSessionId != null && teachingSessionId.isNotEmpty) {
      return '$scheduleId|${teachingSessionId.trim()}';
    }
    return '$scheduleId|_';
  }

  /// Lịch sử điểm danh học viên (theo SRS REQ-07).
  Future<List<AttendanceModel>> fetchStudentAttendance(int studentId) async {
    try {
      final response = await http.get(
        Uri.parse('$_base/attendance/student/$studentId'),
      );
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        return list.map((e) => AttendanceModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('fetchStudentAttendance API: $e');
    }
    return _mockAttendanceHistory(studentId);
  }

  /// Danh sách học viên trong buổi để giảng viên tick Có mặt / Vắng (luồng 9.3 SRS).
  Future<List<SessionAttendanceRow>> fetchSessionRoster({
    required int scheduleId,
    String? teachingSessionId,
  }) async {
    try {
      final q = (teachingSessionId != null && teachingSessionId.isNotEmpty)
          ? '?teaching_session_id=${Uri.encodeQueryComponent(teachingSessionId)}'
          : '';
      final response = await http.get(
        Uri.parse('$_base/attendance/session/$scheduleId/roster$q'),
      );
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        return list.map((e) {
          final m = e as Map<String, dynamic>;
          final sid = m['student_id'] ?? m['studentId'];
          return SessionAttendanceRow(
            studentId: sid is int ? sid : int.tryParse(sid?.toString() ?? '') ?? 0,
            studentName: (m['name'] ?? m['student_name'] ?? 'Học viên').toString(),
            status: (m['status'] ?? 'Absent').toString(),
          );
        }).toList();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('fetchSessionRoster API: $e');
    }
    return _mockRosterForKey(_rosterStorageKey(scheduleId, teachingSessionId));
  }

  Future<void> saveSessionAttendance({
    required int scheduleId,
    required List<SessionAttendanceRow> rows,
    String? teachingSessionId,
  }) async {
    final body = jsonEncode({
      'schedule_id': scheduleId,
      if (teachingSessionId != null && teachingSessionId.isNotEmpty) 'teaching_session_id': teachingSessionId,
      'records': rows
          .map((r) => {
                'student_id': r.studentId,
                'status': r.status,
              })
          .toList(),
    });
    try {
      final response = await http.post(
        Uri.parse('$_base/attendance/session/$scheduleId'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      if (response.statusCode == 200 || response.statusCode == 201) return;
    } catch (e) {
      if (kDebugMode) debugPrint('saveSessionAttendance API: $e');
    }
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final key = _rosterStorageKey(scheduleId, teachingSessionId);
    _mockSessionRosters[key] = rows
        .map(
          (r) => SessionAttendanceRow(
            studentId: r.studentId,
            studentName: r.studentName,
            status: r.status,
          ),
        )
        .toList();
  }

  /// Check-in bằng QR: payload nên chứa `token` hoặc mã lớp do server phát hành.
  Future<void> checkIn({
    required int studentId,
    required int classId,
    required String qrCode,
    int? scheduleId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_base/attendance/checkin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'student_id': studentId,
          'class_id': classId,
          'schedule_id': ?scheduleId,
          'qr_code': qrCode,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) return;
    } catch (e) {
      if (kDebugMode) debugPrint('checkIn API: $e');
    }
    _validateQrPayload(qrCode, studentId);
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  void _validateQrPayload(String qrCode, int studentId) {
    final trimmed = qrCode.trim();
    if (trimmed.isEmpty) {
      throw Exception('Mã QR không hợp lệ');
    }
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Mã QR không hợp lệ');
      }
      final map = decoded;
      final exp = map['exp'] as int?;
      if (exp != null) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: false);
        if (DateTime.now().isAfter(expiry)) {
          throw Exception('Mã QR đã hết hạn');
        }
      }
      final sid = map['student_id'];
      if (sid != null && int.tryParse(sid.toString()) != studentId) {
        throw Exception('Mã QR không khớp tài khoản học viên');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      // Nếu không phải JSON, chấp nhận mã tĩnh demo.
      if (!trimmed.contains('TUTERO') && trimmed.length < 4) {
        throw Exception('Mã QR không hợp lệ');
      }
    }
  }

  List<AttendanceModel> _mockAttendanceHistory(int studentId) {
    final now = DateTime.now();
    return [
      AttendanceModel(
        id: 1,
        studentId: studentId,
        scheduleId: 1,
        classId: AppConstants.demoClassFlutter,
        status: 'Present',
        checkinTime: now.subtract(const Duration(days: 2)),
        className: AppConstants.demoClassName,
        sessionTime: now.subtract(const Duration(days: 2)),
      ),
      AttendanceModel(
        id: 2,
        studentId: studentId,
        scheduleId: 2,
        classId: AppConstants.demoClassFlutter,
        status: 'Absent',
        checkinTime: null,
        className: AppConstants.demoClassName,
        sessionTime: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  List<SessionAttendanceRow> _mockRosterForKey(String key) {
    return _mockSessionRosters.putIfAbsent(key, () {
      return [
        SessionAttendanceRow(studentId: 1, studentName: 'Nguyễn Văn A', status: 'Absent'),
        SessionAttendanceRow(studentId: 2, studentName: 'Trần Thị B', status: 'Absent'),
        SessionAttendanceRow(studentId: 3, studentName: 'Lê Văn C', status: 'Absent'),
      ];
    });
  }
}
