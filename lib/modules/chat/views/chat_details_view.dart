import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/custom_text.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/chat_service.dart';
import '../controllers/chat_controller.dart';
import '../model/message_model.dart';

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
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
          onPressed: () => Get.back(),
        ),
        // ১. টাইটেল সেকশনে Obx ব্যবহার করা হয়েছে যাতে receiverName লোড হলে আপডেট হয়
        title: Obx(() => Row(children: [
              UserAvatar(
                  initials: controller.receiverName.value.isNotEmpty
                      ? controller.receiverName.value[0]
                      : '?',
                  color: AppColors.primary,
                  size: 36),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                CustomText.subtitle(controller.receiverName.value,
                    color: Colors.white),
                const CustomText.small('Private support chat',
                    color: Colors.greenAccent),
              ]),
            ])),
      ),
      body: Column(children: [
        Expanded(
          child: Obx(() {
            // ২. receiverId খালি থাকলে এরর এড়াতে লোডিং ইন্ডিকেটর দেখানো হচ্ছে
            if (controller.receiverId.value.isEmpty) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary));
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
                        CustomText.body('No messages yet',
                            color: AppColors.textSecondary),
                      ],
                    ),
                  );
                }

                // মেসেজ লিস্ট রেন্ডার
                return ListView.builder(
                  controller: controller.scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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

  Widget _buildMessageBubble(MessageModel msg, bool isMine) {
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
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          if (msg.hasAttachment) _attachment(msg, isMine),
          if (msg.hasAttachment && msg.text.isNotEmpty)
            const SizedBox(height: 7),
          if (msg.text.isNotEmpty)
            CustomText.body(msg.text,
                color: isMine ? Colors.white : AppColors.textPrimary),
          const SizedBox(height: 4),
          CustomText.small(
            '${msg.createdAt.hour}:${msg.createdAt.minute.toString().padLeft(2, '0')}${isMine ? (msg.isRead ? '  ✓✓' : '  ✓') : ''}',
            color: isMine ? Colors.white70 : AppColors.textHint,
          ),
        ]),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 10,
          bottom: Get.context!.mediaQueryPadding.bottom + 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2))
        ],
      ),
      child: Row(children: [
        Obx(() => IconButton(
              onPressed:
                  controller.isUploading.value ? null : _showAttachmentOptions,
              icon: controller.isUploading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.add_circle_outline,
                      color: AppColors.primary),
            )),
        Expanded(
          child: TextField(
            controller: controller.messageController,
            style: const TextStyle(fontFamily: 'Nunito', fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Type your message...',
              hintStyle: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  color: AppColors.textHint),
              filled: true,
              fillColor: AppColors.surface2,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            height: 45,
            width: 45,
            decoration: const BoxDecoration(
                color: AppColors.primary, shape: BoxShape.circle),
            child:
                const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }

  Widget _attachment(MessageModel message, bool isMine) {
    return FutureBuilder<String>(
      future: ChatService.to.createAttachmentUrl(message.attachmentPath!),
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
              height: 52,
              width: 150,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
        }
        final url = snapshot.data!;
        if (message.isImage) {
          return GestureDetector(
            onTap: () =>
                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(url,
                  width: 220,
                  height: 170,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _documentTile(message, url, isMine)),
            ),
          );
        }
        return _documentTile(message, url, isMine);
      },
    );
  }

  Widget _documentTile(MessageModel message, String url, bool isMine) =>
      InkWell(
        onTap: () =>
            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isMine
                ? Colors.white.withValues(alpha: .15)
                : AppColors.surface2,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            Icon(Icons.description_outlined,
                color: isMine ? Colors.white : AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(message.attachmentName ?? 'Document',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12,
                          color: isMine ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w700)),
                  if (message.attachmentSize != null)
                    Text(_fileSize(message.attachmentSize!),
                        style: TextStyle(
                            fontSize: 9,
                            color: isMine
                                ? Colors.white70
                                : AppColors.textSecondary)),
                ])),
            Icon(Icons.open_in_new,
                size: 16,
                color: isMine ? Colors.white70 : AppColors.textSecondary),
          ]),
        ),
      );

  String _fileSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  void _showAttachmentOptions() => Get.bottomSheet(
        SafeArea(
          child: Wrap(children: [
            ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppColors.primary),
                title: const Text('Photo from gallery'),
                onTap: () {
                  Get.back();
                  controller.sendImage(ImageSource.gallery);
                }),
            ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: AppColors.primary),
                title: const Text('Take a photo'),
                onTap: () {
                  Get.back();
                  controller.sendImage(ImageSource.camera);
                }),
            ListTile(
                leading:
                    const Icon(Icons.attach_file, color: AppColors.primary),
                title: const Text('Send document (max 10 MB)'),
                subtitle: const Text('PDF, Word, Excel or text file'),
                onTap: () {
                  Get.back();
                  controller.sendDocument();
                }),
          ]),
        ),
        backgroundColor: Colors.white,
      );
}
