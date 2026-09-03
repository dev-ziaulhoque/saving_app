import 'package:get/get.dart';

import '../../../../data/models/transaction_model.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../data/services/supabase_service.dart';

class UserHistoryController extends GetxController {
  final isLoading = false.obs;
  final transactions = <TransactionModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    isLoading.value = true;
    try {
      final uid = AuthService.to.currentUser.value?.id;
      if (uid == null) throw StateError('No authenticated user');
      transactions.value = await SupabaseService.to.getUserTransactions(uid);
    } catch (error) {
      Get.snackbar('Error', 'Could not load transaction history: $error');
    } finally {
      isLoading.value = false;
    }
  }
}
