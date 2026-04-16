import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/custom_Texxt_filed.dart';
import '../../../../core/widgets/custom_text.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../data/models/models.dart';
import '../../../../data/models/transaction_model.dart';
import '../controllers/admin_payment_controller.dart';

class AdminPaymentsView extends GetView<AdminPaymentsController> {
  const AdminPaymentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        title: const CustomText.title('Payments & Reports', color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Get.back(),
        ),
        actions: [
          // রিপোর্ট ডাউনলোড বাটন
          IconButton(
            icon: const Icon(Icons.download_for_offline_outlined, color: Colors.white),
            tooltip: 'Download Report',
            onPressed: () => _showDownloadPicker(context),
          ),
          // মান্থলি প্রাইজ সেট করার বাটন
          IconButton(
            icon: const Icon(Icons.add_chart_outlined, color: Colors.white),
            tooltip: 'Config Monthly Price',
            onPressed: () => _showMonthConfigDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
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
                subtitle: 'No payment requests match this filter.')
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: controller.payments.length,
              itemBuilder: (_, i) => _paymentItem(controller.payments[i]),
            ),
          )),
        ),
      ]),
    );
  }

  // --- পেমেন্ট আইটেম ডিজাইন ---
  Widget _paymentItem(TransactionModel p) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(children: [
        UserAvatar(
          initials: p.userName.isNotEmpty ? p.userName[0] : '?',
          color: AppColors.cardBlue,
          size: 46,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CustomText.subtitle(p.userName, color: AppColors.textPrimary),
            const SizedBox(height: 2),
            CustomText.small('${p.month} • ${_formatDate(p.submittedAt)}',
                color: AppColors.textSecondary),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          CustomText.subtitle('৳${p.amount.toStringAsFixed(0)}', color: AppColors.textPrimary),
          const SizedBox(height: 6),
          if (p.isPending)
            CustomButton(
              text: 'Confirm',
              height: 32,
              isFullWidth: false,
              borderRadius: 8,
              backgroundColor: AppColors.success,
              onPressed: () => controller.confirmPayment(p.id),
            )
          else
            StatusBadge(status: p.status),
        ]),
      ]),
    );
  }

  // --- ফিল্টার বার (All, Pending, Confirmed) ---
  Widget _filterBar() {
    final filters = ['all', 'pending', 'confirmed'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Obx(() => Row(
        children: filters.map((f) {
          final active = controller.selectedFilter.value == f;
          return GestureDetector(
            onTap: () => controller.setFilter(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.surface2,
                borderRadius: BorderRadius.circular(20),
              ),
              child: CustomText.label(
                f.toUpperCase(),
                color: active ? Colors.white : AppColors.textSecondary,
              ),
            ),
          );
        }).toList(),
      )),
    );
  }

  // --- ১. মাসের প্রাইজ কনফিগার করার ডায়ালগ ---
  void _showMonthConfigDialog(BuildContext context) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CustomText.title('Config Monthly Price'),
              const SizedBox(height: 8),
              const CustomText.small('Set custom funding for a specific month.',
                  color: AppColors.textSecondary),
              const SizedBox(height: 20),

              // মাস সিলেক্টর
              Obx(() => ListTile(
                tileColor: AppColors.surface2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: CustomText.body("Target Month: ${controller.configMonth.value.month}/${controller.configMonth.value.year}"),
                trailing: const Icon(Icons.calendar_month, color: AppColors.primary),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: controller.configMonth.value,
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) controller.configMonth.value = picked;
                },
              )),

              const SizedBox(height: 16),
              CustomTextField(
                controller: controller.configAmountCtrl,
                hint: 'Required Amount (৳)',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.payments_outlined,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: controller.configTitleCtrl,
                hint: 'Funding Title (e.g. Regular/Picnic)',
                prefixIcon: Icons.description_outlined,
              ),
              const SizedBox(height: 8),
              Obx(() => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const CustomText.small('Mark as Special Funding'),
                value: controller.isSpecial.value,
                activeColor: AppColors.primary,
                onChanged: (v) => controller.isSpecial.value = v!,
              )),

              const SizedBox(height: 20),
              Obx(() => CustomButton(
                text: 'Save Config',
                isLoading: controller.isLoading.value,
                onPressed: controller.saveMonthConfig,
              )),
            ],
          ),
        ),
      ),
    );
  }

  // --- ২. রিপোর্ট ডাউনলোডের জন্য মাস সিলেক্টর ডায়ালগ ---
  void _showDownloadPicker(BuildContext context) {
    DateTime tempSelected = DateTime.now();
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const CustomText.title('Generate Report'),
        content: const CustomText.body('Please select the month you want to generate the CSV report for.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const CustomText.body('Cancel', color: AppColors.textSecondary),
          ),
          ElevatedButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: tempSelected,
                firstDate: DateTime(2024),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                Get.back();
                controller.downloadReport(picked);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const CustomText.body('Select Month', color: Colors.white),
          ),
        ],
      ),
    );
  }

  // --- হেল্পার মেথড ---
  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}