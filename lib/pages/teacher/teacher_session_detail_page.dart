import 'dart:async';

import 'package:flutter/material.dart';
import '../../models/teaching_session_model.dart';
import '../../services/teacher_schedule_service.dart';
import '../../services/teacher_session_check_in_store.dart';
import '../../utils/constants.dart';
import '../../utils/teacher_session_schedule.dart';
import '../../utils/vietnamese_date_format.dart';
import 'teacher_attendance_page.dart';

class TeacherSessionDetailPage extends StatefulWidget {
  final String sessionId;

  const TeacherSessionDetailPage({super.key, required this.sessionId});

  @override
  State<TeacherSessionDetailPage> createState() => _TeacherSessionDetailPageState();
}

class _TeacherSessionDetailPageState extends State<TeacherSessionDetailPage> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  String _fmtRange(TeachingSessionModel s) {
    return formatTeacherSessionRange(s.start.toLocal(), s.end.toLocal());
  }

  String _checkInHeadline({
    required TeachingSessionModel session,
    required DateTime now,
    required bool beforeCheckInWindow,
    required bool afterEnd,
    required DateTime? checkedAt,
  }) {
    if (beforeCheckInWindow) return 'Buổi học sắp diễn ra';
    if (checkedAt != null) {
      return TeacherSessionCheckInStore.wasCheckInOnTime(session, checkedAt)
          ? 'Bạn đã check-in đúng giờ'
          : 'Bạn đã check-in muộn';
    }
    if (afterEnd) return 'Bạn đã quên check-in buổi học này';
    if (teacherSessionIsInProgress(session, now)) return 'Buổi học đang diễn ra';
    return 'Có thể check-in';
  }

  String _checkInSubtext({
    required TeachingSessionModel session,
    required DateTime now,
    required bool beforeCheckInWindow,
    required bool afterEnd,
    required DateTime? checkedAt,
  }) {
    if (beforeCheckInWindow) {
      return 'Check-in mở từ ${AppConstants.reminderMinutesBeforeClass} phút trước giờ vào lớp, đến khi buổi học kết thúc (theo giờ kết thúc trên lịch — có thể 1,5 giờ, 2 giờ, v.v.).';
    }
    if (checkedAt != null) {
      return TeacherSessionCheckInStore.wasCheckInOnTime(session, checkedAt)
          ? 'Đã ghi nhận và thông báo cho giáo viên.'
          : 'Check-in trong giờ học — đã ghi nhận và thông báo cho giáo viên.';
    }
    if (afterEnd) {
      return 'Sau khi buổi học kết thúc mà chưa check-in — đã thông báo cho giáo viên.';
    }
    if (teacherSessionIsInProgress(session, now)) {
      return 'Nếu bấm Check-in bây giờ sẽ được tính là check-in muộn (trong giờ học).';
    }
    return 'Bấm Check-in khi đã tới lớp hoặc trong giờ học (đến hết buổi).';
  }

  Color _checkInHeadlineColor(
    BuildContext context, {
    required TeachingSessionModel session,
    required DateTime now,
    required bool beforeCheckInWindow,
    required bool afterEnd,
    required DateTime? checkedAt,
  }) {
    if (beforeCheckInWindow) return Colors.green.shade800;
    if (checkedAt != null) {
      return TeacherSessionCheckInStore.wasCheckInOnTime(session, checkedAt)
          ? Colors.teal.shade800
          : Colors.deepOrange.shade800;
    }
    if (afterEnd) return Theme.of(context).colorScheme.error;
    if (teacherSessionIsInProgress(session, now)) return Colors.indigo.shade800;
    return Colors.orange.shade900;
  }

  String _fmtCheckInOpens(TeachingSessionModel s) {
    final l = teacherCheckInOpensAt(s).toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${vietnameseWeekdayLabel(l)} ${two(l.day)}/${two(l.month)}/${l.year}, ${two(l.hour)}:${two(l.minute)}';
  }

  Future<void> _submitCheckIn(TeachingSessionModel session) async {
    final store = TeacherSessionCheckInStore.instance;
    if (store.hasCheckedIn(session.id)) return;
    final when = DateTime.now();
    store.recordCheckIn(session, when);
    if (!mounted) return;
    final onTime = TeacherSessionCheckInStore.wasCheckInOnTime(session, when);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          onTime ? 'Bạn đã check-in đúng giờ.' : 'Bạn đã check-in muộn (trong giờ học).',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final svc = TeacherScheduleService.instance;
    final checkInStore = TeacherSessionCheckInStore.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([svc, checkInStore]),
      builder: (context, _) {
        final session = svc.getById(widget.sessionId);
        if (session == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chi tiết buổi học')),
            body: const Center(child: Text('Không tìm thấy buổi học')),
          );
        }

        checkInStore.ensureForgottenNotification(session, DateTime.now());

        final locked = svc.sessionBelongsToLockedClass(session);
        final now = DateTime.now();
        final phase = teacherSessionPhase(session, now);
        final afterEnd = teacherSessionHasEnded(session, now);
        final beforeCheckInWindow = now.isBefore(teacherCheckInOpensAt(session));
        final checkedAt = checkInStore.checkInTime(session.id);

        final canShowCheckInButton =
            teacherCanCheckInNow(session, now) && !locked && checkedAt == null;
        final canUseActions = !locked;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 160,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    session.lessonLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 4, color: Colors.black45)]),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.deepPurple.shade700,
                          Colors.indigo.shade400,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    alignment: Alignment.bottomLeft,
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          session.className,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (locked)
                        Card(
                          color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.35),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.error),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Lớp đã khóa: buổi cao nhất (${session.lessonNumber}) vượt số buổi hợp đồng (${session.contractLessons}). '
                                    'Giáo viên chỉ xem trên app — admin có quyền xóa buổi / chỉnh hợp đồng trên hệ thống quản trị.',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (locked) const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_fmtRange(session), style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              Text('Buổi ${session.lessonNumber} / ${session.contractLessons} (hợp đồng)'),
                              const SizedBox(height: 8),
                              Chip(
                                label: Text(teacherSessionPhaseLabel(phase)),
                                visualDensity: VisualDensity.compact,
                                backgroundColor: switch (phase) {
                                  TeacherSessionPhase.ended => Theme.of(context).colorScheme.surfaceContainerHighest,
                                  TeacherSessionPhase.inProgress => Colors.indigo.shade50,
                                  TeacherSessionPhase.checkInOpenBeforeClass => Colors.orange.shade50,
                                  TeacherSessionPhase.upcoming => Colors.green.shade50,
                                },
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _checkInHeadline(
                                  session: session,
                                  now: now,
                                  beforeCheckInWindow: beforeCheckInWindow,
                                  afterEnd: afterEnd,
                                  checkedAt: checkedAt,
                                ),
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: _checkInHeadlineColor(
                                        context,
                                        session: session,
                                        now: now,
                                        beforeCheckInWindow: beforeCheckInWindow,
                                        afterEnd: afterEnd,
                                        checkedAt: checkedAt,
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _checkInSubtext(
                                  session: session,
                                  now: now,
                                  beforeCheckInWindow: beforeCheckInWindow,
                                  afterEnd: afterEnd,
                                  checkedAt: checkedAt,
                                ),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                              ),
                              if (canShowCheckInButton) ...[
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: () => _submitCheckIn(session),
                                  icon: const Icon(Icons.how_to_reg_outlined),
                                  label: const Text('Check-in'),
                                ),
                              ] else if (!afterEnd && locked) ...[
                                const SizedBox(height: 16),
                                Text(
                                  'Check-in tắt — lớp đang khóa.',
                                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                                ),
                              ] else if (!afterEnd && !locked && beforeCheckInWindow) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'Check-in mở từ: ${_fmtCheckInOpens(session)} (đến hết buổi theo lịch).',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.outline,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ActionTile(
                        title: 'Điểm danh',
                        subtitle: 'Danh sách học viên, học phí (còn nợ / đủ phí), nhắc phí và QR thanh toán giả lập.',
                        icon: Icons.fact_check_outlined,
                        dimmed: !canUseActions,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton.tonalIcon(
                            onPressed: canUseActions
                                ? () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => TeacherAttendancePage(session: session),
                                      ),
                                    );
                                  }
                                : null,
                            icon: const Icon(Icons.groups_outlined),
                            label: const Text('Mở điểm danh & học phí'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ActionTile(
                        title: 'Đánh giá buổi học',
                        subtitle: 'Nhận xét, đánh giá về buổi học (demo)',
                        icon: Icons.rate_review_outlined,
                        dimmed: !canUseActions,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: canUseActions
                                ? () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Tính năng demo — chưa kết nối backend')),
                                    );
                                  }
                                : null,
                            child: const Text('Mở form đánh giá'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ActionTile(
                        title: 'Upload hình ảnh, video',
                        subtitle: 'Tài liệu buổi học (demo)',
                        icon: Icons.perm_media_outlined,
                        dimmed: !canUseActions,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: canUseActions
                                ? () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Tính năng demo — chưa kết nối backend')),
                                    );
                                  }
                                : null,
                            child: const Text('Chọn tệp'),
                          ),
                        ),
                      ),
                      if (afterEnd) const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final bool dimmed;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final inner = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
    if (!dimmed) return inner;
    return Opacity(opacity: 0.45, child: inner);
  }
}
