import 'package:get/get.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/supabase_service.dart';
import '../routes/app_routes.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _navigate();
  }

  Future<void> _navigate() async {
    // Minimum splash display time
    await Future.delayed(const Duration(seconds: 2));

    final auth = AuthService.to;

    // Supabase session আছে কিনা check করো
    final session = SupabaseService.to.client.auth.currentSession;

    if (session == null) {
      // কোনো session নেই — login এ যাও
      Get.offAllNamed(AppRoutes.LOGIN);
      return;
    }

    // Session আছে কিন্তু profile এখনো load হয়নি হতে পারে
    // তাই fresh profile fetch করো
    try {
      final profile = await SupabaseService.to.getProfile(session.user.id);
      await auth.saveSession(profile);

      if (profile.isPending) {
        Get.offAllNamed(AppRoutes.PENDING_APPROVAL);
      } else if (profile.isBlocked) {
        await auth.logout();
        Get.offAllNamed(AppRoutes.LOGIN);
      } else if (profile.isAdmin) {
        Get.offAllNamed(AppRoutes.ADMIN_DASHBOARD);
      } else {
        Get.offAllNamed(AppRoutes.USER_DASHBOARD);
      }
    } catch (_) {
      // Profile fetch fail হলে login এ পাঠাও
      Get.offAllNamed(AppRoutes.LOGIN);
    }
  }
}