import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';
import '../widgets/notification_tile.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late Future<List<NotificationModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = NotificationService().loadNotificationsForUser(
      userId: AppConstants.demoStudentId,
    );
  }

  void _refresh() {
    setState(() {
      _future = NotificationService().loadNotificationsForUser(
        userId: AppConstants.demoStudentId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<List<NotificationModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return const Center(child: Text('Không có thông báo'));
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return NotificationTile(
                model: item,
                onTap: () {
                  if (item.isRead) return;
                  setState(() {
                    final copy = List<NotificationModel>.from(list);
                    copy[index] = item.copyWith(isRead: true);
                    _future = Future.value(copy);
                  });
                },
              );
            },
          );
        },
      ),
    );
  }
}
