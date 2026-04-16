import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/models/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';

// ─── Controller ───────────────────────────────────────────────
class UserNotificationsController extends GetxController {
  final _api = ApiProvider();
  final isLoading = false.obs;
  final notifications = <NotificationModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    isLoading.value = true;
    try {
      final res = await _api.getUserNotifications();
      notifications.value = (res.data['notifications'] as List)
          .map((n) => NotificationModel.fromJson(n))
          .toList();
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _api.markNotificationRead(id);
      final idx = notifications.indexWhere((n) => n.id == id);
      if (idx != -1) {
        final old = notifications[idx];
        notifications[idx] = NotificationModel(
          id: old.id, title: old.title, body: old.body,
          type: old.type, isRead: true, createdAt: old.createdAt,
        );
        notifications.refresh();
      }
    } catch (_) {}
  }
}

// ─── Binding ──────────────────────────────────────────────────
class UserNotificationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserNotificationsController>(() => UserNotificationsController());
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
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
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
            color: n.isRead ? AppColors.borderColor : AppColors.primaryLight.withOpacity(0.4),
          ),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: _iconBg(n.type),
              borderRadius: BorderRadius.circular(21),
            ),
            child: Icon(_iconData(n.type), color: _iconColor(n.type), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(
                  child: Text(n.title,
                      style: TextStyle(
                          fontFamily: 'Nunito', fontSize: 13,
                          fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w800,
                          color: AppColors.textPrimary)),
                ),
                if (!n.isRead)
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                        color: AppColors.primary, shape: BoxShape.circle),
                  ),
              ]),
              const SizedBox(height: 3),
              Text(n.body,
                  style: const TextStyle(fontFamily: 'Nunito', fontSize: 12,
                      color: AppColors.textSecondary, height: 1.5)),
              const SizedBox(height: 5),
              Text(_timeAgo(n.createdAt),
                  style: const TextStyle(fontFamily: 'Nunito', fontSize: 11,
                      color: AppColors.textHint)),
            ]),
          ),
        ]),
      ),
    );
  }

  Color _iconBg(String type) {
    switch (type) {
      case 'approval': return AppColors.successLight;
      case 'payment': return AppColors.successLight;
      case 'message': return const Color(0xFFEDE9FE);
      default: return const Color(0xFFDBEAFE);
    }
  }

  Color _iconColor(String type) {
    switch (type) {
      case 'approval': return AppColors.success;
      case 'payment': return AppColors.success;
      case 'message': return AppColors.primary;
      default: return const Color(0xFF1D4ED8);
    }
  }

  IconData _iconData(String type) {
    switch (type) {
      case 'approval': return Icons.verified_outlined;
      case 'payment': return Icons.payments_outlined;
      case 'message': return Icons.message_outlined;
      default: return Icons.notifications_outlined;
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
