import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../../data/providers/api_provider.dart';
import '../../../../data/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../controllers/user_history_controller.dart';

class UserHistoryView extends GetView<UserHistoryController> {
  const UserHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const DarkTopBar(title: 'Transaction History', showBack: true),
      body: Obx(() => controller.isLoading.value
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: controller.fetchHistory,
              color: AppColors.primary,
              child: controller.transactions.isEmpty
                  ? const EmptyState(
                      icon: '📋',
                      title: 'No transactions yet',
                      subtitle: 'Your deposit history will appear here.')
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: controller.transactions.length,
                      itemBuilder: (_, i) => _txnItem(controller.transactions[i]),
                    ),
            )),
    );
  }

  Widget _txnItem(TransactionModel t) {
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
            color: t.isConfirmed ? AppColors.successLight : AppColors.warningLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            t.isConfirmed ? Icons.check_circle_outline : Icons.pending_outlined,
            color: t.isConfirmed ? AppColors.success : AppColors.warning,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.month,
                style: const TextStyle(fontFamily: 'Nunito', fontSize: 14,
                    fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            Text('${t.submittedAt.day}/${t.submittedAt.month}/${t.submittedAt.year}',
                style: const TextStyle(fontFamily: 'Nunito', fontSize: 12,
                    color: AppColors.textSecondary)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('+৳${t.amount.toStringAsFixed(0)}',
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 15,
                  fontWeight: FontWeight.w800, color: AppColors.success)),
          const SizedBox(height: 4),
          StatusBadge(status: t.status),
        ]),
      ]),
    );
  }
}
