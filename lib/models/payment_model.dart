class PaymentModel {
  final int id;
  final int studentId;
  final double amount;
  final String status;
  final String? description;
  final DateTime? paidAt;

  PaymentModel({
    required this.id,
    required this.studentId,
    required this.amount,
    required this.status,
    this.description,
    this.paidAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    DateTime? paid;
    final raw = json['paid_at'] ?? json['paidAt'];
    if (raw is String && raw.isNotEmpty) paid = DateTime.tryParse(raw);

    return PaymentModel(
      id: _asInt(json['id']),
      studentId: _asInt(json['student_id'] ?? json['studentId']),
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      status: (json['status'] ?? '').toString(),
      description: json['description']?.toString(),
      paidAt: paid,
    );
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}

/// Khoản học phí cần thanh toán (StudentFeePage).
class StudentFeeItem {
  final int id;
  final String title;
  final double amountVnd;
  final DateTime? dueDate;
  final String status;

  StudentFeeItem({
    required this.id,
    required this.title,
    required this.amountVnd,
    this.dueDate,
    required this.status,
  });

  factory StudentFeeItem.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    final id = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '') ?? 0;
    return StudentFeeItem(
      id: id,
      title: (json['title'] ?? json['course'] ?? 'Học phí').toString(),
      amountVnd: (json['amount'] is num) ? (json['amount'] as num).toDouble() : double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      dueDate: json['due_date'] != null ? DateTime.tryParse(json['due_date'].toString()) : null,
      status: (json['status'] ?? 'pending').toString(),
    );
  }
}
