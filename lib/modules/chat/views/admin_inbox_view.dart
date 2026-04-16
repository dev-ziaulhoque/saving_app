import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/custom_text.dart';
import '../controllers/admin_inbox_controller.dart';

class AdminInboxView extends GetView<AdminInboxController> {
  const AdminInboxView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const DarkTopBar(title: 'Support Messages', showBack: true),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (controller.chatList.isEmpty) {
          return const Center(
            child: CustomText.body('No messages yet', color: AppColors.textSecondary),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchInbox,
          child: ListView.builder(
            itemCount: controller.chatList.length,
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemBuilder: (_, i) {
              final chat = controller.chatList[i];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: ListTile(
                  onTap: () => controller.goToChat(chat),
                  leading: UserAvatar(
                    initials: chat['user_name'][0],
                    color: AppColors.cardBlue,
                    size: 44,
                  ),
                  title: CustomText.subtitle(chat['user_name']),
                  subtitle: CustomText.small(
                    chat['last_msg'] ?? 'New conversation',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (chat['unread_count'] > 0)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                          child: CustomText.label(chat['unread_count'].toString(), color: Colors.white),
                        ),
                      const Icon(Icons.chevron_right, size: 20, color: AppColors.textHint),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}