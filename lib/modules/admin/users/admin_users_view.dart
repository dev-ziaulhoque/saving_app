import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/models.dart';
import 'admin_users_controller.dart';

class AdminUsersView extends GetView<AdminUsersController> {
  const AdminUsersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const DarkTopBar(title: 'All Users', showBack: true),
      body: Column(children: [
        _buildFilters(),
        Expanded(
          child: Obx(() => controller.isLoading.value
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : RefreshIndicator(
                  onRefresh: controller.fetchUsers,
                  color: AppColors.primary,
                  child: controller.users.isEmpty
                      ? const EmptyState(
                          icon: '👥',
                          title: 'No users found',
                          subtitle: 'No users match the selected filter.')
                      : ListView.builder(
                          itemCount: controller.users.length,
                          itemBuilder: (_, i) => _userItem(controller.users[i]),
                        ),
                )),
        ),
      ]),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Obx(() => Row(
        children: controller.filters.map((f) {
          final active = controller.selectedFilter.value == f;
          return GestureDetector(
            onTap: () => controller.setFilter(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.surface2,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                f[0].toUpperCase() + f.substring(1),
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : AppColors.textSecondary),
              ),
            ),
          );
        }).toList(),
      )),
    );
  }

  Widget _userItem(UserModel user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: UserAvatar(initials: user.initials, color: _avatarColor(user.id), size: 44),
        title: Text(user.name,
            style: const TextStyle(
                fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        subtitle: Text(user.phone,
            style: const TextStyle(
                fontFamily: 'Nunito', fontSize: 12, color: AppColors.textSecondary)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          StatusBadge(status: user.status),
          const SizedBox(width: 6),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'detail', child: Text('View Detail')),
              if (user.isPending)
                const PopupMenuItem(value: 'approve', child: Text('Approve')),
              if (user.isActive)
                const PopupMenuItem(value: 'block', child: Text('Block User')),
              if (user.isBlocked)
                const PopupMenuItem(value: 'unblock', child: Text('Unblock User')),
            ],
            onSelected: (v) {
              switch (v) {
                case 'detail':
                  Get.toNamed(AppRoutes.ADMIN_USER_DETAIL, arguments: user);
                  break;
                case 'approve':
                  controller.approveUser(user.id);
                  break;
                case 'block':
                  controller.blockUser(user.id);
                  break;
                case 'unblock':
                  controller.unblockUser(user.id);
                  break;
              }
            },
          ),
        ]),
      ),
    );
  }

  Color _avatarColor(String id) {
    final colors = [
      AppColors.cardBlue, AppColors.cardGreen,
      AppColors.cardPurple, AppColors.cardAmber,
    ];
    return colors[id.hashCode % colors.length];
  }
}

class AdminUsersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminUsersController>(() => AdminUsersController());
  }
}
