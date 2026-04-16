import 'package:get/get.dart';

import '../../../../data/models/models.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../../data/providers/api_provider.dart';

class UserHistoryController extends GetxController {
  final _api = ApiProvider();
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
      final res = await _api.getUserTransactions();
      transactions.value = (res.data['transactions'] as List)
          .map((t) => TransactionModel.fromJson(t))
          .toList();
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }
}