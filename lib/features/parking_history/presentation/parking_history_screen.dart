import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/student_models.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_widgets.dart';

class ParkingHistoryScreen extends StatelessWidget {
  const ParkingHistoryScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final content = RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (controller.parkingHistory.isEmpty)
            const AppCard(
              child: EmptyState(
                icon: Icons.local_parking_outlined,
                title: 'No parking history',
                message: 'Completed and active parking visits appear here.',
              ),
            )
          else
            ...controller.parkingHistory.map(
              (activity) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ParkingCard(activity: activity),
              ),
            ),
        ],
      ),
    );

    if (embedded) return content;
    return Scaffold(
      appBar: AppBar(title: const Text('Parking History')),
      body: content,
    );
  }
}

class _ParkingCard extends StatelessWidget {
  const _ParkingCard({required this.activity});

  final ParkingActivity activity;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.directions_car_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatDate(activity.entryTime),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      formatDuration(activity.duration),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatCurrency(activity.cost),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _TimeDetail(
                  label: 'ENTRY TIME',
                  value: formatTime(activity.entryTime),
                  icon: Icons.login_rounded,
                ),
              ),
              Expanded(
                child: _TimeDetail(
                  label: 'EXIT TIME',
                  value: formatTime(activity.exitTime),
                  icon: Icons.logout_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeDetail extends StatelessWidget {
  const _TimeDetail({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 9,
                letterSpacing: 0.7,
              ),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
