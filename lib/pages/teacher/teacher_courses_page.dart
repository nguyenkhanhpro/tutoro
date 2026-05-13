import 'package:flutter/material.dart';

import '../../models/attendance_model.dart';
import '../../models/teaching_session_model.dart';
import '../../services/attendance_service.dart';
import '../../services/payment_service.dart';
import '../../services/teacher_schedule_service.dart';
import '../../widgets/payment_card.dart';
import 'teacher_attendance_page.dart';

/// Khóa học / lớp: hợp đồng buổi, trạng thái khóa, và danh sách học viên kèm học phí (demo).
class TeacherCoursesPage extends StatefulWidget {
  const TeacherCoursesPage({super.key});

  @override
  State<TeacherCoursesPage> createState() => _TeacherCoursesPageState();
}

class _TeacherCoursesPageState extends State<TeacherCoursesPage> {
  Future<void> _openClassStudentsSheet(BuildContext context, TeacherClassSummary summary) async {
    final scheduleId = demoScheduleIdForTeacherClass(summary.classId);
    final attendance = AttendanceService();
    final roster = await attendance.fetchSessionRoster(scheduleId: scheduleId);
    if (!context.mounted) return;

    final maxH = MediaQuery.sizeOf(context).height * 0.72;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Học viên & học phí — ${summary.className}',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kiểm tra nhanh ai còn nợ / đủ phí (dữ liệu demo). Chạm học viên còn nợ để mở QR thanh toán giả lập.',
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: Theme.of(ctx).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ...roster.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ClassStudentFeeTile(
                        row: r,
                        className: summary.className,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final svc = TeacherScheduleService.instance;
    svc.ensureSeeded();
    return ListenableBuilder(
      listenable: svc,
      builder: (context, _) {
        final rows = svc.classSummaries();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Khóa học & hợp đồng buổi', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Lớp vượt số buổi trong hợp đồng sẽ bị khóa (làm mờ). Chọn nút bên dưới để xem học viên và học phí.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 16),
            ...rows.map(
              (c) => _ClassSummaryCard(
                key: ValueKey<String>(c.classId),
                summary: c,
                onStudentsPressed: () => _openClassStudentsSheet(context, c),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ClassSummaryCard extends StatelessWidget {
  final TeacherClassSummary summary;
  final VoidCallback onStudentsPressed;

  const _ClassSummaryCard({
    super.key,
    required this.summary,
    required this.onStudentsPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inner = Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onStudentsPressed,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.className,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hợp đồng: ${summary.contractLessons} buổi\n'
                          'Buổi cao nhất trên lịch: ${summary.highestLessonNumber}\n'
                          'Đã hoàn thành (đã qua giờ): ${summary.completedSessionsCount}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  summary.locked
                      ? Chip(
                          avatar: Icon(Icons.lock, size: 18, color: theme.colorScheme.error),
                          label: const Text('Đã khóa'),
                        )
                      : const Chip(label: Text('Hoạt động')),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: onStudentsPressed,
                icon: const Icon(Icons.groups_outlined),
                label: const Text('Học viên & học phí'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!summary.locked) return inner;
    return Opacity(opacity: 0.45, child: inner);
  }
}

class _ClassStudentFeeTile extends StatelessWidget {
  final SessionAttendanceRow row;
  final String className;

  const _ClassStudentFeeTile({
    required this.row,
    required this.className,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(bool, double)>(
      future: _feeFuture(row.studentId),
      builder: (context, snap) {
        final owes = snap.data?.$1 ?? false;
        final total = snap.data?.$2 ?? 0.0;
        return Card(
          child: ListTile(
            title: Text(row.studentName),
            subtitle: Text('ID: ${row.studentId}'),
            isThreeLine: true,
            trailing: owes
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Chip(
                        label: const Text('Còn nợ'),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Colors.orange.shade100,
                      ),
                      Text(
                        formatVnd(total),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  )
                : const Chip(
                    label: Text('Đủ phí'),
                    visualDensity: VisualDensity.compact,
                  ),
            onTap: owes
                ? () => showDemoTuitionQrBottomSheet(
                      context,
                      studentId: row.studentId,
                      studentName: row.studentName,
                      className: className,
                    )
                : null,
          ),
        );
      },
    );
  }

  Future<(bool, double)> _feeFuture(int studentId) async {
    final p = PaymentService();
    final owes = await p.hasOutstandingFees(studentId);
    final total = await p.outstandingTotalVnd(studentId);
    return (owes, total);
  }
}
