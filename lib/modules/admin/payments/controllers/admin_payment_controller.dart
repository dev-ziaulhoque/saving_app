import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/services/supabase_service.dart';

class AdminPaymentsController extends GetxController {
  final isLoading = false.obs;
  final payments = <TransactionModel>[].obs;
  final selectedFilter = 'all'.obs;
  final users = <UserModel>[].obs;
  final manualProof = Rxn<File>();
  final manualMonth = DateTime.now().obs;
  final manualMonthCount = 1.obs;
  final manualAvailableMonths = <Map<String, dynamic>>[].obs;
  final manualSelectedMonthKeys = <String>{}.obs;

  final totalConfirmed = 0.0.obs;
  final totalPending = 0.0.obs;
  final totalEntries = 0.obs;

  // --- Monthly Config Variables (ডায়ালগের জন্য) ---
  final configAmountCtrl = TextEditingController();
  final configTitleCtrl =
      TextEditingController(text: 'Regular Monthly Funding');
  final configMonth = DateTime.now().obs;
  final isSpecial = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPayments();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    users.assignAll(await SupabaseService.to.getUsers(status: 'active'));
  }

  Future<void> pickManualProof() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) manualProof.value = File(picked.path);
  }

  String monthKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';
  String monthLabel(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
  List<DateTime> get manualSelectedMonths => manualAvailableMonths
      .where((r) => manualSelectedMonthKeys.contains(r['key']))
      .map((r) => r['date'] as DateTime)
      .toList()
    ..sort();

  Future<void> loadManualMonths(String userId) async {
    final rows =
        await SupabaseService.to.getUserPaymentCalendar(targetUserId: userId);
    final options = <Map<String, dynamic>>[];
    for (final row in rows) {
      if (row['status'] == 'paid' || row['status'] == 'pending') continue;
      final date = DateTime.parse(row['month'].toString()).toLocal();
      options.add({...row, 'date': date, 'key': monthKey(date)});
    }
    final now = DateTime.now();
    for (var i = 1; i <= 12; i++) {
      final date = DateTime(now.year, now.month + i, 1);
      if (!options.any((r) => r['key'] == monthKey(date)))
        options.add({'date': date, 'key': monthKey(date), 'status': 'future'});
    }
    options.sort(
        (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    manualAvailableMonths.assignAll(options);
    manualSelectedMonthKeys.clear();
    if (options.isNotEmpty)
      manualSelectedMonthKeys.add(options.first['key'] as String);
  }

  void toggleManualMonth(String key) {
    manualSelectedMonthKeys.contains(key)
        ? manualSelectedMonthKeys.remove(key)
        : manualSelectedMonthKeys.add(key);
  }

  Future<void> addManualPayment({
    required String userId,
    required double amount,
    required String note,
  }) async {
    final proof = manualProof.value;
    if (proof == null) {
      Get.snackbar('Proof required', 'Attach a receipt or written proof.');
      return;
    }
    if (note.trim().length < 5) {
      Get.snackbar('Note required', 'Write a clear reason/source.');
      return;
    }
    if (manualSelectedMonths.isEmpty) {
      Get.snackbar('Month required', 'Select at least one unpaid month.');
      return;
    }
    isLoading.value = true;
    try {
      await SupabaseService.to.addManualPaymentAdmin(
        targetUserId: userId,
        amount: amount,
        months: manualSelectedMonths,
        proofFile: proof,
        note: note.trim(),
      );
      manualProof.value = null;
      Get.back();
      await fetchPayments();
      Get.snackbar(
          'Recorded', 'Manual payment and proof are permanently recorded.',
          backgroundColor: AppColors.success, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Manual entry failed', e.toString(),
          backgroundColor: AppColors.error, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // ১. পেমেন্ট রিকোয়েস্ট লিস্ট লোড করা
  Future<void> fetchPayments() async {
    isLoading.value = true;
    try {
      final status =
          selectedFilter.value == 'all' ? null : selectedFilter.value;
      final data = await SupabaseService.to.getAllPayments(status: status);
      payments.assignAll(data);
      final all =
          status == null ? data : await SupabaseService.to.getAllPayments();
      totalConfirmed.value = all
          .where((payment) => payment.isConfirmed)
          .fold(0, (sum, payment) => sum + payment.amount);
      totalPending.value = all
          .where((payment) => payment.isPending)
          .fold(0, (sum, payment) => sum + payment.amount);
      totalEntries.value = all.length;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load payments: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ফিল্টার পরিবর্তন করা (All, Pending, Confirmed)
  void setFilter(String f) {
    selectedFilter.value = f;
    fetchPayments();
  }

  // ২. নির্দিষ্ট মাসের জন্য টাকা ফিক্স করা (Config)
  Future<void> saveMonthConfig() async {
    if (configAmountCtrl.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter amount',
          backgroundColor: AppColors.error, colorText: Colors.white);
      return;
    }

    try {
      isLoading.value = true;
      await SupabaseService.to.setMonthRequirement(
        configMonth.value,
        double.parse(configAmountCtrl.text.trim()),
        configTitleCtrl.text.trim(),
        isSpecial.value,
      );

      Get.back(); // ডায়ালগ বন্ধ
      Get.snackbar('Success ✅',
          'Funding rule saved for ${_formatMonth(configMonth.value)}',
          backgroundColor: AppColors.success, colorText: Colors.white);

      // ফিল্ড রিসেট
      configAmountCtrl.clear();
      isSpecial.value = false;
    } catch (e) {
      Get.snackbar('Error', 'Failed to save config: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ৩. ইউজারের পেমেন্ট কনফার্ম করা
  Future<void> confirmPayment(String paymentId) async {
    try {
      await SupabaseService.to.confirmPayment(paymentId);

      // লোকাল লিস্ট আপডেট করা
      final idx = payments.indexWhere((p) => p.id == paymentId);
      if (idx != -1) {
        payments[idx] = payments[idx].copyWith(status: 'confirmed');
        payments.refresh();
      }

      Get.snackbar('Confirmed ✅', 'Payment approved and ledger updated',
          backgroundColor: AppColors.success, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Approval failed: $e');
    }
  }

  // ৪. মান্থলি রিপোর্ট ডাউনলোড (CSV Export)
  Future<void> downloadReport(DateTime month) async {
    try {
      isLoading.value = true;

      // সুপাবেস RPC থেকে ওই মাসের সব ইউজারের ডাটা আনা
      final List<dynamic> reportData =
          await SupabaseService.to.getMonthlyReport(month);

      if (reportData.isEmpty) {
        Get.snackbar('Empty', 'No user data found for this month',
            backgroundColor: AppColors.warning);
        return;
      }

      // CSV ফরম্যাটে ডেটা সাজানো
      List<List<dynamic>> csvRows = [];
      // Header row
      csvRows.add(
          ["User Name", "Phone", "Target Amount", "Paid Amount", "Status"]);

      for (var item in reportData) {
        csvRows.add([
          item['user_name'] ?? 'N/A',
          item['phone'] ?? 'N/A',
          item['required_amount'] ?? 0,
          item['paid_amount'] ?? 0,
          item['status'] ?? 'Unpaid',
        ]);
      }

      // CSV স্ট্রিং তৈরি
      String csvString = const ListToCsvConverter().convert(csvRows);

      // ফাইল সিস্টেমে সেভ করা
      final directory = await getTemporaryDirectory();
      final String fileName =
          "Funding_Report_${_formatMonth(month).replaceAll(' ', '_')}.csv";
      final File file = File('${directory.path}/$fileName');

      await file.writeAsString(csvString);

      // শেয়ার বা ডাউনলোড অপশন দেখানো
      await Share.shareXFiles([XFile(file.path)],
          text: 'Payment Report for ${_formatMonth(month)}');
    } catch (e) {
      Get.snackbar('Error', 'Report generation failed: $e',
          backgroundColor: AppColors.error, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // হেল্পার: মাসের নাম ফরম্যাট করা
  String _formatMonth(DateTime d) {
    const months = [
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
    return "${months[d.month - 1]} ${d.year}";
  }

  @override
  void onClose() {
    configAmountCtrl.dispose();
    configTitleCtrl.dispose();
    super.onClose();
  }
}
