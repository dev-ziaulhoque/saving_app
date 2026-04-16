import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../data/models/models.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/chat_service.dart';

class AdminInboxController extends GetxController {
  final chatList = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchInbox();
  }

  Future<void> fetchInbox() async {
    isLoading.value = true;
    try {
      final list = await ChatService.to.getAdminChatList();
      chatList.assignAll(list);
    } catch (e) {
      print("Error fetching inbox: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void goToChat(Map<String, dynamic> chatData) {
    final user = UserModel(
      id: chatData['user_id'] ?? '',
      name: chatData['user_name'] ?? 'Unknown User',
      phone: '',
      email: '',
      role: 'user',
      status: 'active',
      monthlyAmount: 0.0,
      totalSaved: 0.0,
      dues: 0.0,
      joinedAt: DateTime.now(),
    );

    // আপনার দেওয়া রাউট অনুযায়ী চ্যাট ডিটেইলসে যাওয়া
    Get.toNamed(AppRoutes.ADMIN_CHAT_DETAIL, arguments: user)!.then((_) {
      fetchInbox();
    });
  }
}