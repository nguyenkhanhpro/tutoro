import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/payment_model.dart';
import '../utils/constants.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._();
  factory PaymentService() => _instance;
  PaymentService._();

  /// Demo: sau khi thanh toán giả lập thành công, học viên này không còn khoản nợ mock.
  final Set<int> _demoTuitionClearedStudentIds = <int>{};

  String get _base => AppConstants.baseApiUrl;

  /// Danh sách khoản học phí (StudentFeePage).
  Future<List<StudentFeeItem>> fetchStudentFees(int studentId) async {
    try {
      final response = await http.get(
        Uri.parse('$_base/students/$studentId/fees'),
      );
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        return list.map((e) => StudentFeeItem.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('fetchStudentFees API: $e');
    }
    return _mockFees(studentId);
  }

  /// Có khoản cần thanh toán (pending / overdue).
  Future<bool> hasOutstandingFees(int studentId) async {
    final fees = await fetchStudentFees(studentId);
    return fees.any((f) {
      final s = f.status.toLowerCase();
      return s == 'pending' || s == 'overdue' || s == 'unpaid';
    });
  }

  Future<double> outstandingTotalVnd(int studentId) async {
    final fees = await fetchStudentFees(studentId);
    return fees
        .where((f) {
          final s = f.status.toLowerCase();
          return s == 'pending' || s == 'overdue' || s == 'unpaid';
        })
        .fold<double>(0, (a, b) => a + b.amountVnd);
  }

  Future<List<PaymentModel>> fetchPaymentHistory(int studentId) async {
    try {
      final response = await http.get(
        Uri.parse('$_base/payments/student/$studentId'),
      );
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        return list.map((e) => PaymentModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('fetchPaymentHistory API: $e');
    }
    return [
      PaymentModel(
        id: 1,
        studentId: studentId,
        amount: 2_000_000,
        status: 'completed',
        description: 'Flutter Basic — kỳ 1',
        paidAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ];
  }

  /// Thanh toán học phí: validate số tiền > 0 (logic nghiệp vụ).
  Future<void> payTuition({
    required int studentId,
    required double amount,
    String? note,
  }) async {
    if (amount <= 0) {
      throw Exception('Số tiền phải lớn hơn 0');
    }
    if (amount > 1_000_000_000) {
      throw Exception('Số tiền vượt quá hạn mức cho phép');
    }
    final bodyMap = <String, dynamic>{
      'student_id': studentId,
      'amount': amount,
    };
    if (note != null && note.isNotEmpty) {
      bodyMap['note'] = note;
    }
    final body = jsonEncode(bodyMap);
    try {
      final response = await http.post(
        Uri.parse('$_base/payments'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      if (response.statusCode == 200 || response.statusCode == 201) return;
    } catch (e) {
      if (kDebugMode) debugPrint('payTuition API: $e');
    }
    _demoTuitionClearedStudentIds.add(studentId);
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  List<StudentFeeItem> _mockFees(int studentId) {
    if (_demoTuitionClearedStudentIds.contains(studentId)) {
      return [];
    }
    final dueSoon = DateTime.now().add(const Duration(days: 7));
    final duePast = DateTime.now().subtract(const Duration(days: 3));
    switch (studentId) {
      case 1:
        return [
          StudentFeeItem(
            id: 1,
            title: 'Flutter Basic (CLS001)',
            amountVnd: 5_000_000,
            dueDate: dueSoon,
            status: 'pending',
          ),
        ];
      case 2:
        return [];
      case 3:
        return [
          StudentFeeItem(
            id: 10,
            title: 'Web Fullstack — kỳ 2',
            amountVnd: 3_200_000,
            dueDate: duePast,
            status: 'overdue',
          ),
        ];
      default:
        if (!AppConstants.demoStudentOwesFees) {
          return [];
        }
        return [
          StudentFeeItem(
            id: 1,
            title: 'Flutter Basic (CLS001)',
            amountVnd: 5_000_000,
            dueDate: dueSoon,
            status: 'pending',
          ),
          StudentFeeItem(
            id: 2,
            title: 'Web Fullstack (CLS002)',
            amountVnd: 4_500_000,
            dueDate: dueSoon.add(const Duration(days: 14)),
            status: 'pending',
          ),
        ];
    }
  }
}
