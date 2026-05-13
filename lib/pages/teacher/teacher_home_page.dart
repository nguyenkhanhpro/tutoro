import 'package:flutter/material.dart';
import '../../models/teaching_session_model.dart';
import '../../services/teacher_schedule_service.dart';
import '../../utils/teacher_session_schedule.dart';
import '../../utils/vietnamese_date_format.dart';
import 'teacher_session_detail_page.dart';

class TeacherHomePage extends StatelessWidget {
  const TeacherHomePage({super.key});

  String _fmtRange(TeachingSessionModel s) {
    return formatTeacherSessionRange(s.start.toLocal(), s.end.toLocal());
  }

  void _openDetail(BuildContext context, String sessionId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TeacherSessionDetailPage(sessionId: sessionId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final svc = TeacherScheduleService.instance;
    svc.ensureSeeded();
    return ListenableBuilder(
      listenable: svc,
      builder: (context, _) {
        final now = DateTime.now();
        final today = svc.todaySessions(now);
        final month = svc.monthSessions(now);
        final todayIds = today.map((e) => e.id).toSet();
        final monthRest = month.where((s) => !todayIds.contains(s.id)).toList();
        final current = svc.currentSession(now);
        final currentLocked = current != null && svc.sessionBelongsToLockedClass(current);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (current != null) ...[
              Text('Lớp đang dạy', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              _SessionCard(
                session: current,
                locked: currentLocked,
                subtitle: _fmtRange(current),
                phase: teacherSessionPhase(current, now),
                onTap: () => _openDetail(context, current.id),
              ),
              const SizedBox(height: 24),
            ],
            Text('Lịch dạy hôm nay', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (today.isEmpty)
              const Text('Không có buổi học hôm nay.')
            else
              ...today.map(
                (s) {
                  final locked = svc.sessionBelongsToLockedClass(s);
                  return _SessionCard(
                    session: s,
                    locked: locked,
                    subtitle: _fmtRange(s),
                    phase: teacherSessionPhase(s, now),
                    onTap: () => _openDetail(context, s.id),
                  );
                },
              ),
            const SizedBox(height: 24),
            Text('Lịch dạy trong tháng', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (monthRest.isEmpty)
              const Text('Không còn buổi nào khác trong tháng.')
            else
              ...monthRest.map(
                (s) {
                  final locked = svc.sessionBelongsToLockedClass(s);
                  return _SessionCard(
                    session: s,
                    locked: locked,
                    subtitle: _fmtRange(s),
                    phase: teacherSessionPhase(s, now),
                    onTap: () => _openDetail(context, s.id),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _SessionCard extends StatelessWidget {
  final TeachingSessionModel session;
  final bool locked;
  final String subtitle;
  final TeacherSessionPhase phase;
  final VoidCallback onTap;

  const _SessionCard({
    required this.session,
    required this.locked,
    required this.subtitle,
    required this.phase,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      child: ListTile(
        onTap: onTap,
        title: Text(session.lessonLabel),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(session.className, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle),
            Text('Buổi ${session.lessonNumber} / ${session.contractLessons} (hợp đồng)'),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                label: Text(teacherSessionPhaseLabel(phase)),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: switch (phase) {
                  TeacherSessionPhase.ended => Theme.of(context).colorScheme.surfaceContainerHighest,
                  TeacherSessionPhase.inProgress => Colors.indigo.shade50,
                  TeacherSessionPhase.checkInOpenBeforeClass => Colors.orange.shade50,
                  TeacherSessionPhase.upcoming => Colors.green.shade50,
                },
              ),
            ),
            if (locked) ...[
              const SizedBox(height: 6),
              Text(
                'Lớp đã khóa — vượt số buổi (chỉ admin được xóa / chỉnh)',
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
              ),
            ],
          ],
        ),
        trailing: Icon(
          locked ? Icons.lock_outline : Icons.chevron_right,
        ),
      ),
    );

    if (!locked) return card;

    return Opacity(
      opacity: 0.45,
      child: card,
    );
  }
}
