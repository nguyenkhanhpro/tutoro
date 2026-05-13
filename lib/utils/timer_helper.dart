import 'dart:async';

/// Đếm ngược có hủy được (QR hết hạn, đồng hồ đếm).
class CountdownController {
  CountdownController({
    required this.initialSeconds,
    required this.onTick,
    this.onComplete,
  });

  final int initialSeconds;
  final void Function(int remaining) onTick;
  final void Function()? onComplete;

  Timer? _timer;
  int _remaining = 0;

  int get remaining => _remaining;

  void start() {
    cancel();
    _remaining = initialSeconds;
    onTick(_remaining);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= 0) {
        cancel();
        return;
      }
      _remaining--;
      onTick(_remaining);
      if (_remaining <= 0) {
        cancel();
        onComplete?.call();
      }
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => cancel();
}
