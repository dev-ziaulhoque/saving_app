import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/services/supabase_service.dart'; // ApiProvider বদলে SupabaseService
import '../../../../core/theme/app_theme.dart';

class AdminUsersController extends GetxController {
  final isLoading = false.obs;
  final users = <UserModel>[].obs;
  final selectedFilter = 'all'.obs;

  final filters = ['all', 'active', 'pending', 'blocked'];

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg != null) selectedFilter.value = arg as String;
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    isLoading.value = true;
    try {
      final status =
          selectedFilter.value == 'all' ? null : selectedFilter.value;
      // Supabase থেকে ডাটা ফেচ করা হচ্ছে
      final List<UserModel> fetchedUsers =
          await SupabaseService.to.getUsers(status: status);
      users.assignAll(fetchedUsers);
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch users',
          backgroundColor: AppColors.error, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  void setFilter(String f) {
    selectedFilter.value = f;
    fetchUsers();
  }

  Future<void> blockUser(String userId) async {
    try {
      await SupabaseService.to.blockUser(userId); // Supabase Call
      _updateLocalUserStatus(userId, 'blocked');
      Get.snackbar('Blocked', 'User has been blocked',
          backgroundColor: AppColors.error, colorText: Colors.white);
    } catch (_) {}
  }

  Future<void> unblockUser(String userId) async {
    try {
      await SupabaseService.to.unblockUser(userId); // Supabase Call
      _updateLocalUserStatus(userId, 'active');
      Get.snackbar('Unblocked', 'User has been unblocked',
          backgroundColor: AppColors.success, colorText: Colors.white);
    } catch (_) {}
  }

  Future<void> approveUser(String userId) async {
    try {
      await SupabaseService.to.approveUser(userId); // Supabase Call
      _updateLocalUserStatus(userId, 'active');
      Get.snackbar('Approved', 'User approved successfully',
          backgroundColor: AppColors.success, colorText: Colors.white);
    } catch (_) {}
  }

  Future<void> rejectUser(String userId) async {
    try {
      await SupabaseService.to.rejectUser(userId); // Supabase Call
      _updateLocalUserStatus(userId, 'rejected');
    } catch (_) {}
  }

  Future<void> setMonthlyAmountForUser(String userId, double amount) async {
    try {
      await SupabaseService.to.setMonthlyAmount(userId, amount);
      final idx = users.indexWhere((u) => u.id == userId);
      if (idx != -1) {
        users[idx] = users[idx].copyWith(monthlyAmount: amount);
        users.refresh();
      }
      Get.back();
      Get.snackbar('Updated',
          'Member monthly amount is now ৳${amount.toStringAsFixed(0)}',
          backgroundColor: AppColors.success, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Update failed', e.toString(),
          backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  Future<void> setSavingsStart(String userId, DateTime startDate) async {
    try {
      await SupabaseService.to.setUserSavingsStart(userId, startDate);
      Get.back();
      Get.snackbar('Updated', 'Savings history start month updated.',
          backgroundColor: AppColors.success, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Update failed', e.toString(),
          backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  void _updateLocalUserStatus(String userId, String status) {
    final idx = users.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      users[idx] = users[idx].copyWith(status: status);
      users.refresh();
    }
  }
}
