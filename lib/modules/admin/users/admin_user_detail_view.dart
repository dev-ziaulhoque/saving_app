import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
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
          const Text('User Detail',
              style: TextStyle(fontFamily: 'Nunito', fontSize: 18,
                  fontWeight: FontWeight.w700, color: Colors.white)),
        ]),
        const SizedBox(height: 20),
        UserAvatar(initials: user.initials, color: AppColors.primary, size: 64),
        const SizedBox(height: 10),
        Text(user.name,
            style: const TextStyle(fontFamily: 'Nunito', fontSize: 20,
                fontWeight: FontWeight.w800, color: Colors.white)),
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
            label: const Text('Approve User'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: AppColors.success,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () { ctrl.rejectUser(user.id); Get.back(); },
            icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
            label: const Text('Reject User', style: TextStyle(color: AppColors.error)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              side: const BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
        if (user.isActive)
          OutlinedButton.icon(
            onPressed: () { ctrl.blockUser(user.id); Get.back(); },
            icon: const Icon(Icons.block, color: AppColors.error),
            label: const Text('Block User', style: TextStyle(color: AppColors.error)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              side: const BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        if (user.isBlocked)
          ElevatedButton.icon(
            onPressed: () { ctrl.unblockUser(user.id); Get.back(); },
            icon: const Icon(Icons.lock_open),
            label: const Text('Unblock User'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: AppColors.success,
            ),
          ),
      ]),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: const TextStyle(fontFamily: 'Nunito', fontSize: 13,
                color: AppColors.textSecondary)),
        Text(value,
            style: TextStyle(fontFamily: 'Nunito', fontSize: 14,
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppColors.textPrimary)),
      ]),
    );
  }

  Widget _divider() => const Divider(height: 1, color: AppColors.borderColor);
}
