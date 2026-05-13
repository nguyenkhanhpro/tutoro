/// Nhãn ngày trong tuần theo cách gọi thông dụng ở Việt Nam (Thứ 2 … Chủ nhật).
String vietnameseWeekdayLabel(DateTime localDateTime) {
  switch (localDateTime.weekday) {
    case DateTime.monday:
      return 'Thứ 2';
    case DateTime.tuesday:
      return 'Thứ 3';
    case DateTime.wednesday:
      return 'Thứ 4';
    case DateTime.thursday:
      return 'Thứ 5';
    case DateTime.friday:
      return 'Thứ 6';
    case DateTime.saturday:
      return 'Thứ 7';
    case DateTime.sunday:
      return 'Chủ nhật';
    default:
      return '';
  }
}

/// Ví dụ: `Thứ 4 13/05/2026 19:00 - 21:00`
String formatTeacherSessionRange(DateTime startLocal, DateTime endLocal) {
  String two(int n) => n.toString().padLeft(2, '0');
  final a = startLocal;
  final b = endLocal;
  final w = vietnameseWeekdayLabel(a);
  return '$w ${two(a.day)}/${two(a.month)}/${a.year} ${two(a.hour)}:${two(a.minute)} - ${two(b.hour)}:${two(b.minute)}';
}
