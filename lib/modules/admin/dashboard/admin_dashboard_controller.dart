import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/supabase_service.dart';
import '../../../data/models/models.dart';
import '../../../core/theme/app_theme.dart';

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
}
