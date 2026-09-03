import 'dart:async';

import 'package:get/get.dart';

import '../../../data/models/foundation_report_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/supabase_service.dart';
import '../services/foundation_pdf_service.dart';

class FoundationReportController extends GetxController {
  final isLoading = true.obs;
  final isSaving = false.obs;
  final report = Rxn<FoundationReportModel>();
  final investments = <Map<String, dynamic>>[].obs;
  Timer? _refreshTimer;

  bool get isAdmin => AuthService.to.isAdmin;

  @override
  void onInit() {
    super.onInit();
    load();
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 20), (_) => load(silent: true));
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) isLoading.value = true;
    try {
      final current = await SupabaseService.to.getLiveFoundationReport();
      report.value = current;
      investments.assignAll(current.investments);
    } catch (e) {
      if (!silent) Get.snackbar('Could not load live report', e.toString());
    } finally {
      if (!silent) isLoading.value = false;
    }
  }

  Future<void> addInvestment(
      String title, double amount, DateTime date, String? notes) async {
    await _save(() => SupabaseService.to.addInvestment(
        title: title, amount: amount, investedAt: date, notes: notes));
  }

  Future<void> addProfit(
      String investmentId, double amount, DateTime month, String? notes) async {
    await _save(() => SupabaseService.to.addInvestmentProfit(
        investmentId: investmentId,
        amount: amount,
        month: month,
        notes: notes));
  }

  Future<void> addExpense(String title, double amount, DateTime date,
      String category, String? notes) async {
    await _save(() => SupabaseService.to.addFoundationExpense(
        title: title,
        amount: amount,
        expenseDate: date,
        category: category,
        notes: notes));
  }

  Future<void> _save(Future<void> Function() operation) async {
    isSaving.value = true;
    try {
      await operation();
      Get.back();
      await load(silent: true);
      Get.snackbar('Saved', 'Live accounting report updated.');
    } catch (e) {
      Get.snackbar('Save failed', e.toString());
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> downloadPdf() async {
    final value = report.value;
    if (value == null) return;
    try {
      await FoundationPdfService.share(value);
    } catch (e) {
      Get.snackbar('PDF failed', e.toString());
    }
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }
}
