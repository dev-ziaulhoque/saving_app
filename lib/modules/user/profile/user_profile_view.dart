import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/custom_text.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/models/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart'; // এখানে CustomText আছে ধরে নিচ্ছি
import 'controller/user_profile_controller.dart';

class UserProfileView extends GetView<UserProfileController> {
  const UserProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Obx(() {
        final user = AuthService.to.currentUser.value;
        if (user == null) return const SizedBox();
        return Column(children: [
          _buildHeader(user),
          Expanded(
            child: SingleChildScrollView(
              child: Column(children: [
                const SizedBox(height: 16),
                _infoSection(user),
                const SizedBox(height: 12),
                _savingsSection(user),
                const SizedBox(height: 12),
                _actionsSection(),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ]);
      }),
    );
  }

  Widget _buildHeader(UserModel user) {
    return Container(
      color: AppColors.bgDark,
      padding: EdgeInsets.only(
        top: MediaQuery.of(Get.context!).padding.top + 12,
        left: 18, right: 18, bottom: 24,
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
            onPressed: () => Get.back(),
          ),
          const CustomText.title('My Profile', color: Colors.white),
          Obx(() => TextButton(
            onPressed: controller.isEditing.value
                ? (controller.isSaving.value ? null : controller.saveProfile)
                : controller.toggleEdit,
            child: controller.isSaving.value
                ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : CustomText.subtitle(
                controller.isEditing.value ? 'Save' : 'Edit',
                color: AppColors.primaryLight),
          )),
        ]),
        const SizedBox(height: 16),

        // --- Avatar Section with Image Pick ---
        GestureDetector(
          onTap: controller.pickImage,
          child: Stack(alignment: Alignment.bottomRight, children: [
            Obx(() {
              // যদি নতুন ইমেজ সিলেক্ট করা হয় তবে সেটা দেখাবে, নাহলে পুরানোটা
              if (controller.selectedImage.value != null) {
                return CircleAvatar(
                  radius: 36,
                  backgroundImage: FileImage(controller.selectedImage.value!),
                );
              }
              return UserAvatar(
                  initials: user.initials,
                  imageUrl: user.avatarUrl, // আপনার মডেলে avatarUrl থাকলে
                  color: AppColors.primary,
                  size: 72
              );
            }),
            if (controller.isEditing.value)
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.bgDark, width: 2),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
              ),
          ]),
        ),

        const SizedBox(height: 10),
        CustomText.heading(user.name, color: Colors.white),
        const SizedBox(height: 4),
        CustomText.label('Member ID: #${user.id.substring(0, 6).toUpperCase()}',
            color: Colors.white.withOpacity(0.5)),
        const SizedBox(height: 8),
        StatusBadge(status: user.status),
      ]),
    );
  }

  Widget _infoSection(UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Obx(() => Column(children: [
          _editableRow(
            label: 'Full Name',
            controller: controller.nameController,
            isEditing: controller.isEditing.value,
            icon: Icons.person_outline,
          ),
          const Divider(height: 1, color: AppColors.borderColor),
          _editableRow(
            label: 'Phone',
            controller: controller.phoneController,
            isEditing: controller.isEditing.value,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const Divider(height: 1, color: AppColors.borderColor),
          _staticRow('Email', user.email, Icons.email_outlined),
          const Divider(height: 1, color: AppColors.borderColor),
          _staticRow('Joined',
              '${user.joinedAt.day}/${user.joinedAt.month}/${user.joinedAt.year}',
              Icons.calendar_today_outlined),
        ])),
      ),
    );
  }

  Widget _savingsSection(UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF6366F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          Expanded(child: _savingsStat('Total Saved', '৳${user.totalSaved.toStringAsFixed(0)}')),
          _vDivider(),
          Expanded(child: _savingsStat('Monthly', '৳${user.monthlyAmount.toStringAsFixed(0)}')),
          _vDivider(),
          Expanded(child: _savingsStat('Dues', '৳${user.dues.toStringAsFixed(0)}', isAlert: user.dues > 0)),
        ]),
      ),
    );
  }

  Widget _savingsStat(String label, String value, {bool isAlert = false}) {
    return Column(children: [
      CustomText.label(label, color: Colors.white70),
      const SizedBox(height: 4),
      CustomText.subtitle(value, color: isAlert ? const Color(0xFFFCA5A5) : Colors.white),
    ]);
  }

  Widget _vDivider() => Container(width: 1, height: 36, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 8));

  Widget _actionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        _actionTile(Icons.notifications_outlined, 'Notification Settings', () {}),
        const SizedBox(height: 8),
        _actionTile(Icons.lock_outline, 'Change Password', () {}),
        const SizedBox(height: 8),
        _actionTile(Icons.logout, 'Logout', () async {
          await AuthService.to.logout();
          Get.offAllNamed(AppRoutes.LOGIN);
        }, isDestructive: true),
      ]),
    );
  }

  Widget _actionTile(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(children: [
          Icon(icon, color: isDestructive ? AppColors.error : AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: CustomText.subtitle(label, color: isDestructive ? AppColors.error : AppColors.textPrimary)),
          Icon(Icons.chevron_right, color: isDestructive ? AppColors.error : AppColors.textHint, size: 20),
        ]),
      ),
    );
  }

  Widget _editableRow({required String label, required TextEditingController controller, required bool isEditing, required IconData icon, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Icon(icon, color: AppColors.textSecondary, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CustomText.label(label, color: AppColors.textSecondary),
            isEditing
                ? TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 4), border: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary))),
            )
                : CustomText.subtitle(controller.text, color: AppColors.textPrimary),
          ]),
        ),
      ]),
    );
  }

  Widget _staticRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Icon(icon, color: AppColors.textSecondary, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CustomText.label(label, color: AppColors.textSecondary),
            CustomText.subtitle(value, color: AppColors.textPrimary),
          ]),
        ),
      ]),
    );
  }
}