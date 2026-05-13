import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';
import '../utils/constants.dart';
import '../utils/vietnamese_date_format.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  bool _teacherMode = false;
  bool _loading = true;
  String? _error;
  List<AttendanceModel> _history = [];
  List<SessionAttendanceRow> _roster = [];
  int _scheduleId = AppConstants.demoScheduleId;

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
      final history = await AttendanceService().fetchStudentAttendance(AppConstants.demoStudentId);
      final roster = await AttendanceService().fetchSessionRoster(scheduleId: _scheduleId);
      setState(() {
        _history = history;
        _roster = roster;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _saveRoster() async {
    try {
      await AttendanceService().saveSessionAttendance(
        scheduleId: _scheduleId,
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

  String _statusLabel(String status) {
    final s = status.toLowerCase();
    if (s == 'present' || s == 'có mặt') return 'Có mặt';
    if (s == 'absent' || s == 'vắng') return 'Vắng';
    return status;
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'present' || s == 'có mặt') return Colors.green.shade700;
    if (s == 'absent' || s == 'vắng') return Colors.red.shade700;
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Điểm danh'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
          TextButton(
            onPressed: () => setState(() => _teacherMode = !_teacherMode),
            child: Text(_teacherMode ? 'Học viên' : 'Giảng viên'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _teacherMode
                  ? _buildTeacherPanel(context)
                  : _buildStudentHistory(context),
    );
  }

  Widget _buildStudentHistory(BuildContext context) {
    if (_history.isEmpty) {
      return const Center(child: Text('Chưa có dữ liệu điểm danh'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        final dateStr = item.sessionTime ?? item.checkinTime;
        String subtitle = '—';
        if (dateStr != null) {
          final l = dateStr.toLocal();
          String two(int n) => n.toString().padLeft(2, '0');
          final w = vietnameseWeekdayLabel(l);
          subtitle = '$w ${two(l.day)}/${two(l.month)}/${l.year} ${two(l.hour)}:${two(l.minute)}';
        }
        return Card(
          child: ListTile(
            leading: Icon(Icons.calendar_today, color: _statusColor(item.status)),
            title: Text(item.className ?? 'Lớp học'),
            subtitle: Text(subtitle),
            trailing: Chip(
              label: Text(_statusLabel(item.status)),
              backgroundColor: _statusColor(item.status).withValues(alpha: 0.15),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeacherPanel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Text('Buổi học (schedule_id):'),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: _scheduleId,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('SCH001 — Flutter')),
                  DropdownMenuItem(value: 2, child: Text('SCH002 — Flutter')),
                  DropdownMenuItem(value: 3, child: Text('SCH003 — Web')),
                ],
                onChanged: (v) async {
                  if (v == null) return;
                  setState(() => _scheduleId = v);
                  final roster = await AttendanceService().fetchSessionRoster(scheduleId: v);
                  setState(() => _roster = roster);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _roster.length,
            itemBuilder: (context, index) {
              final row = _roster[index];
              return Card(
                child: ListTile(
                  title: Text(row.studentName),
                  subtitle: Text('ID: ${row.studentId}'),
                  trailing: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Present', label: Text('Có mặt')),
                      ButtonSegment(value: 'Absent', label: Text('Vắng')),
                    ],
                    selected: {row.status},
                    onSelectionChanged: (set) {
                      final next = set.first;
                      setState(() {
                        _roster[index] = row.copyWith(status: next);
                      });
                    },
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
    );
  }
}
