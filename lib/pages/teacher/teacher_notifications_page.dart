import 'package:flutter/material.dart';
import '../../models/notification_model.dart';
import '../../services/teacher_notification_service.dart';
import '../../widgets/notification_tile.dart';

class TeacherNotificationsPage extends StatefulWidget {
  const TeacherNotificationsPage({super.key});

  @override
  State<TeacherNotificationsPage> createState() => _TeacherNotificationsPageState();
}

class _TeacherNotificationsPageState extends State<TeacherNotificationsPage> {
  bool _loading = true;
  List<NotificationModel> _items = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final list = await TeacherNotificationService.instance.buildListAsync(DateTime.now());
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.notifications_off_outlined, size: 48),
              const SizedBox(height: 12),
              const Text('Không có thông báo', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: _reload, child: const Text('Làm mới')),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
            label: const Text('Làm mới'),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              return NotificationTile(
                model: item,
                onTap: () {
                  if (item.isRead) return;
                  setState(() {
                    _items[index] = item.copyWith(isRead: true);
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
