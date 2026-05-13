enum NotificationKind {
  scheduleReminder,
  attendance,
  payment,
  general,
}

class NotificationModel {
  final int id;
  final String title;
  final String message;
  final bool isRead;
  final NotificationKind kind;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    this.kind = NotificationKind.general,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final type = (json['type'] ?? json['kind'] ?? '').toString().toLowerCase();
    NotificationKind kind = NotificationKind.general;
    if (type.contains('schedule') || type.contains('lich')) {
      kind = NotificationKind.scheduleReminder;
    } else if (type.contains('attendance') || type.contains('diem danh')) {
      kind = NotificationKind.attendance;
    } else if (type.contains('payment') || type.contains('hoc phi')) {
      kind = NotificationKind.payment;
    }

    DateTime? created;
    final raw = json['created_at'] ?? json['createdAt'];
    if (raw is String && raw.isNotEmpty) created = DateTime.tryParse(raw);

    return NotificationModel(
      id: _asInt(json['id']),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? json['body'] ?? '').toString(),
      isRead: json['is_read'] == true || json['isRead'] == true,
      kind: kind,
      createdAt: created,
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      isRead: isRead ?? this.isRead,
      kind: kind,
      createdAt: createdAt,
    );
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}
