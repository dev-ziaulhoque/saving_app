import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/models/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/services/supabase_service.dart';

// ─── Controller ───────────────────────────────────────────────
class AdminPaymentsController extends GetxController {
  final isLoading      = false.obs;
  final payments       = <TransactionModel>[].obs;
  final selectedFilter = 'all'.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPayments();
  }

  Future<void> fetchPayments() async {
    isLoading.value = true;
    try {
      payments.value = await SupabaseService.to.getAllPayments(
        status: selectedFilter.value == 'all' ? null : selectedFilter.value,
      );
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  void setFilter(String f) {
    selectedFilter.value = f;
    fetchPayments();
  }

  Future<void> confirmPayment(String paymentId) async {
    try {
      await SupabaseService.to.confirmPayment(paymentId);

      // Update local state
      final idx = payments.indexWhere((p) => p.id == paymentId);
      if (idx != -1) {
        final old = payments[idx];
        payments[idx] = TransactionModel(
          id: old.id, userId: old.userId, userName: old.userName,
          amount: old.amount, month: old.month, monthYear: old.monthYear,
          status: 'confirmed', submittedAt: old.submittedAt,
          confirmedAt: DateTime.now(),
        );
        payments.refresh();
      }

      Get.snackbar('Confirmed ✅', 'Payment confirmed successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12);
    } catch (e) {
      Get.snackbar('Error', e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12);
    }
  }
}


// ─── Binding ──────────────────────────────────────────────────
class AdminPaymentsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminPaymentsController>(() => AdminPaymentsController());
  }
}

// ─── View ─────────────────────────────────────────────────────
class AdminPaymentsView extends GetView<AdminPaymentsController> {
  const AdminPaymentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const DarkTopBar(title: 'Payments', showBack: true),
      body: Column(children: [
        _filterBar(),
        Expanded(
          child: Obx(() => controller.isLoading.value
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : RefreshIndicator(
                  onRefresh: controller.fetchPayments,
                  color: AppColors.primary,
                  child: controller.payments.isEmpty
                      ? const EmptyState(
                          icon: '💳',
                          title: 'No payments found',
                          subtitle: 'No payments match this filter.')
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: controller.payments.length,
                          itemBuilder: (_, i) => _paymentItem(controller.payments[i]),
                        ),
                )),
        ),
      ]),
    );
  }

  Widget _filterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Obx(() => Row(
        children: ['all', 'pending', 'confirmed'].map((f) {
          final active = controller.selectedFilter.value == f;
          return GestureDetector(
            onTap: () => controller.setFilter(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.surface2,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(f[0].toUpperCase() + f.substring(1),
                  style: TextStyle(
                      fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w700,
                      color: active ? Colors.white : AppColors.textSecondary)),
            ),
          );
        }).toList(),
      )),
    );
  }

  Widget _paymentItem(TransactionModel p) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: p.isConfirmed ? AppColors.successLight : AppColors.warningLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            p.isConfirmed ? Icons.check_circle_outline : Icons.pending_outlined,
            color: p.isConfirmed ? AppColors.success : AppColors.warning,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.userName,
                style: const TextStyle(fontFamily: 'Nunito', fontSize: 14,
                    fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            Text('${p.month} • ${_date(p.submittedAt)}',
                style: const TextStyle(fontFamily: 'Nunito', fontSize: 12,
                    color: AppColors.textSecondary)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('৳${p.amount.toStringAsFixed(0)}',
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 15,
                  fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          if (p.isPending)
            GestureDetector(
              onTap: () => controller.confirmPayment(p.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Confirm',
                    style: TextStyle(fontFamily: 'Nunito', fontSize: 11,
                        fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            )
          else
            StatusBadge(status: p.status),
        ]),
      ]),
    );
  }

  String _date(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
