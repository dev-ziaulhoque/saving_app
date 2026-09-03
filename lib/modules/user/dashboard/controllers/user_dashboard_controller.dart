import 'dart:math' as math;

import 'package:get/get.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../../data/services/supabase_service.dart';
import '../../../../data/services/auth_service.dart';

class UserDashboardController extends GetxController {
  final isLoading = false.obs;
  final totalSaved = 0.0.obs;
  final monthlyAmount = 0.0.obs;
  final monthsPaid = 0.obs;
  final totalMonths = 18.obs;
  final dues = 0.0.obs;
  final recentTransactions = <TransactionModel>[].obs;
  final paymentCalendar = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    isLoading.value = true;
    final uid = AuthService.to.currentUser.value!.id;
    try {
      // Dashboard summary via RPC
      final dash = await SupabaseService.to.getUserDashboard();
      totalSaved.value = (dash['total_saved'] ?? 0).toDouble();
      monthlyAmount.value = (dash['monthly_amount'] ?? 0).toDouble();
      monthsPaid.value = dash['months_paid'] ?? 0;
      totalMonths.value = dash['total_months'] ?? 18;
      dues.value = (dash['dues'] ?? 0).toDouble();

      // Recent transactions (latest 5)
      final allTxns = await SupabaseService.to.getUserTransactions(uid);
      recentTransactions.value = allTxns.take(5).toList();
      paymentCalendar
          .assignAll(await SupabaseService.to.getUserPaymentCalendar());
      final nowMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
      final elapsed = paymentCalendar.where((item) {
        final month = DateTime.parse(item['month'].toString());
        return !month.isAfter(nowMonth);
      }).toList();
      final calendarDue = elapsed.fold<double>(0, (sum, item) {
        final required = (item['required'] as num? ?? 0).toDouble();
        final confirmed = (item['confirmed'] as num? ?? 0).toDouble();
        return sum + math.max(required - confirmed, 0);
      });
      dues.value = math.max(dues.value, calendarDue);
      monthsPaid.value =
          elapsed.where((item) => item['status'] == 'paid').length;
      totalMonths.value = elapsed.length;
    } catch (_) {
      // Fallback to cached profile
      final user = AuthService.to.currentUser.value;
      if (user != null) {
        totalSaved.value = user.totalSaved;
        monthlyAmount.value = user.monthlyAmount;
        dues.value = user.dues;
      }
    } finally {
      isLoading.value = false;
    }
  }
}
