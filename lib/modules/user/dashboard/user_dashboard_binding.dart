import 'package:get/get.dart';
import 'package:saving_app/modules/user/dashboard/user_dashboard_controller.dart';

class UserDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserDashboardController>(() => UserDashboardController());
  }
}