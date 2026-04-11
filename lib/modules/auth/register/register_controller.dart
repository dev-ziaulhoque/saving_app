import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/routes/app_routes.dart';
import '../../../data/services/supabase_service.dart';
import '../../../data/services/auth_service.dart';

class RegisterController extends GetxController {
  final nameController     = TextEditingController();
  final emailController    = TextEditingController();
  final phoneController    = TextEditingController();
  final passwordController = TextEditingController();
  final formKey            = GlobalKey<FormState>();

  final isLoading    = false.obs;
  final documentPath = RxnString();
  final documentName = RxnString();

  final _picker = ImagePicker();

  Future<void> pickDocument() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      documentPath.value = file.path;
      documentName.value = file.name;
    }
  }

  Future<void> register() async {
    if (!formKey.currentState!.validate()) return;
    if (documentPath.value == null) {
      Get.snackbar('Document Required',
          'Please upload your NID or verification document.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFEF4444),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12);
      return;
    }
    isLoading.value = true;

    try {
      // ১. ইনপুট ডেটাগুলো ভেরিয়েবলে সেভ করা হলো
      final String email = emailController.text.trim();
      final String password = passwordController.text;
      final String name = nameController.text.trim();
      final String phone = phoneController.text.trim();
      final String? docPath = documentPath.value;

      // ২. কি কি ইনপুট যাচ্ছে তা কনসোলে প্রিন্ট করে দেখা
      debugPrint('========= Registration Input Data =========');
      debugPrint('Name          : $name');
      debugPrint('Email         : $email');
      debugPrint('Phone         : $phone');
      debugPrint('Password      : $password');
      debugPrint('Document Path : $docPath');
      debugPrint('=============================================');

      // ৩. Supabase এ ডেটা পাঠানো হলো
      final user = await SupabaseService.to.signUp(
        email:        email,
        password:     password,
        name:         name,
        phone:        phone,
        documentFile: File(docPath!),
      );

      // ৪. রেসপন্স প্রিন্ট করে দেখা
      debugPrint('Registration Success Response: $user');

      await AuthService.to.saveSession(user);
      Get.offAllNamed(AppRoutes.PENDING_APPROVAL);

    } catch (e) {
      debugPrint('Registration Failed Error: $e');
      Get.snackbar('Registration Failed',
          e.toString().replaceAll('Exception: ', ''),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFEF4444),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12);
    } finally {
      isLoading.value = false;
    }
  }

  String? validateRequired(String? v) =>
      (v == null || v.isEmpty) ? 'This field is required' : null;
  String? validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Email is required';
    if (!GetUtils.isEmail(v)) return 'Enter a valid email';
    return null;
  }
  String? validatePhone(String? v) {
    if (v == null || v.isEmpty) return 'Phone is required';
    if (v.length < 10) return 'Enter a valid phone number';
    return null;
  }
  String? validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Minimum 6 characters';
    return null;
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}