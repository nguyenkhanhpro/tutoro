import 'dart:async';
import 'package:flutter/material.dart';
import '../services/attendance_service.dart';
import '../services/demo_checkin_session.dart';
import '../services/demo_schedule_store.dart';
import '../services/payment_service.dart';
import '../utils/constants.dart';
import '../utils/timer_helper.dart';
import '../widgets/qr_scanner_widget.dart';

enum CheckInRole { teacher, student }

class CheckInPage extends StatefulWidget {
  /// Khi `true`: không dùng Scaffold/AppBar riêng (nhúng trong shell khác).
  final bool embedInStudentShell;

  const CheckInPage({super.key, this.embedInStudentShell = false});

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  final DemoScheduleStore _schedule = DemoScheduleStore.instance;
  final DemoCheckInSession _session = DemoCheckInSession.instance;

  CheckInRole _role = CheckInRole.student;
  CountdownController? _teacherCountdown;
  int _teacherSecondsLeft = 0;
  Timer? _uiClock;
  bool _owesFees = false;

  @override
  void initState() {
    super.initState();
    _session.addListener(_onSessionChanged);
    _uiClock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
    _refreshOwesFees();
  }

  Future<void> _refreshOwesFees() async {
    final owes = await PaymentService().hasOutstandingFees(AppConstants.demoStudentId);
    if (mounted) setState(() => _owesFees = owes);
  }

  void _onSessionChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _uiClock?.cancel();
    _session.removeListener(_onSessionChanged);
    _teacherCountdown?.dispose();
    super.dispose();
  }

  void _stopTeacherCountdown() {
    _teacherCountdown?.dispose();
    _teacherCountdown = null;
    _teacherSecondsLeft = 0;
  }

  void _startTeacherCountdown() {
    _stopTeacherCountdown();
    _teacherCountdown = CountdownController(
      initialSeconds: AppConstants.qrValiditySeconds,
      onTick: (s) => setState(() => _teacherSecondsLeft = s),
      onComplete: () {
        _session.close();
        _stopTeacherCountdown();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã hết thời gian phiên check-in')),
          );
        }
        setState(() {});
      },
    )..start();
    setState(() => _teacherSecondsLeft = AppConstants.qrValiditySeconds);
  }

  void _teacherOpenCheckIn() {
    _session.openByTeacher();
    _startTeacherCountdown();
    setState(() {});
  }

  void _teacherCloseCheckIn() {
    _session.close();
    _stopTeacherCountdown();
    setState(() {});
  }

  Future<void> _studentSubmit(String qrCode) async {
    try {
      await AttendanceService().checkIn(
        studentId: AppConstants.demoStudentId,
        classId: AppConstants.demoClassFlutter,
        scheduleId: AppConstants.demoScheduleId,
        qrCode: qrCode,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-in thành công')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _openScanner() async {
    if (!_session.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giảng viên chưa mở check-in')),
      );
      return;
    }
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QrScannerPage()),
    );
    if (code != null && code.isNotEmpty) {
      await _studentSubmit(code);
    }
  }

  String _formatDateTime(DateTime dt) {
    final l = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(l.day)}/${two(l.month)}/${l.year} ${two(l.hour)}:${two(l.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final classStart = _schedule.classSessionStart;
    final windowOpenAt = _schedule.checkInWindowOpensAt(classStart);
    final upcoming = _schedule.isTooEarlyForCheckIn(now);
    final past = _schedule.isAfterCheckInSlot(now);

    final body = Padding(
      padding: const EdgeInsets.all(20),
      child: widget.embedInStudentShell
          ? _buildStudentBody(
              context,
              classStart: classStart,
              windowOpenAt: windowOpenAt,
              upcoming: upcoming,
              past: past,
            )
          : (_role == CheckInRole.teacher
              ? _buildTeacherBody(
                  context,
                  classStart: classStart,
                  windowOpenAt: windowOpenAt,
                  upcoming: upcoming,
                  past: past,
                )
              : _buildStudentBody(
                  context,
                  classStart: classStart,
                  windowOpenAt: windowOpenAt,
                  upcoming: upcoming,
                  past: past,
                )),
    );

    if (widget.embedInStudentShell) {
      return SingleChildScrollView(child: body);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-in'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SegmentedButton<CheckInRole>(
              segments: const [
                ButtonSegment(value: CheckInRole.teacher, label: Text('Giảng viên'), icon: Icon(Icons.school_outlined)),
                ButtonSegment(value: CheckInRole.student, label: Text('Học viên'), icon: Icon(Icons.person_outlined)),
              ],
              selected: {_role},
              onSelectionChanged: (s) {
                setState(() => _role = s.first);
              },
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.event_available),
            tooltip: 'Điểm danh',
            onPressed: () => Navigator.pushNamed(context, '/attendance'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.pushNamed(context, '/notification'),
          ),
          if (_role == CheckInRole.student && _owesFees)
            IconButton(
              icon: const Icon(Icons.payments_outlined),
              tooltip: 'Thanh toán học phí',
              onPressed: () => Navigator.pushNamed(context, '/payment'),
            ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildTeacherBody(
    BuildContext context, {
    required DateTime classStart,
    required DateTime windowOpenAt,
    required bool upcoming,
    required bool past,
  }) {
    final theme = Theme.of(context);
    if (upcoming) {
      return _messageCard(
        context,
        title: 'Buổi học sắp diễn ra',
        lines: [
          'Lớp: ${AppConstants.demoClassName}',
          'Giờ vào lớp dự kiến: ${_formatDateTime(classStart)}',
          'Check-in cho phép từ: ${_formatDateTime(windowOpenAt)} (${AppConstants.reminderMinutesBeforeClass} phút trước giờ học)',
          'Múi giờ: ${AppConstants.timezoneLabel}',
        ],
        icon: Icons.event_note,
      );
    }
    if (past) {
      return _messageCard(
        context,
        title: 'Đã kết thúc thời gian check-in',
        lines: [
          'Buổi học demo đã qua cửa sổ check-in.',
          'Khởi động lại app để tạo lịch demo mới (nếu cần).',
        ],
        icon: Icons.event_busy,
      );
    }

    if (!_session.isActive) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Đã đến cửa sổ check-in',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Buổi học: ${_formatDateTime(classStart)} — bấm nút bên dưới để mở phiên check-in cho học viên.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: _teacherOpenCheckIn,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Mở check-in buổi học'),
          ),
        ],
      );
    }

    final payload = _session.qrPayload ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Phiên check-in đang mở',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Thời gian còn lại: $_teacherSecondsLeft giây',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Text('Mã QR cho học viên quét', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(child: QRCodeWidget(data: payload)),
          ),
        ),
        const SizedBox(height: 8),
        SelectableText(payload, style: theme.textTheme.bodySmall),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: _teacherCloseCheckIn,
          icon: const Icon(Icons.stop_circle_outlined),
          label: const Text('Kết thúc phiên check-in'),
        ),
      ],
    );
  }

  Widget _buildStudentBody(
    BuildContext context, {
    required DateTime classStart,
    required DateTime windowOpenAt,
    required bool upcoming,
    required bool past,
  }) {
    final theme = Theme.of(context);
    if (upcoming) {
      return _messageCard(
        context,
        title: 'Buổi học sắp diễn ra',
        lines: [
          'Lớp: ${AppConstants.demoClassName}',
          'Giờ vào lớp dự kiến: ${_formatDateTime(classStart)}',
          'Bạn có thể check-in khi giảng viên mở phiên, trong khoảng ${AppConstants.reminderMinutesBeforeClass} phút trước giờ học.',
          'Mở cửa check-in: ${_formatDateTime(windowOpenAt)}',
        ],
        icon: Icons.hourglass_top,
      );
    }
    if (past) {
      return _messageCard(
        context,
        title: 'Đã kết thúc thời gian check-in',
        lines: const [
          'Buổi học demo đã qua cửa sổ check-in.',
        ],
        icon: Icons.event_busy,
      );
    }

    if (!_session.isActive) {
      return _messageCard(
        context,
        title: 'Đang chờ giảng viên mở check-in',
        lines: [
          'Đã trong thời gian cho phép check-in, nhưng giảng viên chưa bấm "Mở check-in buổi học".',
          'Vui lòng chờ GV hiển thị mã QR.',
        ],
        icon: Icons.qr_code_2,
      );
    }

    final remain = _session.secondsRemaining();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Check-in buổi học', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Thời gian còn lại của phiên: $remain giây',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Text(
          'Quét mã QR do giảng viên hiển thị (không phải thanh toán).',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: remain > 0 ? _openScanner : null,
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Quét QR để check-in'),
        ),
      ],
    );
  }

  Widget _messageCard(
    BuildContext context, {
    required String title,
    required List<String> lines,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final line in lines) ...[
              Text(line, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}
