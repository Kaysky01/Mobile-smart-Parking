import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/student_models.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_widgets.dart';

enum TransactionFilter { all, parking, topup }

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  TransactionFilter _filter = TransactionFilter.all;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final items = controller.transactions.where((item) {
      return switch (_filter) {
        TransactionFilter.all => true,
        TransactionFilter.parking => item.type == TransactionType.parking,
        TransactionFilter.topup => item.type == TransactionType.topup,
      };
    }).toList();

    final content = Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: SegmentedButton<TransactionFilter>(
            segments: const [
              ButtonSegment(value: TransactionFilter.all, label: Text('All')),
              ButtonSegment(
                value: TransactionFilter.parking,
                label: Text('Parking'),
              ),
              ButtonSegment(
                value: TransactionFilter.topup,
                label: Text('Top Up'),
              ),
            ],
            selected: {_filter},
            onSelectionChanged: (value) =>
                setState(() => _filter = value.first),
            showSelectedIcon: false,
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (items.isEmpty)
                  const AppCard(
                    child: EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No transactions',
                      message: 'Parking payments and top ups appear here.',
                    ),
                  )
                else
                  ...items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TransactionCard(item: item),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );

    if (widget.embedded) return content;
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: content,
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.item});

  final StudentTransaction item;

  @override
  Widget build(BuildContext context) {
    final isTopup = item.type == TransactionType.topup;
    final color = isTopup ? AppColors.success : AppColors.primary;
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              isTopup ? Icons.add_rounded : Icons.local_parking_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  formatDateTime(item.createdAt),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isTopup ? '+' : '-'}${formatCurrency(item.amount.abs())}',
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
