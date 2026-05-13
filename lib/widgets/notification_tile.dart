import 'package:flutter/material.dart';
import '../models/notification_model.dart';

class NotificationTile extends StatelessWidget {
  final NotificationModel model;
  final VoidCallback? onTap;

  const NotificationTile({
    super.key,
    required this.model,
    this.onTap,
  });

  IconData _iconFor(NotificationKind k) {
    switch (k) {
      case NotificationKind.scheduleReminder:
        return Icons.schedule;
      case NotificationKind.attendance:
        return Icons.how_to_reg_outlined;
      case NotificationKind.payment:
        return Icons.payment;
      case NotificationKind.general:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: model.isRead ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.primaryContainer,
          child: Icon(
            _iconFor(model.kind),
            color: model.isRead ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          model.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: model.isRead ? FontWeight.w500 : FontWeight.w700,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(model.message),
            if (model.createdAt != null) ...[
              const SizedBox(height: 6),
              Text(
                _formatTime(model.createdAt!),
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
          ],
        ),
        trailing: model.isRead ? null : Icon(Icons.circle, size: 10, color: theme.colorScheme.primary),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
  }
}
