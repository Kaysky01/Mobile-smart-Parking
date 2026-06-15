import 'package:flutter/material.dart';

import '../../parking_history/presentation/parking_history_screen.dart';
import '../../transactions/presentation/transactions_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('History'),
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Parking'),
              Tab(text: 'Transactions'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ParkingHistoryScreen(embedded: true),
            TransactionsScreen(embedded: true),
          ],
        ),
      ),
    );
  }
}
