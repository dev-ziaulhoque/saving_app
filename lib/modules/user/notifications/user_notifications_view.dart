import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/supabase_service.dart';
import '../../../data/services/badge_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';

// ─── Controller ───────────────────────────────────────────────
class UserNotificationsController extends GetxController {
  final isLoading = false.obs;
  final notifications = <NotificationModel>[].obs;
  RealtimeChannel? _realtimeChannel;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
    final uid = AuthService.to.currentUser.value?.id;
    if (uid != null) {
      _realtimeChannel = SupabaseService.to.subscribeToNotifications(
        userId: uid,
        onChanged: fetchNotifications,
      );
    }
  }

  Future<void> fetchNotifications() async {
    isLoading.value = true;
    try {
      final uid = AuthService.to.currentUser.value?.id;
      if (uid == null) throw StateError('No authenticated user');
      notifications.value = await SupabaseService.to.getUserNotifications(uid);
      await BadgeService.to.refresh();
    } catch (error) {
      Get.snackbar('Error', 'Could not load notifications: $error');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markRead(String id) async {
    try {
      await SupabaseService.to.markNotificationRead(id);
      final idx = notifications.indexWhere((n) => n.id == id);
      if (idx != -1) {
        final old = notifications[idx];
        notifications[idx] = NotificationModel(
          id: old.id,
          title: old.title,
          body: old.body,
          type: old.type,
          userId: old.userId,
          isRead: true,
          isCompleted: old.isCompleted,
          createdAt: old.createdAt,
        );
        notifications.refresh();
        await BadgeService.to.refresh();
      }
    } catch (error) {
      Get.snackbar('Error', 'Could not update notification: $error');
    }
  }

  Future<void> markCompleted(NotificationModel notification) async {
    if (notification.isCompleted) return;
    try {
      await SupabaseService.to.completeNotification(notification.id);
      await fetchNotifications();
      Get.snackbar('Completed', 'Notification marked as completed',
          backgroundColor: AppColors.success, colorText: Colors.white);
    } catch (error) {
      Get.snackbar('Error', 'Could not complete notification: $error');
    }
  }

  @override
  void onClose() {
    final channel = _realtimeChannel;
    if (channel != null) Supabase.instance.client.removeChannel(channel);
    super.onClose();
  }
}

// ─── Binding ──────────────────────────────────────────────────
class UserNotificationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserNotificationsController>(
        () => UserNotificationsController());
  }
}

// ─── View ─────────────────────────────────────────────────────
class UserNotificationsView extends GetView<UserNotificationsController> {
  const UserNotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const DarkTopBar(title: 'Notifications', showBack: true),
      body: Obx(() => controller.isLoading.value
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: controller.fetchNotifications,
              color: AppColors.primary,
              child: controller.notifications.isEmpty
                  ? const EmptyState(
                      icon: '🔔',
                      title: 'No notifications',
                      subtitle: 'You have no notifications yet.')
                  : ListView.builder(
                      itemCount: controller.notifications.length,
                      itemBuilder: (_, i) {
                        final n = controller.notifications[i];
                        return _notifItem(n);
                      },
                    ),
            )),
    );
  }

  Widget _notifItem(NotificationModel n) {
    return GestureDetector(
      onTap: () => controller.markRead(n.id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: n.isRead ? Colors.white : const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: n.isRead
                ? AppColors.borderColor
                : AppColors.primaryLight.withValues(alpha: 0.4),
          ),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _iconBg(n.type),
              borderRadius: BorderRadius.circular(21),
            ),
            child: Icon(_iconData(n.type), color: _iconColor(n.type), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(
                  child: Text(n.title,
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          fontWeight:
                              n.isRead ? FontWeight.w600 : FontWeight.w800,
                          color: AppColors.textPrimary)),
                ),
                if (!n.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: AppColors.primary, shape: BoxShape.circle),
                  ),
              ]),
              const SizedBox(height: 3),
              Text(n.body,
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5)),
              const SizedBox(height: 5),
              Text(_timeAgo(n.createdAt),
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      color: AppColors.textHint)),
              const SizedBox(height: 9),
              Align(
                alignment: Alignment.centerRight,
                child: n.isCompleted
                    ? const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.task_alt,
                            size: 17, color: AppColors.success),
                        SizedBox(width: 5),
                        Text('Completed',
                            style: TextStyle(
                                color: AppColors.success,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ])
                    : OutlinedButton.icon(
                        onPressed: () => controller.markCompleted(n),
                        icon: const Icon(Icons.check_circle_outline, size: 17),
                        label: const Text('Mark completed'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.success,
                          side: const BorderSide(color: AppColors.success),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Color _iconBg(String type) {
    switch (type) {
      case 'approval':
        return AppColors.successLight;
      case 'payment':
        return AppColors.successLight;
      case 'message':
        return const Color(0xFFEDE9FE);
      default:
        return const Color(0xFFDBEAFE);
    }
  }

  Color _iconColor(String type) {
    switch (type) {
      case 'approval':
        return AppColors.success;
      case 'payment':
        return AppColors.success;
      case 'message':
        return AppColors.primary;
      default:
        return const Color(0xFF1D4ED8);
    }
  }

  IconData _iconData(String type) {
    switch (type) {
      case 'approval':
        return Icons.verified_outlined;
      case 'payment':
        return Icons.payments_outlined;
      case 'message':
        return Icons.message_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
