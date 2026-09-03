import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/models/user_model.dart';
import '../../../data/services/chat_service.dart';

class ChatController extends GetxController {
  final messageController = TextEditingController();
  final scrollController = ScrollController();

  // late সরিয়ে .obs ব্যবহার করুন
  final receiverId = ''.obs;
  final receiverName = 'Loading...'.obs;
  final isUploading = false.obs;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments;
    if (args is UserModel) {
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
        await _markRead();
      } else {
        receiverName.value = 'Support unavailable';
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

  Future<void> sendImage(ImageSource source) async {
    if (receiverId.value.isEmpty || isUploading.value) return;
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1920,
    );
    if (picked == null) return;
    await _sendFile(File(picked.path), 'image', picked.name);
  }

  Future<void> sendDocument() async {
    if (receiverId.value.isEmpty || isUploading.value) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
    );
    final picked = result?.files.single;
    if (picked?.path == null) return;
    await _sendFile(File(picked!.path!), 'document', picked.name);
  }

  Future<void> _sendFile(File file, String type, String name) async {
    isUploading.value = true;
    try {
      await ChatService.to.sendAttachment(
        receiverId: receiverId.value,
        file: file,
        type: type,
        fileName: name,
        text: messageController.text.trim(),
      );
      messageController.clear();
      _scrollToBottom();
    } catch (e) {
      Get.snackbar('Upload failed', e.toString());
    } finally {
      isUploading.value = false;
    }
  }

  void _scrollToBottom() {
    // ChatDetailsView is reversed, therefore offset 0 is the visual bottom.
    Future<void>.delayed(const Duration(milliseconds: 100), () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!scrollController.hasClients) return;
        scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      });
    });
  }

  Future<void> _markRead() async {
    if (receiverId.value.isNotEmpty) {
      await ChatService.to.markAsRead(receiverId.value);
    }
  }
}
