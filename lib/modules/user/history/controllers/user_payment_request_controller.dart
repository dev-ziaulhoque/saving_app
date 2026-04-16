import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../data/services/supabase_service.dart';
import '../../../../core/theme/app_theme.dart';

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/services/supabase_service.dart';

class PaymentRequestController extends GetxController {
  final amountCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

  // ডেট পিকারের জন্য ভেরিয়েবল
  final selectedDate = DateTime.now().obs;

  final receiptImage = Rxn<File>();
  final isLoading = false.obs;
  final _picker = ImagePicker();

  // মাসের নাম ফরম্যাট করা (যেমন: October 2025)
  String get formattedMonth {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return "${months[selectedDate.value.month - 1]} ${selectedDate.value.year}";
  }

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      receiptImage.value = File(image.path);
    }
  }

  // ডেট পিকার ওপেন করা
  Future<void> selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      helpText: 'Select Payment Month',
    );
    if (picked != null && picked != selectedDate.value) {
      selectedDate.value = picked;
    }
  }

  Future<void> submitPayment() async {
    if (amountCtrl.text.isEmpty || phoneCtrl.text.isEmpty) {
      Get.snackbar('Error', 'Please fill all required fields');
      return;
    }

    try {
      isLoading.value = true;
      await SupabaseService.to.requestPayment(
        amount: double.parse(amountCtrl.text.trim()),
        month: formattedMonth, // ফরম্যাটেড মাস পাঠানো হচ্ছে
        phone: phoneCtrl.text.trim(),
        receiptFile: receiptImage.value,
      );

      Get.back();
      Get.snackbar('Success ✅', 'Payment request submitted!',
          backgroundColor: AppColors.success, colorText: Colors.white);

    } catch (e) {
      debugPrint("upload error is $e");
      Get.snackbar('Error', 'Upload failed: $e');
    } finally {
      isLoading.value = false;
    }
  }
}