import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/custom_Texxt_filed.dart';
import '../../../../core/widgets/custom_text.dart';
import '../controllers/user_payment_request_controller.dart';

class PaymentRequestView extends GetView<PaymentRequestController> {
  const PaymentRequestView({super.key});

  @override
  Widget build(BuildContext context) {
    // কন্ট্রোলার ইনিশিয়ালাইজেশন
    if (!Get.isRegistered<PaymentRequestController>()) {
      Get.put(PaymentRequestController());
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const DarkTopBar(title: 'Submit Payment', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const CustomText.title('Hand Cash Payment'),
          const SizedBox(height: 4),
          const CustomText.small('Submit info after paying hand cash to admin.',
              color: AppColors.textSecondary),
          const SizedBox(height: 24),

          CustomTextField(
            controller: controller.amountCtrl,
            hint: 'Amount per month (৳)',
            prefixIcon: Icons.payments_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          CustomTextField(
            controller: controller.phoneCtrl,
            hint: 'Your Phone Number',
            prefixIcon: Icons.phone_android_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),

          // --- Date Picker Field ---
          const CustomText.label('Payment Month',
              color: AppColors.textSecondary),
          const SizedBox(height: 8),
          Obx(() => InkWell(
                onTap: null,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_outlined,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      CustomText.body(controller.formattedMonth),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down,
                          color: AppColors.textSecondary),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 14),

          Obx(() => Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderColor)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CustomText.label('Select unpaid / future months'),
                      const SizedBox(height: 8),
                      if (controller.availableMonths.isEmpty)
                        const CustomText.small('No unpaid month available')
                      else
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: controller.availableMonths.map((row) {
                            final date = row['date'] as DateTime;
                            final key = row['key'] as String;
                            final selected =
                                controller.selectedMonthKeys.contains(key);
                            return FilterChip(
                              selected: selected,
                              label: Text(controller.monthLabel(date)),
                              onSelected: (_) => controller.toggleMonth(key),
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
                        ),
                      const SizedBox(height: 10),
                      Obx(() {
                        controller.amountVersion.value;
                        return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total request',
                                  style: TextStyle(
                                      color: AppColors.textSecondary)),
                              Text(
                                  '৳${controller.totalAmount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary)),
                            ]);
                      }),
                    ]),
              )),
          const SizedBox(height: 20),

          const CustomText.label('Receipt / Screenshot (Optional)'),
          const SizedBox(height: 8),
          Obx(() => GestureDetector(
                onTap: controller.pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: controller.receiptImage.value == null
                      ? const Icon(Icons.add_a_photo_outlined,
                          color: AppColors.textHint, size: 30)
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(controller.receiptImage.value!,
                              fit: BoxFit.cover),
                        ),
                ),
              )),

          const SizedBox(height: 30),

          Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.submitPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const CustomText.subtitle('Submit Request',
                          color: Colors.white),
                ),
              )),
        ]),
      ),
    );
  }
}
