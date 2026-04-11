import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/services/supabase_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/models/models.dart';

class ChatController extends GetxController {
  final messages       = <MessageModel>[].obs;
  final isLoading      = false.obs;
  final isSending      = false.obs;
  final messageCtrl    = TextEditingController();
  final scrollCtrl     = ScrollController();

  late final String _myId;
  late final String _otherId;
  RealtimeChannel? _channel;

  @override
  void onInit() {
    super.onInit();
    _myId    = AuthService.to.currentUser.value!.id;
    _otherId = Get.arguments as String; // pass the other user's ID
    _fetchAndSubscribe();
  }

  Future<void> _fetchAndSubscribe() async {
    isLoading.value = true;
    try {
      messages.value = await SupabaseService.to.getMessages(
        userAId: _myId,
        userBId: _otherId,
      );
      _scrollToBottom();

      // Mark messages as read
      await SupabaseService.to.markMessagesRead(
        senderId: _otherId,
        receiverId: _myId,
      );

      // Subscribe to realtime new messages
      _channel = SupabaseService.to.subscribeToMessages(
        userAId: _myId,
        userBId: _otherId,
        onMessage: (msg) {
          messages.add(msg);
          _scrollToBottom();
          // Auto-mark as read if it's from the other person
          if (msg.senderId == _otherId) {
            SupabaseService.to.markMessagesRead(
              senderId: _otherId,
              receiverId: _myId,
            );
          }
        },
      );
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendMessage() async {
    final text = messageCtrl.text.trim();
    if (text.isEmpty) return;
    messageCtrl.clear();
    isSending.value = true;

    try {
      await SupabaseService.to.sendMessage(
        senderId:   _myId,
        receiverId: _otherId,
        text:       text,
      );
      // Realtime will push it back; but add locally for instant feel
      messages.add(MessageModel(
        id:         DateTime.now().millisecondsSinceEpoch.toString(),
        senderId:   _myId,
        senderName: AuthService.to.currentUser.value!.name,
        receiverId: _otherId,
        text:       text,
        sentAt:     DateTime.now(),
      ));
      _scrollToBottom();
    } catch (_) {
    } finally {
      isSending.value = false;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollCtrl.hasClients) {
        scrollCtrl.animateTo(
          scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void onClose() {
    _channel?.unsubscribe();
    messageCtrl.dispose();
    scrollCtrl.dispose();
    super.onClose();
  }
}
