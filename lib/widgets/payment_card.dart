import 'package:flutter/material.dart';
import '../models/payment_model.dart';

String formatVnd(double amount) {
  final value = amount.round().abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < value.length; i++) {
    final idxFromEnd = value.length - i;
    if (i > 0 && idxFromEnd % 3 == 0) buf.write('.');
    buf.write(value[i]);
  }
  final prefix = amount < 0 ? '-' : '';
  return '$prefix$buf đ';
}

class PaymentCard extends StatelessWidget {
  final PaymentModel payment;

  const PaymentCard({super.key, required this.payment});

  Color _statusColor(BuildContext context) {
    final s = payment.status.toLowerCase();
    if (s.contains('complete') || s.contains('success') || s == 'paid') {
      return Colors.green.shade700;
    }
    if (s.contains('pending')) return Colors.orange.shade800;
    if (s.contains('fail')) return Theme.of(context).colorScheme.error;
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    payment.description ?? 'Thanh toán học phí',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(
                  formatVnd(payment.amount),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(context).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    payment.status,
                    style: theme.textTheme.labelMedium?.copyWith(color: _statusColor(context)),
                  ),
                ),
                if (payment.paidAt != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    _paidLabel(payment.paidAt!),
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _paidLabel(DateTime dt) {
    final l = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(l.day)}/${two(l.month)}/${l.year} ${two(l.hour)}:${two(l.minute)}';
  }
}

class StudentFeeCard extends StatelessWidget {
  final StudentFeeItem fee;
  final VoidCallback? onPayPressed;

  const StudentFeeCard({
    super.key,
    required this.fee,
    this.onPayPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pending = fee.status.toLowerCase() == 'pending';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(fee.title, style: theme.textTheme.titleMedium),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Số tiền: ${formatVnd(fee.amountVnd)}', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
              if (fee.dueDate != null)
                Text(
                  'Hạn: ${_date(fee.dueDate!)}',
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
        ),
        trailing: pending
            ? TextButton(
                onPressed: onPayPressed,
                child: const Text('Thanh toán'),
              )
            : const Icon(Icons.check_circle, color: Colors.green),
      ),
    );
  }

  String _date(DateTime d) {
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(l.day)}/${two(l.month)}/${l.year}';
  }
}
