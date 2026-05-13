import '../models/notification_model.dart';
import '../utils/constants.dart';
import '../utils/vietnamese_date_format.dart';
import 'payment_service.dart';
import 'teacher_schedule_service.dart';
import 'teacher_session_check_in_store.dart';

/// Thông báo phía giáo viên: lịch; check-in; lớp khóa; học phí học viên.
class TeacherNotificationService {
  TeacherNotificationService._();
  static final TeacherNotificationService instance = TeacherNotificationService._();

  Future<List<NotificationModel>> buildListAsync(DateTime now) async {
    final svc = TeacherScheduleService.instance;
    svc.ensureSeeded();
    final out = <NotificationModel>[];
    var nid = 7000;

    for (final s in svc.sessions) {
      TeacherSessionCheckInStore.instance.ensureForgottenNotification(s, now);
      final remindAt = s.start.subtract(
        const Duration(minutes: AppConstants.reminderMinutesBeforeClass),
      );
      if (now.isAfter(remindAt) && now.isBefore(s.start)) {
        out.add(
          NotificationModel(
            id: nid++,
            title: 'Sắp đến giờ dạy',
            message: 'Bạn có lớp "${s.className}" lúc ${_fmt(s.start)}.',
            isRead: false,
            kind: NotificationKind.scheduleReminder,
            createdAt: now,
          ),
        );
      }
    }

    final seen = <String>{};
    for (final c in svc.classSummaries()) {
      if (!c.locked || seen.contains(c.classId)) continue;
      seen.add(c.classId);
      out.add(
        NotificationModel(
          id: nid++,
          title: 'Lớp đã khóa',
          message:
              'Lớp "${c.className}" vượt số buổi hợp đồng (buổi cao nhất ${c.highestLessonNumber}/${c.contractLessons}). Ứng dụng chỉ xem — admin có quyền xóa / chỉnh buổi trên hệ thống quản trị.',
          isRead: false,
          kind: NotificationKind.general,
          createdAt: now.subtract(const Duration(minutes: 30)),
        ),
      );
    }

    out.addAll(TeacherSessionCheckInStore.instance.notificationsSnapshot());

    final payment = PaymentService();
    const feeWatch = <(int, String)>[
      (1, 'Nguyễn Văn A'),
      (3, 'Lê Văn C'),
    ];
    for (final e in feeWatch) {
      final sid = e.$1;
      final name = e.$2;
      final owes = await payment.hasOutstandingFees(sid);
      if (!owes) continue;
      final total = await payment.outstandingTotalVnd(sid);
      out.add(
        NotificationModel(
          id: nid++,
          title: 'Học phí — cần theo dõi',
          message:
              'Học viên $name còn nợ khoảng ${total.round()} VND. Kiểm tra trong Điểm danh buổi học hoặc mục Khóa học → Học viên & học phí.',
          isRead: false,
          kind: NotificationKind.payment,
          createdAt: now.subtract(const Duration(hours: 1)),
        ),
      );
    }

    out.sort((a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
        .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
    return out;
  }

  String _fmt(DateTime dt) {
    final l = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    final label = vietnameseWeekdayLabel(l);
    return '$label ${two(l.day)}/${two(l.month)}/${l.year} ${two(l.hour)}:${two(l.minute)}';
  }
}
