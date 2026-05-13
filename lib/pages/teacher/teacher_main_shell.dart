import 'package:flutter/material.dart';
import '../demo_login_page.dart';
import 'teacher_courses_page.dart';
import 'teacher_home_page.dart';
import 'teacher_notifications_page.dart';

class TeacherMainShell extends StatefulWidget {
  const TeacherMainShell({super.key});

  @override
  State<TeacherMainShell> createState() => _TeacherMainShellState();
}

class _TeacherMainShellState extends State<TeacherMainShell> {
  int _index = 0;

  static const _titles = ['Quản lý giảng dạy', 'Thông báo', 'Khóa học'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            tooltip: 'Thoát demo',
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(builder: (_) => const DemoLoginPage()),
                (_) => false,
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          TeacherHomePage(),
          TeacherNotificationsPage(),
          TeacherCoursesPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Quản lý',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Thông báo',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Khóa học',
          ),
        ],
      ),
    );
  }
}
