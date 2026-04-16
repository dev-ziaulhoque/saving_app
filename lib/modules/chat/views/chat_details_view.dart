import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/custom_text.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/chat_service.dart';
import '../controllers/chat_controller.dart';

class ChatDetailsView extends GetView<ChatController> {
  const ChatDetailsView({super.key});

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
        // ১. টাইটেল সেকশনে Obx ব্যবহার করা হয়েছে যাতে receiverName লোড হলে আপডেট হয়
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
      body: Column(children: [
        Expanded(
          child: Obx(() {
            // ২. receiverId খালি থাকলে এরর এড়াতে লোডিং ইন্ডিকেটর দেখানো হচ্ছে
            if (controller.receiverId.value.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            return StreamBuilder(
              // ৩. controller.receiverId.value ব্যবহার করা হয়েছে
              stream: ChatService.to.getChatStream(controller.receiverId.value),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('💬', style: TextStyle(fontSize: 40)),
                        SizedBox(height: 10),
                        CustomText.body('No messages yet', color: AppColors.textSecondary),
                      ],
                    ),
                  );
                }

                // মেসেজ লিস্ট রেন্ডার
                return ListView.builder(
                  controller: controller.scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: messages.length,
                  reverse: true,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    final isMine = msg.senderId == myId;
                    return _buildMessageBubble(msg, isMine);
                  },
                );
              },
            );
          }),
        ),
        _buildInputArea(),
      ]),
    );
  }

  Widget _buildMessageBubble(msg, bool isMine) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: Get.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          CustomText.body(
              msg.text,
              color: isMine ? Colors.white : AppColors.textPrimary
          ),
          const SizedBox(height: 4),
          CustomText.small(
            '${msg.createdAt.hour}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
            color: isMine ? Colors.white70 : AppColors.textHint,
          ),
        ]),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
          left: 16, right: 16, top: 10,
          bottom: Get.context!.mediaQueryPadding.bottom + 10
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))
        ],
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: controller.messageController,
            style: const TextStyle(fontFamily: 'Nunito', fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Type your message...',
              hintStyle: const TextStyle(fontFamily: 'Nunito', fontSize: 14, color: AppColors.textHint),
              filled: true,
              fillColor: AppColors.surface2,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (_) => controller.sendMessage(),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: controller.sendMessage,
          child: Container(
            height: 45, width: 45,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }
}