import 'package:get/get.dart';
import 'admin_users_controller.dart';

class AdminUsersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminUsersController>(() => AdminUsersController());
  }
}
