import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../data/services/supabase_service.dart';

class PaymentRequestController extends GetxController {
  final amountCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final availableMonths = <Map<String, dynamic>>[].obs;
  final selectedMonthKeys = <String>{}.obs;
  final amountVersion = 0.obs;
  final receiptImage = Rxn<File>();
  final isLoading = false.obs;
  final _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    final user = AuthService.to.currentUser.value;
    if ((user?.monthlyAmount ?? 0) > 0)
      amountCtrl.text = user!.monthlyAmount.toStringAsFixed(0);
    phoneCtrl.text = user?.phone ?? '';
    amountCtrl.addListener(_amountChanged);
    loadAvailableMonths();
  }

  void _amountChanged() => amountVersion.value++;
  String _key(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';
  List<DateTime> get selectedMonths => availableMonths
      .where((r) => selectedMonthKeys.contains(r['key']))
      .map((r) => r['date'] as DateTime)
      .toList()
    ..sort();
  double get amountPerMonth => double.tryParse(amountCtrl.text.trim()) ?? 0;
  double get totalAmount => amountPerMonth * selectedMonthKeys.length;

  Future<void> loadAvailableMonths() async {
    try {
      final rows = await SupabaseService.to.getUserPaymentCalendar();
      final options = <Map<String, dynamic>>[];
      for (final row in rows) {
        if (row['status'] == 'paid' || row['status'] == 'pending') continue;
        final date = DateTime.parse(row['month'].toString()).toLocal();
        options.add({...row, 'date': date, 'key': _key(date)});
      }
      final now = DateTime.now();
      for (var i = 1; i <= 12; i++) {
        final date = DateTime(now.year, now.month + i, 1);
        if (!options.any((r) => r['key'] == _key(date)))
          options.add({'date': date, 'key': _key(date), 'status': 'future'});
      }
      options.sort(
          (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
      availableMonths.assignAll(options);
      if (selectedMonthKeys.isEmpty && options.isNotEmpty)
        selectedMonthKeys.add(options.first['key'] as String);
    } catch (e) {
      Get.snackbar('Error', 'Could not load unpaid months: $e');
    }
  }

  void toggleMonth(String key) {
    if (selectedMonthKeys.contains(key))
      selectedMonthKeys.remove(key);
    else if (selectedMonthKeys.length < 24) selectedMonthKeys.add(key);
  }

  String monthLabel(DateTime d) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${names[d.month - 1]} ${d.year}';
  }

  String get formattedMonth => selectedMonths.isEmpty
      ? 'Select unpaid months'
      : selectedMonths.length == 1
          ? monthLabel(selectedMonths.first)
          : '${selectedMonths.length} months selected';

  Future<void> pickImage() async {
    final image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) receiptImage.value = File(image.path);
  }

  Future<void> submitPayment() async {
    final amount = double.tryParse(amountCtrl.text.trim());
    if (amount == null || amount <= 0 || phoneCtrl.text.trim().isEmpty) {
      Get.snackbar('Error', 'Enter valid amount and phone number');
      return;
    }
    if (selectedMonths.isEmpty) {
      Get.snackbar('Select month', 'Select at least one unpaid month.');
      return;
    }
    try {
      isLoading.value = true;
      await SupabaseService.to.requestPayment(
          months: selectedMonths,
          amountPerMonth: amount,
          phone: phoneCtrl.text.trim(),
          receiptFile: receiptImage.value);
      Get.back();
      Get.snackbar('Success',
          '${selectedMonths.length} month payment request submitted!',
          backgroundColor: AppColors.success, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Upload failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    amountCtrl.removeListener(_amountChanged);
    amountCtrl.dispose();
    phoneCtrl.dispose();
    super.onClose();
  }
}
