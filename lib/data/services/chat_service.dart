import 'dart:io';

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app/app_config/app_config.dart';
import '../../modules/chat/model/message_model.dart';
import '../../core/utils/app_logger.dart';
import 'auth_service.dart';
import 'badge_service.dart';

class ChatService extends GetxService {
  static ChatService get to => Get.find();
  final _supabase = Supabase.instance.client;

  // ১. মেসেজ স্ট্রিম (রিয়েল-টাইম)
  Stream<List<MessageModel>> getChatStream(String otherUserId) {
    final myId = AuthService.to.currentUser.value!.id;
    AppLogger.request('chat.subscribe', {
      'user_id': myId,
      'other_user_id': otherUserId,
    });
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
          return data
              .where((m) =>
                  (m['sender_id'] == myId && m['receiver_id'] == otherUserId) ||
                  (m['sender_id'] == otherUserId && m['receiver_id'] == myId))
              .map((m) => MessageModel.fromJson(m))
              .toList();
        });
  }

  // ২. মেসেজ পাঠানো
  Future<void> sendMessage(String receiverId, String text) async {
    final myId = AuthService.to.currentUser.value!.id;
    AppLogger.request('chat.send', {
      'sender_id': myId,
      'receiver_id': receiverId,
      'text': text,
    });
    await _supabase.from('messages').insert({
      'sender_id': myId,
      'receiver_id': receiverId,
      'text': text,
    });
    AppLogger.success('chat.send');
  }

  Future<void> sendAttachment({
    required String receiverId,
    required File file,
    required String type,
    required String fileName,
    String text = '',
  }) async {
    final myId = AuthService.to.currentUser.value!.id;
    final size = await file.length();
    if (size <= 0 || size > 10 * 1024 * 1024) {
      throw StateError('Attachment must be between 1 byte and 10 MB');
    }
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path =
        '$myId/$receiverId/${DateTime.now().millisecondsSinceEpoch}-$safeName';
    final contentType = _contentType(fileName, type);
    AppLogger.request('chat.uploadAttachment', {
      'receiver_id': receiverId,
      'type': type,
      'file_name': safeName,
      'bytes': size,
    });
    await _supabase.storage.from('chat-attachments').upload(
          path,
          file,
          fileOptions: FileOptions(contentType: contentType),
        );
    try {
      await _supabase.from('messages').insert({
        'sender_id': myId,
        'receiver_id': receiverId,
        'text': text.trim(),
        'attachment_path': path,
        'attachment_type': type,
        'attachment_name': fileName,
        'attachment_size': size,
      });
      AppLogger.success('chat.uploadAttachment', {'path': path});
    } catch (_) {
      try {
        await _supabase.storage.from('chat-attachments').remove([path]);
      } catch (_) {}
      rethrow;
    }
  }

  Future<String> createAttachmentUrl(String path) =>
      _supabase.storage.from('chat-attachments').createSignedUrl(path, 3600);

  String _contentType(String name, String type) {
    final ext = name.split('.').last.toLowerCase();
    const types = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'webp': 'image/webp',
      'gif': 'image/gif',
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'txt': 'text/plain',
    };
    return types[ext] ?? (type == 'image' ? 'image/jpeg' : 'text/plain');
  }

  // ৩. অ্যাডমিনের চ্যাট লিস্ট (RPC)
  Future<List<Map<String, dynamic>>> getAdminChatList() async {
    final res = await _supabase.rpc('get_admin_chat_list');
    return List<Map<String, dynamic>>.from(res);
  }

  // ৪. অ্যাডমিন আইডি খুঁজে বের করা (ইউজারের জন্য)
  Future<String?> getAdminId() async {
    // Use the same canonical support account as the admin inbox. This avoids
    // routing users to a different account when multiple admins are active.
    if (AppConfig.adminId.isNotEmpty) {
      try {
        final configured = await _supabase
            .from('profiles')
            .select('id')
            .eq('id', AppConfig.adminId)
            .eq('role', 'admin')
            .eq('status', 'active')
            .maybeSingle();
        if (configured != null) {
          AppLogger.success(
              'chat.getAdminId.configured', {'admin_id': configured['id']});
          return configured['id'] as String;
        }
      } catch (error) {
        AppLogger.error('chat.getAdminId.configured', error);
      }
    }
    try {
      AppLogger.request('chat.getAdminId');
      final res = await _supabase.rpc('get_admin_id');

      if (res == null) {
        return null;
      }
      AppLogger.success('chat.getAdminId', {'admin_id': res});
      return res as String;
    } catch (error) {
      if (error is! PostgrestException || error.code != 'PGRST202') {
        AppLogger.error('chat.getAdminId', error);
      }
      try {
        final row = await _supabase
            .from('profiles')
            .select('id')
            .eq('role', 'admin')
            .eq('status', 'active')
            .limit(1)
            .maybeSingle();
        if (row != null) {
          AppLogger.success(
              'chat.getAdminId.fallback', {'admin_id': row['id']});
          return row['id'] as String;
        }
      } catch (_) {}
      // Keeps support chat usable while PostgREST refreshes a repaired RPC.
      final fallback = AppConfig.adminId.isEmpty ? null : AppConfig.adminId;
      if (fallback != null) {
        AppLogger.success(
            'chat.getAdminId.configFallback', {'admin_id': fallback});
      }
      return fallback;
    }
  }

  Future<void> markAsRead(String senderId) async {
    final myId = _supabase.auth.currentUser!.id;
    try {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('sender_id', senderId) // ইউজারের পাঠানো মেসেজ
          .eq('receiver_id', myId) // যা এডমিনের কাছে এসেছে
          .eq('is_read', false); // যেগুলো এখনো পড়া হয়নি
      if (Get.isRegistered<BadgeService>()) {
        await BadgeService.to.refresh();
      }
    } catch (_) {}
  }
}
