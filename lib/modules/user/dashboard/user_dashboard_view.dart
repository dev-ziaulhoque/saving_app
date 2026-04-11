import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saving_app/modules/user/dashboard/user_dashboard_controller.dart';
import '../../../app/routes/app_routes.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/models/models.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';

class UserDashboardView extends GetView<UserDashboardController> {
  const UserDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.to.currentUser.value;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(children: [
        _buildHeader(user?.name ?? 'User'),
        Expanded(
          child: Obx(() => controller.isLoading.value
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : RefreshIndicator(
                  onRefresh: controller.fetchDashboard,
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(children: [
                      _savingsCard(),
                      const SizedBox(height: 8),
                      SectionHeader(
                        title: 'Recent Transactions',
                        actionText: 'See All',
                        onAction: () => Get.toNamed(AppRoutes.USER_HISTORY),
                      ),
                      Obx(() => controller.recentTransactions.isEmpty
                          ? _emptyTxn()
                          : Column(
                              children: controller.recentTransactions
                                  .map(_txnItem)
                                  .toList())),
                      const SizedBox(height: 20),
                    ]),
                  ),
                )),
        ),
        _bottomNav(0),
      ]),
    );
  }

  Widget _buildHeader(String name) {
    return Container(
      color: AppColors.bgDark,
      padding: EdgeInsets.only(
        top: MediaQuery.of(Get.context!).padding.top + 12,
        left: 18, right: 18, bottom: 16,
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Good day 👋',
              style: TextStyle(fontFamily: 'Nunito', fontSize: 13,
                  color: Colors.white.withOpacity(0.5))),
          Text(name,
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 20,
                  fontWeight: FontWeight.w800, color: Colors.white)),
        ]),
        PopupMenuButton(
          child: UserAvatar(
              initials: AuthService.to.currentUser.value?.initials ?? 'U',
              color: AppColors.primary),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'profile', child: Text('My Profile')),
            const PopupMenuItem(value: 'logout', child: Text('Logout')),
          ],
          onSelected: (v) async {
            if (v == 'profile') Get.toNamed(AppRoutes.USER_PROFILE);
            if (v == 'logout') {
              await AuthService.to.logout();
              Get.offAllNamed(AppRoutes.LOGIN);
            }
          },
        ),
      ]),
    );
  }

  Widget _savingsCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Obx(() {
        final progress = controller.totalMonths.value > 0
            ? controller.monthsPaid.value / controller.totalMonths.value
            : 0.0;
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF6366F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Total Savings',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 13,
                    color: Colors.white70)),
            Text('৳${controller.totalSaved.value.toStringAsFixed(0)}',
                style: const TextStyle(fontFamily: 'Nunito', fontSize: 32,
                    fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.toDouble().clamp(0.0, 1.0),
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFA5F3FC)),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _mini('Monthly', '৳${controller.monthlyAmount.value.toStringAsFixed(0)}'),
              _mini('Months Paid', '${controller.monthsPaid.value}/${controller.totalMonths.value}'),
              _mini('Dues', '৳${controller.dues.value.toStringAsFixed(0)}',
                  valueColor: controller.dues.value > 0 ? const Color(0xFFFCA5A5) : Colors.white),
            ]),
          ]),
        );
      }),
    );
  }

  Widget _mini(String label, String value, {Color? valueColor}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(fontFamily: 'Nunito', fontSize: 11,
              color: Colors.white60)),
      Text(value,
          style: TextStyle(fontFamily: 'Nunito', fontSize: 14,
              fontWeight: FontWeight.w800,
              color: valueColor ?? Colors.white)),
    ]);
  }

  Widget _txnItem(TransactionModel t) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: t.isConfirmed ? AppColors.successLight : AppColors.warningLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            t.isConfirmed ? Icons.check_circle_outline : Icons.pending_outlined,
            color: t.isConfirmed ? AppColors.success : AppColors.warning,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.month,
                style: const TextStyle(fontFamily: 'Nunito', fontSize: 14,
                    fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            Text('${t.submittedAt.day}/${t.submittedAt.month}/${t.submittedAt.year} • ${t.status}',
                style: const TextStyle(fontFamily: 'Nunito', fontSize: 12,
                    color: AppColors.textSecondary)),
          ]),
        ),
        Text('+৳${t.amount.toStringAsFixed(0)}',
            style: const TextStyle(fontFamily: 'Nunito', fontSize: 15,
                fontWeight: FontWeight.w800, color: AppColors.success)),
      ]),
    );
  }

  Widget _emptyTxn() {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: EmptyState(
        icon: '📋',
        title: 'No transactions yet',
        subtitle: 'Your deposit history will appear here.',
      ),
    );
  }

  Widget _bottomNav(int current) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderColor)),
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(children: [
        _navItem(Icons.home_outlined, 'Home', 0, current, () {}),
        _navItem(Icons.notifications_outlined, 'Alerts', 1, current,
            () => Get.toNamed(AppRoutes.USER_NOTIFICATIONS)),
        _navItem(Icons.chat_bubble_outline, 'Chat', 2, current,
            () => Get.toNamed(AppRoutes.USER_CHAT)),
        _navItem(Icons.person_outline, 'Profile', 3, current,
            () => Get.toNamed(AppRoutes.USER_PROFILE)),
      ]),
    );
  }

  Widget _navItem(IconData icon, String label, int index, int current, VoidCallback onTap) {
    final active = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(children: [
          Icon(icon,
              color: active ? AppColors.primary : AppColors.textSecondary,
              size: 24),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(fontFamily: 'Nunito', fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: active ? AppColors.primary : AppColors.textSecondary)),
        ]),
      ),
    );
  }
}
