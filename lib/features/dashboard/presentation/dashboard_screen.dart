import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/state/app_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../transactions/presentation/transactions_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.onSelectTab});

  final ValueChanged<int> onSelectTab;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppController>().loadLastReadNotificationTime();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final profile = controller.profile;
    final now = DateTime.now();
    final monthlyParking = controller.parkingHistory
        .where(
          (item) =>
              item.entryTime?.year == now.year &&
              item.entryTime?.month == now.month,
        )
        .toList();
    final monthlyCost = monthlyParking.fold<double>(
      0,
      (sum, item) => sum + item.cost,
    );

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: PagePadding(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Welcome back',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  'Hello, ${profile?.name.split(' ').first ?? 'Student'}',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            tooltip: 'Notifications',
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const NotificationsScreen(),
                              ),
                            ),
                            icon: Badge(
                              isLabelVisible: controller.hasUnreadNotifications,
                              child: const Icon(Icons.notifications_outlined),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Hero(
                        tag: 'wallet-card',
                        child: Material(
                          color: Colors.transparent,
                          child: _BalanceCard(
                            balance: controller.balance,
                            rfidStatus: profile?.rfidStatus ?? '-',
                            rfidUid: profile?.rfidUid ?? '-',
                            plateNumber: profile?.plateNumber ?? '-',
                          ),
                        ),
                      ),
                      if (controller.errorMessage != null) ...[
                        const SizedBox(height: 14),
                        _ErrorBanner(
                          message: controller.errorMessage!,
                          onRetry: controller.refresh,
                        ),
                      ],
                      const SizedBox(height: 26),
                      const SectionHeader(title: 'Quick actions'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.add_card_rounded,
                              label: 'Top Up',
                              onTap: () => widget.onSelectTab(1),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.local_parking_rounded,
                              label: 'Parking',
                              onTap: () => widget.onSelectTab(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.swap_horiz_rounded,
                              label: 'Transactions',
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const TransactionsScreen(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.person_rounded,
                              label: 'Profile',
                              onTap: () => widget.onSelectTab(3),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      const SectionHeader(title: 'This month'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StatisticCard(
                              icon: Icons.local_parking_rounded,
                              color: AppColors.primary,
                              value: '${monthlyParking.length}',
                              label: 'Parking visits',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatisticCard(
                              icon: Icons.account_balance_wallet_outlined,
                              color: AppColors.warning,
                              value: formatCurrency(monthlyCost),
                              label: 'Parking cost',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      const SectionHeader(title: 'Last parking activity'),
                      const SizedBox(height: 12),
                      if (controller.parkingHistory.isEmpty)
                        const AppCard(
                          child: EmptyState(
                            icon: Icons.directions_car_outlined,
                            title: 'No parking activity',
                            message:
                                'Your latest campus parking visit will appear here.',
                          ),
                        )
                      else
                        _RecentParking(
                          activity: controller.parkingHistory.first,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
    required this.rfidStatus,
    required this.rfidUid,
    required this.plateNumber,
  });

  final double balance;
  final String rfidStatus;
  final String rfidUid;
  final String plateNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D4ED8), Color(0xFF60A5FA)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'RFID BALANCE',
                  style: TextStyle(
                    color: Color(0xFFDBEAFE),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.3,
                  ),
                ),
              ),
              StatusBadge(status: rfidStatus),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            formatCurrency(balance),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(
                child: _WalletDetail(label: 'CARD ID', value: rfidUid),
              ),
              Expanded(
                child: _WalletDetail(
                  label: 'PLATE NUMBER',
                  value: plateNumber,
                  alignEnd: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WalletDetail extends StatelessWidget {
  const _WalletDetail({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFDBEAFE),
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 16),
          FittedBox(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentParking extends StatelessWidget {
  const _RecentParking({required this.activity});

  final dynamic activity;

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
            child: const Icon(
              Icons.directions_car_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatDate(activity.entryTime),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatTime(activity.entryTime)} - ${formatTime(activity.exitTime)}',
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
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
