import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/custom_text.dart';
import '../../../data/models/models.dart';
import 'admin_users_controller.dart';

class AdminUserDetailView extends StatelessWidget {
  const AdminUserDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Get.arguments as UserModel;
    final ctrl = Get.find<AdminUsersController>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(children: [
        _buildHeader(user),
        Expanded(
          child: SingleChildScrollView(
            child: Column(children: [
              const SizedBox(height: 16),
              _infoCard(user),
              const SizedBox(height: 12),
              _savingsCard(user),
              const SizedBox(height: 12),
              _actionButtons(user, ctrl),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildHeader(UserModel user) {
    return Container(
      color: AppColors.bgDark,
      padding: EdgeInsets.only(
        top: MediaQuery.of(Get.context!).padding.top + 8,
        left: 18, right: 18, bottom: 20,
      ),
      child: Column(children: [
        Row(children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          const CustomText.title('User Detail', color: Colors.white),
        ]),
        const SizedBox(height: 20),
        UserAvatar(initials: user.initials, color: AppColors.primary, size: 64),
        const SizedBox(height: 10),
        CustomText.heading(user.name, color: Colors.white),
        const SizedBox(height: 4),
        StatusBadge(status: user.status),
      ]),
    );
  }

  Widget _infoCard(UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderColor)),
        child: Column(children: [
          _row('Phone', user.phone),
          _divider(),
          _row('Email', user.email),
          _divider(),
          _row('Member ID', '#${user.id.substring(0, 6).toUpperCase()}'),
          _divider(),
          _row('Joined', '${user.joinedAt.day}/${user.joinedAt.month}/${user.joinedAt.year}'),
        ]),
      ),
    );
  }

  Widget _savingsCard(UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderColor)),
        child: Column(children: [
          _row('Monthly Amount', '৳${user.monthlyAmount.toStringAsFixed(0)}'),
          _divider(),
          _row('Total Saved', '৳${user.totalSaved.toStringAsFixed(0)}'),
          _divider(),
          _row('Dues', '৳${user.dues.toStringAsFixed(0)}',
              valueColor: user.dues > 0 ? AppColors.error : AppColors.success),
        ]),
      ),
    );
  }

  Widget _actionButtons(UserModel user, AdminUsersController ctrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        if (user.isPending) ...[
          ElevatedButton.icon(
            onPressed: () { ctrl.approveUser(user.id); Get.back(); },
            icon: const Icon(Icons.check_circle_outline),
            label: const CustomText.subtitle('Approve User', color: Colors.white),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () { ctrl.rejectUser(user.id); Get.back(); },
            icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
            label: const CustomText.subtitle('Reject User', color: AppColors.error),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              side: const BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
        // ... অন্যান্য বাটন গুলোতেও একই ভাবে CustomText যোগ করুন
      ]),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        CustomText.small(label, color: AppColors.textSecondary),
        CustomText.subtitle(value, color: valueColor ?? AppColors.textPrimary),
      ]),
    );
  }

  Widget _divider() => const Divider(height: 1, color: AppColors.borderColor);
}