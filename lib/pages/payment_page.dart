import 'package:flutter/material.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';
import '../utils/constants.dart';
import '../widgets/payment_card.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  bool _busy = false;
  bool _loading = true;
  bool _hasOutstanding = false;
  double _outstandingTotal = 0;
  List<PaymentModel> _history = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final owes = await PaymentService().hasOutstandingFees(AppConstants.demoStudentId);
    final total = await PaymentService().outstandingTotalVnd(AppConstants.demoStudentId);
    final list = await PaymentService().fetchPaymentHistory(AppConstants.demoStudentId);
    if (!mounted) return;
    setState(() {
      _hasOutstanding = owes;
      _outstandingTotal = total;
      _history = list;
      _loading = false;
      if (owes && total > 0 && amountController.text.isEmpty) {
        amountController.text = total.round().toString();
      }
    });
  }

  Future<void> handlePayment() async {
    if (!_hasOutstanding) return;
    final raw = amountController.text.trim().replaceAll('.', '').replaceAll(',', '');
    final amount = double.tryParse(raw);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số tiền không hợp lệ')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await PaymentService().payTuition(
        studentId: AppConstants.demoStudentId,
        amount: amount,
        note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
      );
      if (!mounted) return;
      amountController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanh toán thành công')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán học phí'),
        actions: [
          IconButton(
            icon: const Icon(Icons.request_quote_outlined),
            tooltip: 'Học phí',
            onPressed: () => Navigator.pushNamed(context, '/student-fees'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!_hasOutstanding) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline, size: 40, color: Colors.green.shade700),
                    const SizedBox(height: 12),
                    Text(
                      'Bạn không có khoản học phí cần thanh toán',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Thanh toán chỉ dành cho học viên còn nợ / chưa đóng học phí theo kỳ.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ] else ...[
            Text(
              'Số tiền cần thanh toán (ước tính): ${_outstandingTotal.round()} VND',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Số tiền (VND)',
                hintText: 'Ví dụ: 2000000',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (tuỳ chọn)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : handlePayment,
              child: _busy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Thanh toán'),
            ),
            const SizedBox(height: 24),
          ],
          Text('Lịch sử giao dịch', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_history.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Chưa có giao dịch')),
            )
          else
            ..._history.map((p) => PaymentCard(payment: p)),
        ],
      ),
    );
  }
}
