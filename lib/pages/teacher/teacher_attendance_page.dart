import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/attendance_model.dart';
import '../../models/teaching_session_model.dart';
import '../../services/attendance_service.dart';
import '../../services/payment_service.dart';
import '../../utils/teacher_session_schedule.dart';
import '../../utils/vietnamese_date_format.dart';
import '../../widgets/payment_card.dart';
import '../../widgets/qr_scanner_widget.dart';

/// Lịch demo backend: `schedule_id` theo lớp (đồng bộ với dropdown AttendancePage).
int demoScheduleIdForTeacherClass(String classId) {
  switch (classId) {
    case 'cls_flutter':
      return 1;
    case 'cls_web':
      return 3;
    case 'cls_scratch':
      return 2;
    case 'cls_python':
      return 1;
    case 'cls_checkin_demo':
      return 1;
    default:
      return 1;
  }
}

class TeacherAttendancePage extends StatefulWidget {
  final TeachingSessionModel session;

  const TeacherAttendancePage({super.key, required this.session});

  @override
  State<TeacherAttendancePage> createState() => _TeacherAttendancePageState();
}

class _TeacherAttendancePageState extends State<TeacherAttendancePage> {
  final _attendance = AttendanceService();
  final _payment = PaymentService();

  bool _loading = true;
  String? _error;
  List<SessionAttendanceRow> _roster = [];
  final Map<int, double> _outstandingByStudent = {};
  final Map<int, bool> _owesByStudent = {};

  int get _scheduleId => demoScheduleIdForTeacherClass(widget.session.classId);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final roster = await _attendance.fetchSessionRoster(
        scheduleId: _scheduleId,
        teachingSessionId: widget.session.id,
      );
      final outs = <int, double>{};
      final owesMap = <int, bool>{};
      for (final r in roster) {
        final total = await _payment.outstandingTotalVnd(r.studentId);
        outs[r.studentId] = total;
        owesMap[r.studentId] = await _payment.hasOutstandingFees(r.studentId);
      }
      if (!mounted) return;
      final normalized = <SessionAttendanceRow>[];
      for (final r in roster) {
        final studentOwes = owesMap[r.studentId] ?? false;
        final st = (studentOwes && _isPresentStatus(r.status)) ? 'Absent' : r.status;
        normalized.add(SessionAttendanceRow(studentId: r.studentId, studentName: r.studentName, status: st));
      }
      if (!mounted) return;
      setState(() {
        _roster = normalized;
        _outstandingByStudent
          ..clear()
          ..addAll(outs);
        _owesByStudent
          ..clear()
          ..addAll(owesMap);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _saveRoster() async {
    for (var i = 0; i < _roster.length; i++) {
      final r = _roster[i];
      if ((_owesByStudent[r.studentId] ?? false) && _isPresentStatus(r.status)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${r.studentName} còn nợ học phí — không thể lưu trạng thái Có mặt.')),
        );
        return;
      }
    }
    try {
      await _attendance.saveSessionAttendance(
        scheduleId: _scheduleId,
        teachingSessionId: widget.session.id,
        rows: _roster,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu điểm danh')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _showFeeAlert(SessionAttendanceRow row) {
    final total = _outstandingByStudent[row.studentId] ?? 0;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${row.studentName}: còn nợ ${formatVnd(total)} — nhắc đóng học phí trước buổi (demo).',
        ),
        action: SnackBarAction(
          label: 'QR thanh toán',
          onPressed: () => _openTuitionQrSheet(row),
        ),
      ),
    );
  }

  Future<void> _openTuitionQrSheet(SessionAttendanceRow row) async {
    await showDemoTuitionQrBottomSheet(
      context,
      studentId: row.studentId,
      studentName: row.studentName,
      className: widget.session.className,
      onPaidSuccess: _load,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final range = formatTeacherSessionRange(s.start.toLocal(), s.end.toLocal());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Điểm danh'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.className, style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 4),
                              Text(formatLessonLabelForSessionStart(
                                lessonNumber: s.lessonNumber,
                                sessionStart: s.start,
                              )),
                              const SizedBox(height: 4),
                              Text(range, style: Theme.of(context).textTheme.bodyMedium),
                              const SizedBox(height: 4),
                              Text(
                                'Buổi ${s.lessonNumber} / ${s.contractLessons} — schedule_id demo: $_scheduleId',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Danh sách học viên',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _roster.length,
                        itemBuilder: (context, index) {
                          final row = _roster[index];
                          final owes = _owesByStudent[row.studentId] ?? false;
                          final total = _outstandingByStudent[row.studentId] ?? 0;
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(row.studentName),
                                    subtitle: Text('ID: ${row.studentId}'),
                                    trailing: owes
                                        ? Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.end,
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
                                                ),
                                              ),
                                            ],
                                          )
                                        : Chip(
                                            label: const Text('Đã đủ phí'),
                                            visualDensity: VisualDensity.compact,
                                            backgroundColor: Colors.green.shade100,
                                          ),
                                  ),
                                  if (owes) ...[
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => _showFeeAlert(row),
                                          icon: const Icon(Icons.notifications_active_outlined, size: 18),
                                          label: const Text('Thông báo nhắc phí'),
                                        ),
                                        TextButton.icon(
                                          onPressed: () => _openTuitionQrSheet(row),
                                          icon: const Icon(Icons.qr_code_2, size: 18),
                                          label: const Text('QR thanh toán'),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: SegmentedButton<String>(
                                      segments: [
                                        ButtonSegment(
                                          value: 'Present',
                                          label: const Text('Có mặt'),
                                          enabled: !owes,
                                        ),
                                        const ButtonSegment(value: 'Absent', label: Text('Vắng')),
                                      ],
                                      selected: {row.status},
                                      onSelectionChanged: (set) {
                                        final next = set.first;
                                        if (next == 'Present' && owes) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Học viên còn nợ học phí — không thể điểm danh Có mặt.'),
                                            ),
                                          );
                                          return;
                                        }
                                        setState(() {
                                          _roster[index] = row.copyWith(status: next);
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: FilledButton(
                        onPressed: _saveRoster,
                        child: const Text('Lưu điểm danh'),
                      ),
                    ),
                  ],
                ),
    );
  }

  bool _isPresentStatus(String status) {
    final lower = status.toLowerCase();
    return lower == 'present' || lower == 'có mặt';
  }
}

/// QR thanh toán học phí (demo) — dùng từ điểm danh hoặc tab Khóa học.
Future<void> showDemoTuitionQrBottomSheet(
  BuildContext context, {
  required int studentId,
  required String studentName,
  required String className,
  Future<void> Function()? onPaidSuccess,
}) async {
  final payment = PaymentService();
  final total = await payment.outstandingTotalVnd(studentId);
  if (!context.mounted) return;
  if (total <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Học viên không còn khoản nợ (demo).')),
    );
    return;
  }
  final payload = jsonEncode({
    'type': 'TUTERO_PAY',
    'student_id': studentId,
    'student_name': studentName,
    'amount_vnd': total.round(),
    'class': className,
    'memo': 'Thanh toán học phí — QR giả lập (giáo viên tạo)',
  });
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: 24 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'QR thanh toán — $studentName',
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Số tiền: ${formatVnd(total)}',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            QRCodeWidget(data: payload),
            const SizedBox(height: 8),
            SelectableText(payload, style: Theme.of(ctx).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(
              'Trong thực tế, phụ huynh / học viên quét QR để chuyển khoản. Ở đây chỉ mô phỏng giao diện.',
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                try {
                  await payment.payTuition(
                    studentId: studentId,
                    amount: total,
                    note: 'QR giả lập — $className',
                  );
                  if (!context.mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã ghi nhận thanh toán (demo)')),
                  );
                  await onPaidSuccess?.call();
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              },
              child: const Text('Ghi nhận đã thanh toán (demo)'),
            ),
          ],
        ),
      );
    },
  );
}
