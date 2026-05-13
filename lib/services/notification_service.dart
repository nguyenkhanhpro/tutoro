import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';
import '../utils/constants.dart';

/// Một buổi học để tính nhắc trước 15 phút (REQ-08).
class UpcomingClassSlot {
  final int scheduleId;
  final String className;
  final DateTime startUtc;

  UpcomingClassSlot({
    required this.scheduleId,
    required this.className,
    required this.startUtc,
  });
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  String get _base => AppConstants.baseApiUrl;

  /// Gộp thông báo từ API + nhắc lịch học theo SRS (15 phút trước giờ học).
  Future<List<NotificationModel>> loadNotificationsForUser({
    required int userId,
    List<UpcomingClassSlot>? upcomingSlots,
  }) async {
    final fromApi = await _fetchFromApi(userId);
    final reminders = _buildScheduleReminders(upcomingSlots ?? _defaultUpcomingSlots());
    final merged = <NotificationModel>[...reminders, ...fromApi];
    merged.sort((a, b) => (b.createdAt ?? DateTime(1970)).compareTo(a.createdAt ?? DateTime(1970)));
    return merged;
  }

  Future<List<NotificationModel>> _fetchFromApi(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_base/notifications/$userId'),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
        }
        if (decoded is Map && decoded['data'] is List) {
          return (decoded['data'] as List)
              .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('notifications API: $e');
    }
    return _mockStaticNotifications();
  }

  List<NotificationModel> _mockStaticNotifications() {
    return [
      NotificationModel(
        id: 100,
        title: 'Nhắc học phí',
        message: 'Vui lòng hoàn tất học phí kỳ tới trước hạn.',
        isRead: false,
        kind: NotificationKind.payment,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ];
  }

  List<UpcomingClassSlot> _defaultUpcomingSlots() {
    final now = DateTime.now();
    return [
      UpcomingClassSlot(
        scheduleId: 1,
        className: AppConstants.demoClassName,
        startUtc: now.add(const Duration(minutes: 12)),
      ),
      UpcomingClassSlot(
        scheduleId: 2,
        className: 'Web Fullstack',
        startUtc: now.add(const Duration(days: 1, hours: 2)),
      ),
    ];
  }

  /// Trong vòng [AppConstants.reminderMinutesBeforeClass] phút trước giờ học → thêm thông báo đẩy nội dung chuẩn SRS.
  List<NotificationModel> _buildScheduleReminders(List<UpcomingClassSlot> slots) {
    final window = Duration(minutes: AppConstants.reminderMinutesBeforeClass);
    final out = <NotificationModel>[];
    var fakeId = 9000;
    for (final s in slots) {
      final triggerStart = s.startUtc.subtract(window);
      final now = DateTime.now();
      if (now.isAfter(triggerStart) && now.isBefore(s.startUtc)) {
        out.add(
          NotificationModel(
            id: fakeId++,
            title: 'Sắp đến giờ học',
            message: 'Sắp đến giờ học ${s.className}',
            isRead: false,
            kind: NotificationKind.scheduleReminder,
            createdAt: now,
          ),
        );
      }
    }
    return out;
  }
}
