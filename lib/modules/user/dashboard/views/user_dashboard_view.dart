import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saving_app/modules/user/history/views/user_payment_request_view.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/custom_text.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/count_badge.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../data/services/badge_service.dart';
import '../controllers/user_dashboard_controller.dart';

class UserDashboardView extends GetView<UserDashboardController> {
  const UserDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.to.currentUser.value;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _buildHeader(user?.name ?? 'User'),
          Expanded(
            child: Obx(() => controller.isLoading.value
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : RefreshIndicator(
                    onRefresh: controller.fetchDashboard,
                    color: AppColors.primary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          _buildSavingsCard(),
                          _buildMonthlyCalendar(),
                          const SizedBox(height: 20),

                          // পেমেন্ট সাবমিট করার মূল বাটন
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: CustomButton(
                              text: 'Submit New Payment',
                              icon: Icons.add_circle_outline,
                              onPressed: () =>
                                  Get.to(() => const PaymentRequestView()),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // রিসেন্ট ট্রানজেকশন সেকশন
                          SectionHeader(
                            title: 'Recent Transactions',
                            actionText: 'See All',
                            onAction: () => Get.toNamed(AppRoutes.USER_HISTORY),
                          ),

                          Obx(() => controller.recentTransactions.isEmpty
                              ? _buildEmptyState()
                              : Column(
                                  children: controller.recentTransactions
                                      .map((t) => _buildTransactionItem(t))
                                      .toList(),
                                )),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  )),
          ),
          _buildBottomNav(0),
        ],
      ),
    );
  }

  // --- ১. হেডার সেকশন ---
  Widget _buildHeader(String name) {
    return Container(
      color: AppColors.bgDark,
      padding: EdgeInsets.only(
        top: MediaQuery.of(Get.context!).padding.top + 12,
        left: 18,
        right: 18,
        bottom: 20,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText.small('Good day 👋',
                  color: Colors.white.withValues(alpha: 0.5)),
              CustomText.heading(name, color: Colors.white),
            ],
          ),
          PopupMenuButton<String>(
            child: UserAvatar(
              initials: AuthService.to.currentUser.value?.initials ?? 'U',
              color: AppColors.primary,
              size: 44,
            ),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'report', child: CustomText.body('Foundation Report')),
              const PopupMenuItem(
                  value: 'profile', child: CustomText.body('My Profile')),
              const PopupMenuItem(
                  value: 'logout',
                  child: CustomText.body('Logout', color: AppColors.error)),
            ],
            onSelected: (v) async {
              if (v == 'report') Get.toNamed(AppRoutes.USER_FOUNDATION_REPORT);
              if (v == 'profile') Get.toNamed(AppRoutes.USER_PROFILE);
              if (v == 'logout') {
                await AuthService.to.logout();
                Get.offAllNamed(AppRoutes.LOGIN);
              }
            },
          ),
        ],
      ),
    );
  }

  // --- ২. সেভিংস কার্ড (Gradient Card) ---
  Widget _buildSavingsCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Obx(() {
        // প্রগ্রেস ক্যালকুলেশন
        final progress = controller.totalMonths.value > 0
            ? controller.monthsPaid.value / controller.totalMonths.value
            : 0.0;

        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF6366F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomText.label('TOTAL SAVED BALANCE',
                  color: Colors.white70),
              const SizedBox(height: 4),
              CustomText.heading(
                '৳${controller.totalSaved.value.toStringAsFixed(0)}',
                color: Colors.white,
              ),
              const SizedBox(height: 18),

              // প্রগ্রেস বার
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.white24,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFFA5F3FC)),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 20),

              // নিচের ৩টি স্ট্যাটাস
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statItem('Remaining Due',
                      '৳${controller.dues.value.toStringAsFixed(0)}',
                      isAlert: controller.dues.value > 0),
                  _statItem('Monthly Fix',
                      '৳${controller.monthlyAmount.value.toStringAsFixed(0)}'),
                  _statItem('Months Paid',
                      '${controller.monthsPaid.value}/${controller.totalMonths.value}'),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _statItem(String label, String value, {bool isAlert = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText.label(label, color: Colors.white60),
        const SizedBox(height: 2),
        CustomText.subtitle(
          value,
          color: isAlert ? const Color(0xFFFCA5A5) : Colors.white,
        ),
      ],
    );
  }

  Widget _buildMonthlyCalendar() => Obx(() {
        final months = controller.paymentCalendar;
        if (months.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const CustomText.subtitle('Monthly payment timeline'),
            const SizedBox(height: 3),
            const CustomText.small(
                'Paid, pending, due and advance months at a glance.',
                color: AppColors.textSecondary),
            const SizedBox(height: 10),
            SizedBox(
              height: 92,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                reverse: true,
                itemCount: months.length,
                itemBuilder: (_, index) {
                  final item = months[months.length - 1 - index];
                  final date = DateTime.parse(item['month'].toString());
                  final status = item['status']?.toString() ?? 'due';
                  final color = switch (status) {
                    'paid' => AppColors.success,
                    'pending' => AppColors.warning,
                    'partial' => AppColors.primary,
                    'future' => AppColors.cardBlue,
                    _ => AppColors.error,
                  };
                  return Container(
                    width: 106,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: color.withValues(alpha: .35)),
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${date.month.toString().padLeft(2, '0')}/${date.year}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800)),
                          const Spacer(),
                          Text(
                              '৳${(item['confirmed'] as num? ?? 0).toStringAsFixed(0)}',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, color: color)),
                          Text(status.toUpperCase(),
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: color)),
                        ]),
                  );
                },
              ),
            ),
          ]),
        );
      });

  // --- ৩. ট্রানজেকশন আইটেম ডিজাইন ---
  Widget _buildTransactionItem(TransactionModel t) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: t.isConfirmed
                  ? AppColors.successLight
                  : AppColors.warningLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              t.isConfirmed
                  ? Icons.check_circle_outline
                  : Icons.pending_outlined,
              color: t.isConfirmed ? AppColors.success : AppColors.warning,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText.subtitle(t.month, color: AppColors.textPrimary),
                CustomText.small(
                  '${t.submittedAt.day}/${t.submittedAt.month}/${t.submittedAt.year} • ${t.status.toUpperCase()}',
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          CustomText.subtitle(
            '+৳${t.amount.toStringAsFixed(0)}',
            color: t.isConfirmed ? AppColors.success : AppColors.textPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: EmptyState(
        icon: '📋',
        title: 'No transactions yet',
        subtitle: 'Submit your first hand-cash payment info.',
      ),
    );
  }

  // --- ৪. বটম নেভিগেশন ---
  Widget _buildBottomNav(int current) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderColor)),
      ),
      padding: const EdgeInsets.only(top: 10, bottom: 12),
      child: Row(
        children: [
          _navItem(Icons.dashboard_outlined, Icons.dashboard, 'Home', 0,
              current, () {}),
          _navItem(Icons.notifications_outlined, Icons.notifications, 'Alerts',
              1, current, () => Get.toNamed(AppRoutes.USER_NOTIFICATIONS)),
          _navItem(Icons.groups_outlined, Icons.groups, 'Community', 2, current,
              () => Get.toNamed(AppRoutes.USER_CHAT)),
          _navItem(Icons.person_outline, Icons.person, 'Profile', 3, current,
              () => Get.toNamed(AppRoutes.USER_PROFILE)),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, IconData activeIcon, String label, int index,
      int current, VoidCallback onTap) {
    final active = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label == 'Alerts' || label == 'Community')
              Obx(() => CountBadge(
                    count: label == 'Alerts'
                        ? BadgeService.to.unreadNotifications.value
                        : BadgeService.to.unreadChats.value,
                    child: Icon(
                      active ? activeIcon : icon,
                      color:
                          active ? AppColors.primary : AppColors.textSecondary,
                      size: 24,
                    ),
                  ))
            else
              Icon(
                active ? activeIcon : icon,
                color: active ? AppColors.primary : AppColors.textSecondary,
                size: 24,
              ),
            const SizedBox(height: 4),
            CustomText.label(
              label,
              color: active ? AppColors.primary : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
