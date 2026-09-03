import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';

// ─── Controller ───────────────────────────────────────────────
class AdminNotificationsController extends GetxController {
  final titleController = TextEditingController();
  final bodyController = TextEditingController();
  final isSending = false.obs;
  final sendToAll = true.obs;
  final targetUserId = RxnString();
  final users = <UserModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      users.value = await SupabaseService.to.getUsers(status: 'active');
    } catch (error) {
      Get.snackbar('Error', 'Could not load recipients: $error');
    }
  }

  Future<void> sendNotification() async {
    if (titleController.text.isEmpty || bodyController.text.isEmpty) {
      Get.snackbar('Error', 'Title and message are required',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12);
      return;
    }
    isSending.value = true;
    try {
      if (!sendToAll.value && targetUserId.value == null) {
        throw StateError('Select a recipient');
      }
      await SupabaseService.to.sendNotification(
        title: titleController.text.trim(),
        body: bodyController.text.trim(),
        type: 'general',
        userId: sendToAll.value ? null : targetUserId.value,
      );
      titleController.clear();
      bodyController.clear();
      Get.snackbar('Sent!', 'Notification sent successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12);
    } catch (error) {
      Get.snackbar('Error', 'Failed to send notification: $error',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12);
    } finally {
      isSending.value = false;
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    bodyController.dispose();
    super.onClose();
  }
}

// ─── Binding ──────────────────────────────────────────────────
class AdminNotificationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminNotificationsController>(
        () => AdminNotificationsController());
  }
}

// ─── View ─────────────────────────────────────────────────────
class AdminNotificationsView extends GetView<AdminNotificationsController> {
  const AdminNotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const DarkTopBar(title: 'Send Notification', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Compose Notification',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          const Text('Send a notification to all or specific users.',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 24),

          // Recipient
          const Text('Recipient',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Obx(() => Row(children: [
                _chip('All Users', true, controller.sendToAll.value,
                    () => controller.sendToAll.value = true),
                const SizedBox(width: 8),
                _chip('Specific User', false, !controller.sendToAll.value,
                    () => controller.sendToAll.value = false),
              ])),
          Obx(() => controller.sendToAll.value
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: DropdownButtonFormField<String>(
                    initialValue: controller.targetUserId.value,
                    decoration: const InputDecoration(
                      labelText: 'Select user',
                    ),
                    items: controller.users
                        .map((user) => DropdownMenuItem(
                              value: user.id,
                              child: Text(user.name),
                            ))
                        .toList(),
                    onChanged: (value) => controller.targetUserId.value = value,
                  ),
                )),
          const SizedBox(height: 20),

          // Title
          const Text('Title',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          TextField(
            controller: controller.titleController,
            style: const TextStyle(fontFamily: 'Nunito', fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'e.g. Monthly Reminder',
              hintStyle: TextStyle(fontFamily: 'Nunito'),
            ),
          ),
          const SizedBox(height: 16),

          // Message
          const Text('Message',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          TextField(
            controller: controller.bodyController,
            maxLines: 4,
            style: const TextStyle(fontFamily: 'Nunito', fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Write your message here...',
              hintStyle: TextStyle(fontFamily: 'Nunito'),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 28),

          Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: controller.isSending.value
                      ? null
                      : controller.sendNotification,
                  icon: controller.isSending.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded),
                  label: Text(
                      controller.isSending.value
                          ? 'Sending...'
                          : 'Send Notification',
                      style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              )),
        ]),
      ),
    );
  }

  Widget _chip(String label, bool value, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface2,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }
}
