import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/models/models.dart';
import '../../../core/theme/app_theme.dart';

class AdminUsersController extends GetxController {
  final _api = ApiProvider();

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
      final status = selectedFilter.value == 'all' ? null : selectedFilter.value;
      final res = await _api.getUsers(status: status);
      users.value = (res.data['users'] as List)
          .map((u) => UserModel.fromJson(u))
          .toList();
    } catch (_) {
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
      await _api.blockUser(userId);
      final idx = users.indexWhere((u) => u.id == userId);
      if (idx != -1) {
        users[idx] = users[idx].copyWith(status: 'blocked');
        users.refresh();
      }
      Get.snackbar('Blocked', 'User has been blocked',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12);
    } catch (_) {}
  }

  Future<void> unblockUser(String userId) async {
    try {
      await _api.unblockUser(userId);
      final idx = users.indexWhere((u) => u.id == userId);
      if (idx != -1) {
        users[idx] = users[idx].copyWith(status: 'active');
        users.refresh();
      }
      Get.snackbar('Unblocked', 'User has been unblocked',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12);
    } catch (_) {}
  }

  Future<void> approveUser(String userId) async {
    try {
      await _api.approveUser(userId);
      final idx = users.indexWhere((u) => u.id == userId);
      if (idx != -1) {
        users[idx] = users[idx].copyWith(status: 'active');
        users.refresh();
      }
    } catch (_) {}
  }

  Future<void> rejectUser(String userId) async {
    try {
      await _api.rejectUser(userId);
      final idx = users.indexWhere((u) => u.id == userId);
      if (idx != -1) {
        users[idx] = users[idx].copyWith(status: 'rejected');
        users.refresh();
      }
      Get.snackbar('Rejected', 'User has been rejected',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12);
    } catch (_) {}
  }
}
