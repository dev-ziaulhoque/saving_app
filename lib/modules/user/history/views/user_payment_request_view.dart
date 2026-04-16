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
          const CustomText.small('Submit info after paying hand cash to admin.', color: AppColors.textSecondary),
          const SizedBox(height: 24),

          CustomTextField(
            controller: controller.amountCtrl,
            hint: 'Amount (৳)',
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
          const CustomText.label('Payment Month', color: AppColors.textSecondary),
          const SizedBox(height: 8),
          Obx(() => InkWell(
            onTap: () => controller.selectMonth(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_outlined, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  CustomText.body(controller.formattedMonth),
                  const Spacer(),
                  const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                ],
              ),
            ),
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
                  ? const Icon(Icons.add_a_photo_outlined, color: AppColors.textHint, size: 30)
                  : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(controller.receiptImage.value!, fit: BoxFit.cover),
              ),
            ),
          )),

          const SizedBox(height: 30),

          Obx(() => SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: controller.isLoading.value ? null : controller.submitPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: controller.isLoading.value
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const CustomText.subtitle('Submit Request', color: Colors.white),
            ),
          )),
        ]),
      ),
    );
  }
}