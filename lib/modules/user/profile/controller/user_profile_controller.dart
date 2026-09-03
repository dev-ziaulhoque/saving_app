import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../data/services/supabase_service.dart';

class UserProfileController extends GetxController {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  final isEditing = false.obs;
  final isSaving = false.obs;

  final Rx<File?> selectedImage = Rx<File?>(null);
  final _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    _fillFields();
  }

  void _fillFields() {
    final user = AuthService.to.currentUser.value;
    nameController.text = user?.name ?? '';
    phoneController.text = user?.phone ?? '';
  }

  void toggleEdit() {
    if (isEditing.value) {
      selectedImage.value = null;
      _fillFields();
    }
    isEditing.value = !isEditing.value;
  }

  Future<void> pickImage() async {
    if (!isEditing.value) return;
    final XFile? image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) selectedImage.value = File(image.path);
  }

  Future<void> saveProfile() async {
    final currentUser = AuthService.to.currentUser.value;
    if (currentUser == null || nameController.text.trim().isEmpty) return;

    isSaving.value = true;
    try {
      final updatedUser = await SupabaseService.to.updateProfile(
        uid: currentUser.id,
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        avatarFile: selectedImage.value,
      );

      // লোকাল স্টেট আপডেট
      await AuthService.to.updateUser(updatedUser);

      isEditing.value = false;
      selectedImage.value = null;

      Get.snackbar('Success', 'Profile updated successfully',
          backgroundColor: AppColors.success, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', e.toString(),
          backgroundColor: AppColors.error, colorText: Colors.white);
    } finally {
      isSaving.value = false;
    }
  }
}
