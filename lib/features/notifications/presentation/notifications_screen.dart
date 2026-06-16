import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/state/app_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  DateTime? _lastReadTime;

  @override
  void initState() {
    super.initState();
    _loadLastReadTime();
  }

  Future<void> _loadLastReadTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('notifications_last_read_time');
    if (timestamp != null) {
      setState(() {
        _lastReadTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      });
    }
  }

  Future<void> _markAsRead() async {
    await context.read<AppController>().markNotificationsAsRead();
    setState(() {
      _lastReadTime = context.read<AppController>().lastReadNotificationTime;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();

    // Filter approved top-ups
    final approved = controller.topUps
        .where((item) => item.status == 'approved')
        .take(3);

    // Only show parking success if there is parking history
    final showParkingHistory = controller.parkingHistory.isNotEmpty;

    final notifications = <Widget>[
      if (controller.balance < 10000)
        _NotificationTile(
          icon: Icons.warning_amber_rounded,
          color: AppColors.warning,
          title: 'Low balance warning',
          message: 'Top up soon to keep your RFID card ready for parking.',
          isRead: _lastReadTime != null,
        ),
      for (final item in approved)
        _NotificationTile(
          icon: Icons.check_circle_outline_rounded,
          color: AppColors.success,
          title: 'Top up approved',
          message:
              '${formatCurrency(item.amount)} was approved on ${formatDate(item.createdAt)}.',
          isRead:
              _lastReadTime != null &&
              item.createdAt != null &&
              (item.createdAt!.isBefore(_lastReadTime!) ||
                  item.createdAt!.isAtSameMomentAs(_lastReadTime!)),
        ),
      if (showParkingHistory)
        _NotificationTile(
          icon: Icons.local_parking_rounded,
          color: AppColors.primary,
          title: 'Parking transaction successful',
          message:
              'Your latest parking payment was ${formatCurrency(controller.parkingHistory.first.cost)}.',
          isRead:
              _lastReadTime != null &&
              controller.parkingHistory.first.entryTime != null &&
              (controller.parkingHistory.first.entryTime!.isBefore(
                    _lastReadTime!,
                  ) ||
                  controller.parkingHistory.first.entryTime!.isAtSameMomentAs(
                    _lastReadTime!,
                  )),
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all_rounded),
              tooltip: 'Mark all as read',
              onPressed: _markAsRead,
            ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: notifications.isEmpty ? 1 : notifications.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          if (notifications.isEmpty) {
            return const AppCard(
              child: EmptyState(
                icon: Icons.notifications_none_rounded,
                title: 'All caught up',
                message: 'Account and parking updates will appear here.',
              ),
            );
          }
          return notifications[index];
        },
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
    this.isRead = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final bool isRead;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isRead
              ? Colors.transparent
              : AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(22),
          border: isRead
              ? null
              : Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isRead
                    ? color.withValues(alpha: 0.12)
                    : color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(15),
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
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    message,
                    style: TextStyle(
                      color: isRead ? AppColors.textSecondary : AppColors.text,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (!isRead)
              Container(
                margin: const EdgeInsets.only(top: 6, left: 8),
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
