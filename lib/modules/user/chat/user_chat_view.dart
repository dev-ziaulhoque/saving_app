import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/models/models.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';

// ─── Controller ───────────────────────────────────────────────
class UserChatController extends GetxController {
  final _api = ApiProvider();
  final messages = <MessageModel>[].obs;
  final isLoading = false.obs;
  final isSending = false.obs;
  final messageController = TextEditingController();
  final scrollController = ScrollController();

  static const _adminId = 'admin';

  @override
  void onInit() {
    super.onInit();
    fetchMessages();
  }

  Future<void> fetchMessages() async {
    isLoading.value = true;
    try {
      final res = await _api.getMessages(_adminId);
      messages.value = (res.data['messages'] as List)
          .map((m) => MessageModel.fromJson(m))
          .toList();
      _scrollToBottom();
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;
    messageController.clear();
    isSending.value = true;
    try {
      await _api.sendMessage(_adminId, text);
      final user = AuthService.to.currentUser.value!;
      messages.add(MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: user.id,
        senderName: user.name,
        receiverId: _adminId,
        text: text,
        sentAt: DateTime.now(),
      ));
      _scrollToBottom();
    } catch (_) {
    } finally {
      isSending.value = false;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void onClose() {
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}

// ─── Binding ──────────────────────────────────────────────────
class UserChatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserChatController>(() => UserChatController());
  }
}

// ─── View ─────────────────────────────────────────────────────
class UserChatView extends GetView<UserChatController> {
  const UserChatView({super.key});

  @override
  Widget build(BuildContext context) {
    final myId = AuthService.to.currentUser.value?.id ?? '';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Get.back(),
        ),
        title: Row(children: [
          const UserAvatar(initials: 'AD', color: AppColors.primary, size: 34),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Admin Support',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 15,
                    fontWeight: FontWeight.w700, color: Colors.white)),
            Text('Online',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 11,
                    color: Colors.greenAccent.withOpacity(0.8))),
          ]),
        ]),
      ),
      body: Column(children: [
        Expanded(
          child: Obx(() => controller.isLoading.value
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : controller.messages.isEmpty
                  ? Center(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Text('💬', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        const Text('No messages yet',
                            style: TextStyle(fontFamily: 'Nunito', fontSize: 16,
                                fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        const SizedBox(height: 6),
                        Text('Send a message to the admin',
                            style: const TextStyle(fontFamily: 'Nunito', fontSize: 13,
                                color: AppColors.textSecondary)),
                      ]),
                    )
                  : ListView.builder(
                      controller: controller.scrollController,
                      padding: const EdgeInsets.all(14),
                      itemCount: controller.messages.length,
                      itemBuilder: (_, i) {
                        final msg = controller.messages[i];
                        final isMine = msg.senderId == myId;
                        return _bubble(msg, isMine);
                      },
                    )),
        ),
        _inputBar(),
      ]),
    );
  }

  Widget _bubble(MessageModel msg, bool isMine) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(Get.context!).size.width * 0.72),
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
          Text(msg.text,
              style: TextStyle(fontFamily: 'Nunito', fontSize: 14,
                  color: isMine ? Colors.white : AppColors.textPrimary,
                  height: 1.4)),
          const SizedBox(height: 3),
          Text(
            '${msg.sentAt.hour}:${msg.sentAt.minute.toString().padLeft(2, '0')}',
            style: TextStyle(fontFamily: 'Nunito', fontSize: 10,
                color: isMine ? Colors.white60 : AppColors.textHint),
          ),
        ]),
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderColor)),
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: controller.messageController,
            style: const TextStyle(fontFamily: 'Nunito', fontSize: 14),
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => controller.sendMessage(),
            decoration: InputDecoration(
              hintText: 'Type a message...',
              hintStyle: const TextStyle(fontFamily: 'Nunito',
                  color: AppColors.textHint, fontSize: 14),
              filled: true,
              fillColor: AppColors.surface2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Obx(() => GestureDetector(
          onTap: controller.isSending.value ? null : controller.sendMessage,
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(22),
            ),
            child: controller.isSending.value
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        )),
      ]),
    );
  }
}
