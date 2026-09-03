/*import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/services/supabase_service.dart';
import '../../../../data/models/models.dart';
import '../../../../core/theme/app_theme.dart';

class AdminDashboardController extends GetxController {
  final isLoading       = false.obs;
  final totalUsers      = 0.obs;
  final totalCollected  = 0.0.obs;
  final pendingAmount   = 0.0.obs;
  final newRequests     = 0.obs;
  final pendingUsers    = <UserModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    isLoading.value = true;
    try {
      // Stats
      final stats = await SupabaseService.to.getAdminStats();
      totalUsers.value     = stats['total_users'] ?? 0;
      totalCollected.value = (stats['total_collected'] ?? 0).toDouble();
      pendingAmount.value  = (stats['pending_amount'] ?? 0).toDouble();
      newRequests.value    = stats['new_requests'] ?? 0;

      // Pending approval users
      pendingUsers.value = await SupabaseService.to.getUsers(status: 'pending');
    } catch (e) {
      Get.snackbar('Error', 'Failed to load dashboard',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> approveUser(String userId) async {
    try {
      await SupabaseService.to.approveUser(userId);
      pendingUsers.removeWhere((u) => u.id == userId);
      newRequests.value = (newRequests.value - 1).clamp(0, 9999);
      Get.snackbar('Approved ✅', 'User approved successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12);
    } catch (_) {}
  }

  Future<void> rejectUser(String userId) async {
    try {
      await SupabaseService.to.rejectUser(userId);
      pendingUsers.removeWhere((u) => u.id == userId);
      newRequests.value = (newRequests.value - 1).clamp(0, 9999);
    } catch (_) {}
  }
}*/


import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/services/supabase_service.dart';
import '../../../../core/theme/app_theme.dart';

class AdminDashboardController extends GetxController {
  final isLoading = false.obs;

  // Stats
  final totalUsers = 0.obs;
  final totalCollected = 0.0.obs;
  final pendingAmount = 0.0.obs;
  final newRequests = 0.obs;
  final pendingUsers = <UserModel>[].obs;

  // All active users list for special charge
  final allActiveUsers = <UserModel>[].obs;

  // Special Charge Controllers
  final chargeTitleCtrl = TextEditingController();
  final chargeAmountCtrl = TextEditingController();
  final isGlobalCharge = true.obs;
  final selectedUserForCharge = Rxn<UserModel>(); // নির্দিষ্ট ইউজার সিলেক্ট করার জন্য

  @override
  void onInit() {
    super.onInit();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    isLoading.value = true;
    try {
      // ১. ড্যাশবোর্ড স্ট্যাটাস আনা
      final stats = await SupabaseService.to.getAdminStats();
      totalUsers.value = stats['total_users'] ?? 0;
      totalCollected.value = (stats['total_collected'] ?? 0).toDouble();
      pendingAmount.value = (stats['pending_amount'] ?? 0).toDouble();
      newRequests.value = stats['new_requests'] ?? 0;

      // ২. পেন্ডিং ইউজার লিস্ট আনা
      pendingUsers.value = await SupabaseService.to.getUsers(status: 'pending');

      // ৩. সব অ্যাক্টিভ ইউজার আনা (চার্জ দেওয়ার জন্য)
      allActiveUsers.value = await SupabaseService.to.getUsers(status: 'active');
    } catch (e) {
      Get.snackbar('Error', 'Failed to load dashboard');
    } finally {
      isLoading.value = false;
    }
  }

  void submitSpecialCharge() async {
    // ভ্যালিডেশন
    if (chargeTitleCtrl.text.isEmpty || chargeAmountCtrl.text.isEmpty) {
      Get.snackbar('Error', 'Reason and Amount are required',
          backgroundColor: AppColors.error, colorText: Colors.white);
      return;
    }

    if (!isGlobalCharge.value && selectedUserForCharge.value == null) {
      Get.snackbar('Error', 'Please select a user',
          backgroundColor: AppColors.error, colorText: Colors.white);
      return;
    }

    try {
      isLoading.value = true;

      await SupabaseService.to.applySpecialCharge(
        title: chargeTitleCtrl.text.trim(),
        amount: double.parse(chargeAmountCtrl.text.trim()),
        userId: isGlobalCharge.value ? null : selectedUserForCharge.value?.id,
      );

      Get.back(); // পপ-আপ বন্ধ
      fetchDashboard(); // ডাটা রিফ্রেশ

      Get.snackbar('Success ✅', 'Special charge applied successfully',
          backgroundColor: AppColors.success, colorText: Colors.white);

      // রিসেট
      chargeTitleCtrl.clear();
      chargeAmountCtrl.clear();
      selectedUserForCharge.value = null;
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // ইউজারদের অ্যাপ্রুভ/রিজেক্ট লজিক (আগে যা ছিল)
  Future<void> approveUser(String userId) async {
    await SupabaseService.to.approveUser(userId);
    fetchDashboard();
  }

  Future<void> rejectUser(String userId) async {
    await SupabaseService.to.rejectUser(userId);
    fetchDashboard();
  }
}
