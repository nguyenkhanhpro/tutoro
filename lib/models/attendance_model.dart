class AttendanceModel {
  final int id;
  final int studentId;
  final int? scheduleId;
  final int? classId;
  final String status;
  final DateTime? checkinTime;
  final String? className;
  final DateTime? sessionTime;

  AttendanceModel({
    required this.id,
    required this.studentId,
    this.scheduleId,
    this.classId,
    required this.status,
    this.checkinTime,
    this.className,
    this.sessionTime,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDt(dynamic v) {
      if (v == null) return null;
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
      return null;
    }

    return AttendanceModel(
      id: _asInt(json['id']),
      studentId: _asInt(json['student_id'] ?? json['studentId']),
      scheduleId: _nullableInt(json['schedule_id'] ?? json['scheduleId']),
      classId: _nullableInt(json['class_id'] ?? json['classId']),
      status: (json['status'] ?? 'unknown').toString(),
      checkinTime: parseDt(json['checkin_time'] ?? json['checkinTime']),
      className: json['class_name']?.toString() ?? json['className']?.toString(),
      sessionTime: parseDt(json['session_time'] ?? json['sessionTime'] ?? json['time']),
    );
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static int? _nullableInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }
}

/// Một dòng điểm danh theo buổi (giảng viên tick Có mặt / Vắng).
class SessionAttendanceRow {
  final int studentId;
  final String studentName;
  final String status;

  SessionAttendanceRow({
    required this.studentId,
    required this.studentName,
    required this.status,
  });

  SessionAttendanceRow copyWith({String? status}) {
    return SessionAttendanceRow(
      studentId: studentId,
      studentName: studentName,
      status: status ?? this.status,
    );
  }
}
