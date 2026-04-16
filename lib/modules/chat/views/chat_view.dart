import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/custom_text.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/chat_service.dart';
import '../controllers/chat_controller.dart';

class ChatView extends GetView<ChatController> {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    final myId = AuthService.to.currentUser.value?.id ?? '';
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Get.back(),
        ),
        title: Obx(() => Row(children: [
          UserAvatar(
              initials: controller.receiverName.value.isNotEmpty
                  ? controller.receiverName.value[0]
                  : '?',
              color: AppColors.primary,
              size: 36
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CustomText.subtitle(controller.receiverName.value, color: Colors.white),
            const CustomText.small('Online', color: Colors.greenAccent),
          ]),
        ])),
      ),
      body: Obx(() {
        // receiverId খালি থাকলে লোডিং দেখাবে
        if (controller.receiverId.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        return Column(children: [
          Expanded(
            child: StreamBuilder(
              stream: ChatService.to.getChatStream(controller.receiverId.value),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return const Center(child: CustomText.body('No messages yet. Say Hi!'));
                }

                return ListView.builder(
                  controller: controller.scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    final isMine = msg.senderId == myId;
                    return _buildBubble(msg, isMine);
                  },
                );
              },
            ),
          ),
          _buildInputBar(),
        ]);
      }),
    );
  }




  Widget _buildBubble(msg, bool isMine) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          border: isMine ? null : Border.all(color: AppColors.borderColor),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          CustomText.body(msg.text, color: isMine ? Colors.white : AppColors.textPrimary),
          const SizedBox(height: 4),
          CustomText.small(
            '${msg.createdAt.hour}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
            color: isMine ? Colors.white70 : AppColors.textHint,
          ),
        ]),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.borderColor))),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: controller.messageController,
            decoration: InputDecoration(
              hintText: 'Type message...',
              filled: true,
              fillColor: AppColors.surface2,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: controller.sendMessage,
          child: const CircleAvatar(backgroundColor: AppColors.primary, child: Icon(Icons.send, color: Colors.white, size: 20)),
        ),
      ]),
    );
  }
}