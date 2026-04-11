import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/models/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';

// ─── Controller ───────────────────────────────────────────────
class UserProfileController extends GetxController {
  final _api = ApiProvider();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final isEditing = false.obs;
  final isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    final user = AuthService.to.currentUser.value;
    nameController.text = user?.name ?? '';
    phoneController.text = user?.phone ?? '';
  }

  void toggleEdit() => isEditing.value = !isEditing.value;

  Future<void> saveProfile() async {
    if (nameController.text.trim().isEmpty) return;
    isSaving.value = true;
    try {
      final res = await _api.updateProfile({
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
      });
      final updated = UserModel.fromJson(res.data['user']);
      await AuthService.to.updateUser(updated);
      isEditing.value = false;
      Get.snackbar('Saved', 'Profile updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12);
    } catch (_) {
      Get.snackbar('Error', 'Failed to update profile',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12);
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    super.onClose();
  }
}

// ─── Binding ──────────────────────────────────────────────────
class UserProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserProfileController>(() => UserProfileController());
  }
}

// ─── Profile View ─────────────────────────────────────────────
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
      },),
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
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 18),
            onPressed: () => Get.back(),
          ),
          const Text('My Profile',
              style: TextStyle(fontFamily: 'Nunito', fontSize: 18,
                  fontWeight: FontWeight.w700, color: Colors.white)),
          Obx(() => TextButton(
            onPressed: controller.isEditing.value
                ? controller.saveProfile
                : controller.toggleEdit,
            child: Obx(() => controller.isSaving.value
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    controller.isEditing.value ? 'Save' : 'Edit',
                    style: const TextStyle(fontFamily: 'Nunito',
                        color: AppColors.primaryLight,
                        fontSize: 14, fontWeight: FontWeight.w700))),
          )),
        ]),
        const SizedBox(height: 16),
        Stack(alignment: Alignment.bottomRight, children: [
          UserAvatar(initials: user.initials, color: AppColors.primary, size: 72),
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: AppColors.bgDark, width: 2),
            ),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 12),
          ),
        ]),
        const SizedBox(height: 10),
        Text(user.name,
            style: const TextStyle(fontFamily: 'Nunito', fontSize: 20,
                fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 4),
        Text('Member ID: #${user.id.substring(0, 6).toUpperCase()}',
            style: TextStyle(fontFamily: 'Nunito', fontSize: 12,
                color: Colors.white.withOpacity(0.4))),
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
          Expanded(child: _savingsStat('Total Saved',
              '৳${user.totalSaved.toStringAsFixed(0)}')),
          _vDivider(),
          Expanded(child: _savingsStat('Monthly',
              '৳${user.monthlyAmount.toStringAsFixed(0)}')),
          _vDivider(),
          Expanded(child: _savingsStat('Dues',
              '৳${user.dues.toStringAsFixed(0)}',
              isAlert: user.dues > 0)),
        ]),
      ),
    );
  }

  Widget _savingsStat(String label, String value, {bool isAlert = false}) {
    return Column(children: [
      Text(label,
          style: const TextStyle(fontFamily: 'Nunito', fontSize: 11,
              color: Colors.white70)),
      const SizedBox(height: 4),
      Text(value,
          style: TextStyle(fontFamily: 'Nunito', fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isAlert ? const Color(0xFFFCA5A5) : Colors.white)),
    ]);
  }

  Widget _vDivider() {
    return Container(
      width: 1, height: 36,
      color: Colors.white24,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

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

  Widget _actionTile(IconData icon, String label, VoidCallback onTap,
      {bool isDestructive = false}) {
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
          Icon(icon,
              color: isDestructive ? AppColors.error : AppColors.textSecondary,
              size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: TextStyle(fontFamily: 'Nunito', fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDestructive ? AppColors.error : AppColors.textPrimary)),
          ),
          Icon(Icons.chevron_right,
              color: isDestructive ? AppColors.error : AppColors.textHint, size: 20),
        ]),
      ),
    );
  }

  Widget _editableRow({
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Icon(icon, color: AppColors.textSecondary, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(fontFamily: 'Nunito', fontSize: 11,
                    color: AppColors.textSecondary)),
            isEditing
                ? TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 14,
                        color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                      border: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primary)),
                      focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
                    ),
                  )
                : Text(controller.text,
                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 14,
                        color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
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
            Text(label,
                style: const TextStyle(fontFamily: 'Nunito', fontSize: 11,
                    color: AppColors.textSecondary)),
            Text(value,
                style: const TextStyle(fontFamily: 'Nunito', fontSize: 14,
                    color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }
}
