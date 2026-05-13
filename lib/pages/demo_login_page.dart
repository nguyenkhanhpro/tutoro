import 'package:flutter/material.dart';
import 'teacher/teacher_main_shell.dart';

/// Cổng demo (login thật do nhóm tích hợp sau — chỉ còn ứng dụng cho giáo viên).
class DemoLoginPage extends StatelessWidget {
  const DemoLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Icon(Icons.school, size: 72, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Tutoro — Giảng viên',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Ứng dụng chỉ dành cho giáo viên quản lý lịch dạy. (Demo — thay bằng màn đăng nhập thật của nhóm.)',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              const SizedBox(height: 40),
              FilledButton.icon(
                style: FilledButton.styleFrom(padding: const EdgeInsets.all(18)),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(builder: (_) => const TeacherMainShell()),
                  );
                },
                icon: const Icon(Icons.login),
                label: const Text('Vào ứng dụng (demo)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
