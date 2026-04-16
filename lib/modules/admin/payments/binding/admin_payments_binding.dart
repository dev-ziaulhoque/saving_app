import 'package:get/get.dart';

import '../controllers/admin_payment_controller.dart';

class AdminPaymentsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminPaymentsController>(() => AdminPaymentsController());
  }
}
