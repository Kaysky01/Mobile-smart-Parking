import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/student_models.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_widgets.dart';

class TopUpHistoryScreen extends StatelessWidget {
  const TopUpHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final topUps = controller.topUps;

    if (topUps.isEmpty) {
      return const Center(
        child: AppCard(
          padding: EdgeInsets.all(24),
          child: EmptyState(
            icon: Icons.add_card_outlined,
            title: 'Belum ada top-up',
            message: 'Permintaan top-up akan ditampilkan di sini.',
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: topUps.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, index) => _TopUpCard(item: topUps[index]),
      ),
    );
  }
}

class _TopUpCard extends StatelessWidget {
  const _TopUpCard({required this.item});

  final TopUpRequest item;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.add_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatCurrency(item.amount),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  '${formatDate(item.createdAt)}  •  #${item.id}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(status: item.status),
        ],
      ),
    );
  }
}
