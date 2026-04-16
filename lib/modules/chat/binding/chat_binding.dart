import 'package:get/get.dart';

import '../../../data/services/chat_service.dart';
import '../controllers/admin_inbox_controller.dart';
import '../controllers/chat_controller.dart';

class ChatBinding extends Bindings {
  @override
  void dependencies() {
    // ChatService না থাকলে সেটি পুট করো
    if (!Get.isRegistered<ChatService>()) {
      Get.put(ChatService());
    }
    Get.lazyPut<AdminInboxController>(() => AdminInboxController());
    // তারপর কন্ট্রোলার লোড করো
    Get.lazyPut<ChatController>(() => ChatController());
  }
}