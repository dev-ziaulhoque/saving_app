import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saving_app/modules/user/history/views/user_payment_request_view.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/custom_text.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../data/models/models.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../../data/services/auth_service.dart';
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
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : RefreshIndicator(
              onRefresh: controller.fetchDashboard,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildSavingsCard(),
                    const SizedBox(height: 20),

                    // পেমেন্ট সাবমিট করার মূল বাটন
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: CustomButton(
                        text: 'Submit New Payment',
                        icon: Icons.add_circle_outline,
                        onPressed: () => Get.to(()=> const PaymentRequestView()),
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
        left: 18, right: 18, bottom: 20,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText.small('Good day 👋', color: Colors.white.withOpacity(0.5)),
              CustomText.heading(name, color: Colors.white),
            ],
          ),
          PopupMenuButton<String>(
            child: UserAvatar(
              initials: AuthService.to.currentUser.value?.initials ?? 'U',
              color: AppColors.primary,
              size: 44,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'profile', child: CustomText.body('My Profile')),
              const PopupMenuItem(value: 'logout', child: CustomText.body('Logout', color: AppColors.error)),
            ],
            onSelected: (v) async {
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
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomText.label('TOTAL SAVED BALANCE', color: Colors.white70),
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
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFA5F3FC)),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 20),

              // নিচের ৩টি স্ট্যাটাস
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statItem('Remaining Due', '৳${controller.dues.value.toStringAsFixed(0)}',
                      isAlert: controller.dues.value > 0),
                  _statItem('Monthly Fix', '৳${controller.monthlyAmount.value.toStringAsFixed(0)}'),
                  _statItem('Months Paid', '${controller.monthsPaid.value}/${controller.totalMonths.value}'),
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
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: t.isConfirmed ? AppColors.successLight : AppColors.warningLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              t.isConfirmed ? Icons.check_circle_outline : Icons.pending_outlined,
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
          _navItem(Icons.dashboard_outlined, Icons.dashboard, 'Home', 0, current, () {}),
          _navItem(Icons.notifications_outlined, Icons.notifications, 'Alerts', 1, current,
                  () => Get.toNamed(AppRoutes.USER_NOTIFICATIONS)),
          _navItem(Icons.chat_bubble_outline, Icons.chat_bubble, 'Support', 2, current,
                  () => Get.toNamed(AppRoutes.USER_CHAT)),
          _navItem(Icons.person_outline, Icons.person, 'Profile', 3, current,
                  () => Get.toNamed(AppRoutes.USER_PROFILE)),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, IconData activeIcon, String label, int index, int current, VoidCallback onTap) {
    final active = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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