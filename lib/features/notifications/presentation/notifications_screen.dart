import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/state/app_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final approved = controller.topUps
        .where((item) => item.status == 'approved')
        .take(3);
    final notifications = <Widget>[
      if (controller.balance < 10000)
        const _NotificationTile(
          icon: Icons.warning_amber_rounded,
          color: AppColors.warning,
          title: 'Low balance warning',
          message: 'Top up soon to keep your RFID card ready for parking.',
        ),
      for (final item in approved)
        _NotificationTile(
          icon: Icons.check_circle_outline_rounded,
          color: AppColors.success,
          title: 'Top up approved',
          message:
              '${formatCurrency(item.amount)} was approved on ${formatDate(item.createdAt)}.',
        ),
      if (controller.parkingHistory.isNotEmpty)
        _NotificationTile(
          icon: Icons.local_parking_rounded,
          color: AppColors.primary,
          title: 'Parking transaction successful',
          message:
              'Your latest parking payment was ${formatCurrency(controller.parkingHistory.first.cost)}.',
        ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: PagePadding(
        child: notifications.isEmpty
            ? const AppCard(
                child: EmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: 'All caught up',
                  message: 'Account and parking updates will appear here.',
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: notifications.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, index) => notifications[index],
              ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
