/*

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_text.dart';
import '../../../../data/models/models.dart';

void _showSpecialChargeDialog(BuildContext context) {
  Get.dialog(
    Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomText.title('Add Special Charge'),
            const SizedBox(height: 4),*/
/**//*

            const CustomText.small('Manual charge to increase user dues.', color: AppColors.textSecondary),
            const SizedBox(height: 20),

            // --- Toggle: Global or Single ---
            Obx(() => Row(
              children: [
                Expanded(
                  child: _selectBtn('All Users', controller.isGlobalCharge.value,
                          () => controller.isGlobalCharge.value = true),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _selectBtn('Single User', !controller.isGlobalCharge.value,
                          () => controller.isGlobalCharge.value = false),
                ),
              ],
            )),

            const SizedBox(height: 20),

            // --- User Selection (Show only if not global) ---
            Obx(() => controller.isGlobalCharge.value
                ? const SizedBox.shrink()
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CustomText.label('Select User'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<UserModel>(
                      isExpanded: true,
                      hint: const CustomText.small('Choose a member'),
                      value: controller.selectedUserForCharge.value,
                      items: controller.allActiveUsers.map((user) {
                        return DropdownMenuItem(
                          value: user,
                          child: CustomText.small(user.name),
                        );
                      }).toList(),
                      onChanged: (val) => controller.selectedUserForCharge.value = val,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            )),

            _buildDialogField(controller.chargeTitleCtrl, 'Reason (e.g. Picnic, Late Fee)', Icons.description_outlined),
            const SizedBox(height: 12),
            _buildDialogField(controller.chargeAmountCtrl, 'Amount (৳)', Icons.payments_outlined, isNumber: true),

            const SizedBox(height: 24),

            // --- Buttons ---
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const CustomText.body('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() => ElevatedButton(
                  onPressed: controller.isLoading.value ? null : controller.submitSpecialCharge,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const CustomText.body('Apply Charge', color: Colors.white),
                )),
              ),
            ]),
          ],
        ),
      ),
    ),
  );
}

Widget _selectBtn(String label, bool active, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: active ? null : Border.all(color: AppColors.borderColor),
      ),
      child: Center(
        child: CustomText.label(label, color: active ? Colors.white : AppColors.textSecondary),
      ),
    ),
  );
}

Widget _buildDialogField(TextEditingController ctrl, String hint, IconData icon, {bool isNumber = false}) {
  return TextField(
    controller: ctrl,
    keyboardType: isNumber ? TextInputType.number : TextInputType.text,
    style: const TextStyle(fontFamily: 'Nunito', fontSize: 14),
    decoration: InputDecoration(
      prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint),
      filled: true,
      fillColor: AppColors.surface2,
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    ),
  );
}*/
