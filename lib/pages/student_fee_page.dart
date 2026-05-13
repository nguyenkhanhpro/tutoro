import 'package:flutter/material.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';
import '../utils/constants.dart';
import '../widgets/payment_card.dart';

class StudentFeePage extends StatefulWidget {
  const StudentFeePage({super.key});

  @override
  State<StudentFeePage> createState() => _StudentFeePageState();
}

class _StudentFeePageState extends State<StudentFeePage> {
  late Future<List<StudentFeeItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = PaymentService().fetchStudentFees(AppConstants.demoStudentId);
  }

  void _refresh() {
    setState(() {
      _future = PaymentService().fetchStudentFees(AppConstants.demoStudentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Học phí'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<List<StudentFeeItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  AppConstants.demoStudentOwesFees
                      ? 'Không có khoản học phí'
                      : 'Bạn không có khoản học phí cần thanh toán',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final fee = items[i];
              return StudentFeeCard(
                fee: fee,
                onPayPressed: () {
                  Navigator.pushNamed(context, '/payment');
                },
              );
            },
          );
        },
      ),
    );
  }
}
