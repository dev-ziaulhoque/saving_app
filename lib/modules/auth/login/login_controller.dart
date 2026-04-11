import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../data/services/supabase_service.dart';
import '../../../data/services/auth_service.dart';

class LoginController extends GetxController {
  final emailController    = TextEditingController();
  final passwordController = TextEditingController();
  final formKey            = GlobalKey<FormState>();

  final selectedRole   = 'user'.obs;
  final isLoading      = false.obs;
  final obscurePassword = true.obs;

  void toggleRole(String role) => selectedRole.value = role;
  void toggleObscure() => obscurePassword.value = !obscurePassword.value;

  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;
    isLoading.value = true;

    try {
      // ১. ইনপুট ডেটাগুলো ভেরিয়েবলে সেভ করা হলো
      final String email = emailController.text.trim();
      final String password = passwordController.text;
      final String role = selectedRole.value;

      // ২. কি কি ইনপুট যাচ্ছে তা কনসোলে প্রিন্ট করে দেখা
      debugPrint('========= Login Input Data =========');
      debugPrint('Email    : $email');
      debugPrint('Password : $password');
      debugPrint('Role     : $role');
      debugPrint('====================================');

      // ৩. Supabase এ ডেটা পাঠানো হলো
      final user = await SupabaseService.to.signIn(
        email:    email,
        password: password,
      );

      // ৪. রেসপন্স প্রিন্ট করে দেখা
      debugPrint('Login Success Response: $user');

      // Role check
      if (selectedRole.value == 'admin' && !user.isAdmin) {
        throw Exception('Not an admin account');
      }
      if (selectedRole.value == 'user' && user.isAdmin) {
        throw Exception('Please use admin login');
      }

      await AuthService.to.saveSession(user);

      // ৫. কন্ডিশন অনুযায়ী রাউটিং
      if (user.isPending) {
        Get.offAllNamed(AppRoutes.PENDING_APPROVAL);
      } else if (user.isBlocked) {
        _showError('Your account has been blocked. Contact admin.');
        await SupabaseService.to.signOut();
      } else if (user.isAdmin) {
        Get.offAllNamed(AppRoutes.ADMIN_DASHBOARD);
      } else {
        Get.offAllNamed(AppRoutes.USER_DASHBOARD);
      }
    } catch (e) {
      debugPrint('Login Failed Error: $e');
      _showError(e.toString().contains('Invalid')
          ? 'Invalid email or password.'
          : e.toString().replaceAll('Exception: ', ''));
    } finally {
      isLoading.value = false;
    }
  }

  void _showError(String msg) {
    Get.snackbar('Login Failed', msg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12);
  }

  String? validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Email is required';
    if (!GetUtils.isEmail(v)) return 'Enter a valid email';
    return null;
  }

  String? validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Minimum 6 characters';
    return null;
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}