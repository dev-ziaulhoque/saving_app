import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/custom_Texxt_filed.dart';
import '../../../../core/widgets/custom_text.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../../app/routes/app_routes.dart';
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
        title:
            const CustomText.title('Payments & Reports', color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
          onPressed: () => Get.back(),
        ),
        actions: [
          // রিপোর্ট ডাউনলোড বাটন
          IconButton(
            icon: const Icon(Icons.download_for_offline_outlined,
                color: Colors.white),
            tooltip: 'All-time PDF statement',
            onPressed: () => Get.toNamed(AppRoutes.ADMIN_ACCOUNTING),
          ),
          IconButton(
            icon: const Icon(Icons.post_add_outlined, color: Colors.white),
            tooltip: 'Add manual payment with proof',
            onPressed: () => _showManualPaymentDialog(context),
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
        _paymentSummary(),
        _filterBar(),
        Expanded(
          child: Obx(() => controller.isLoading.value
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
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
                          itemBuilder: (_, i) =>
                              _paymentItem(controller.payments[i]),
                        ),
                )),
        ),
      ]),
    );
  }

  Widget _paymentSummary() => Obx(() => Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppColors.bgDark, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Expanded(
              child: _summaryValue('Confirmed', controller.totalConfirmed.value,
                  AppColors.successLight)),
          Container(width: 1, height: 38, color: Colors.white24),
          Expanded(
              child: _summaryValue('Pending', controller.totalPending.value,
                  AppColors.warningLight)),
          Container(width: 1, height: 38, color: Colors.white24),
          Expanded(
              child: _summaryValue('Entries',
                  controller.totalEntries.value.toDouble(), Colors.white)),
        ]),
      ));

  Widget _summaryValue(String label, double value, Color color) =>
      Column(children: [
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.white60)),
        const SizedBox(height: 3),
        Text(
            label == 'Entries'
                ? value.toInt().toString()
                : '৳${value.toStringAsFixed(0)}',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800, color: color)),
      ]);

  void _showManualPaymentDialog(BuildContext context) {
    if (controller.users.isEmpty) {
      Get.snackbar('No active users', 'No active member is available.');
      return;
    }
    String selectedUser = controller.users.first.id;
    final amount = TextEditingController();
    final note = TextEditingController();
    controller.manualProof.value = null;
    controller.loadManualMonths(selectedUser);
    Get.dialog(StatefulBuilder(
        builder: (_, setState) => AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              title: const Text('Manual payment with proof'),
              content: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text(
                    'This creates an immutable confirmed entry. A proof and clear note are mandatory.',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                    initialValue: selectedUser,
                    decoration: const InputDecoration(labelText: 'Member'),
                    items: controller.users
                        .map((u) =>
                            DropdownMenuItem(value: u.id, child: Text(u.name)))
                        .toList(),
                    onChanged: (v) {
                      setState(() => selectedUser = v!);
                      controller.loadManualMonths(selectedUser);
                    }),
                const SizedBox(height: 10),
                TextField(
                    controller: amount,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Amount per month')),
                const SizedBox(height: 10),
                const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Select unpaid / future months',
                        style: TextStyle(fontWeight: FontWeight.w700))),
                const SizedBox(height: 8),
                Obx(() => controller.manualAvailableMonths.isEmpty
                    ? const Text('No unpaid month available',
                        style: TextStyle(color: AppColors.textSecondary))
                    : Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: controller.manualAvailableMonths.map((row) {
                          final date = row['date'] as DateTime;
                          final key = row['key'] as String;
                          final selected =
                              controller.manualSelectedMonthKeys.contains(key);
                          return FilterChip(
                            label: Text(controller.monthLabel(date)),
                            selected: selected,
                            onSelected: (_) =>
                                controller.toggleManualMonth(key),
                            backgroundColor: Colors.white,
                            selectedColor:
                                AppColors.primary.withValues(alpha: .14),
                            checkmarkColor: AppColors.primary,
                            side: BorderSide(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.borderColor),
                          );
                        }).toList(),
                      )),
                const SizedBox(height: 10),
                TextField(
                    controller: note,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(
                        labelText: 'Reason / payment source')),
                const SizedBox(height: 10),
                Obx(() => OutlinedButton.icon(
                    onPressed: controller.pickManualProof,
                    icon: Icon(
                        controller.manualProof.value == null
                            ? Icons.attach_file
                            : Icons.check_circle,
                        color: controller.manualProof.value == null
                            ? null
                            : AppColors.success),
                    label: Text(controller.manualProof.value == null
                        ? 'Attach mandatory proof'
                        : 'Proof attached'))),
              ])),
              actions: [
                TextButton(onPressed: Get.back, child: const Text('Cancel')),
                FilledButton(
                    onPressed: () {
                      final parsed = double.tryParse(amount.text);
                      if (parsed == null || parsed <= 0) {
                        Get.snackbar(
                            'Invalid amount', 'Enter a valid positive amount.');
                        return;
                      }
                      controller.addManualPayment(
                          userId: selectedUser,
                          amount: parsed,
                          note: note.text);
                    },
                    child: const Text('Record permanently'))
              ],
            )));
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
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CustomText.subtitle(p.userName, color: AppColors.textPrimary),
            const SizedBox(height: 2),
            CustomText.small('${p.month} • ${_formatDate(p.submittedAt)}',
                color: AppColors.textSecondary),
            if (p.note != null && p.note!.isNotEmpty) ...[
              const SizedBox(height: 3),
              CustomText.small(p.note!, color: AppColors.textSecondary),
            ],
            if (p.receiptUrl != null && p.receiptUrl!.isNotEmpty)
              const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.verified_user_outlined,
                    size: 13, color: AppColors.success),
                SizedBox(width: 3),
                Text('Proof attached',
                    style: TextStyle(fontSize: 10, color: AppColors.success)),
              ]),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          CustomText.subtitle('৳${p.amount.toStringAsFixed(0)}',
              color: AppColors.textPrimary),
          const SizedBox(height: 6),
          if (p.isPending)
            CustomButton(
              text: 'Confirm',
              height: 32,
              isFullWidth: false,
              borderRadius: 8,
              backgroundColor: const Color(0xFF15803D),
              textColor: Colors.white,
              onPressed: () => controller.confirmPayment(p.id),
            )
          else
            StatusBadge(status: p.status),
          if (p.receiptUrl != null && p.receiptUrl!.isNotEmpty)
            IconButton(
              tooltip: 'Open payment proof',
              visualDensity: VisualDensity.compact,
              onPressed: () => launchUrl(
                Uri.parse(p.receiptUrl!),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.open_in_new,
                  size: 18, color: AppColors.primary),
            ),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    title: CustomText.body(
                        "Target Month: ${controller.configMonth.value.month}/${controller.configMonth.value.year}"),
                    trailing: const Icon(Icons.calendar_month,
                        color: AppColors.primary),
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

  // --- হেল্পার মেথড ---
  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
