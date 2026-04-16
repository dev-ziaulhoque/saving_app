import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/models.dart';
import '../../../data/services/chat_service.dart';

class ChatController extends GetxController {
  final messageController = TextEditingController();
  final scrollController = ScrollController();

  // late সরিয়ে .obs ব্যবহার করুন
  final receiverId = ''.obs;
  final receiverName = 'Loading...'.obs;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments;
    if (args != null && args is UserModel) {
      receiverId.value = args.id;
      receiverName.value = args.name;
    } else {
      _loadAdminInfo();
    }

    /// mark as read
    if (args != null && args is UserModel) {
      receiverId.value = args.id;
      receiverName.value = args.name;
      _markRead();
    } else {
      _loadAdminInfo();
    }
  }

  Future<void> _loadAdminInfo() async {
    try {
      final adminId = await ChatService.to.getAdminId();
      if (adminId != null) {
        receiverId.value = adminId;
        receiverName.value = 'Admin Support';
      }
    } catch (e) {
      receiverName.value = 'Support';
      Get.snackbar('Error', 'Could not load admin info');
    }
  }

  void sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || receiverId.isEmpty) return;

    messageController.clear();
    try {
      await ChatService.to.sendMessage(receiverId.value, text);
      _scrollToBottom();
    } catch (e) {
      Get.snackbar('Error', 'Message not sent');
    }
  }

  void _scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _markRead() async {
    if (receiverId.value.isNotEmpty) {
      await ChatService.to.markAsRead(receiverId.value);
    }
  }
}