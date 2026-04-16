import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../modules/chat/model/message_model.dart';
import '../models/models.dart';
import 'auth_service.dart';

class ChatService extends GetxService {
  static ChatService get to => Get.find();
  final _supabase = Supabase.instance.client;

  // ১. মেসেজ স্ট্রিম (রিয়েল-টাইম)
  Stream<List<MessageModel>> getChatStream(String otherUserId) {
    final myId = AuthService.to.currentUser.value!.id;
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
    await _supabase.from('messages').insert({
      'sender_id': myId,
      'receiver_id': receiverId,
      'text': text,
    });
  }

  // ৩. অ্যাডমিনের চ্যাট লিস্ট (RPC)
  Future<List<Map<String, dynamic>>> getAdminChatList() async {
    final res = await _supabase.rpc('get_admin_chat_list');
    return List<Map<String, dynamic>>.from(res);
  }

  // ৪. অ্যাডমিন আইডি খুঁজে বের করা (ইউজারের জন্য)
  Future<String?> getAdminId() async {
    try {
      final res = await _supabase
          .from('profiles')
          .select('id')
          .eq('role', 'admin')
          .limit(1)
          .maybeSingle();

      if (res == null) {
        print("❌ Error: No Admin found in Profiles table!");
        return null;
      }

      print("✅ Admin Found: ${res['id']}");
      return res['id'];
    } catch (e) {
      print("❌ Supabase Error in getAdminId: $e");
      return null;
    }
  }

  Future<void> markAsRead(String senderId) async {
    final myId = _supabase.auth.currentUser!.id;
    try {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('sender_id', senderId) // ইউজারের পাঠানো মেসেজ
          .eq('receiver_id', myId)   // যা এডমিনের কাছে এসেছে
          .eq('is_read', false);     // যেগুলো এখনো পড়া হয়নি
    } catch (e) {
      print("Error marking messages as read: $e");
    }
  }
}