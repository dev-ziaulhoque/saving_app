import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import 'register_controller.dart';

class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Join SaveSmart',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Fill in your details and upload a verification document.',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              _buildField(
                controller: controller.nameController,
                label: 'Full Name',
                icon: Icons.person_outline,
                validator: controller.validateRequired,
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: controller.phoneController,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                validator: controller.validatePhone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: controller.emailController,
                label: 'Email Address',
                icon: Icons.email_outlined,
                validator: controller.validateEmail,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: controller.passwordController,
                label: 'Password',
                icon: Icons.lock_outline,
                validator: controller.validatePassword,
                obscure: true,
              ),
              const SizedBox(height: 20),

              // Document Upload
              const Text(
                'Verification Document (NID / Passport)',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Obx(() => GestureDetector(
                onTap: controller.pickDocument,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: controller.documentPath.value != null
                          ? AppColors.primary
                          : AppColors.borderColor,
                      style: BorderStyle.solid,
                      width: controller.documentPath.value != null ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        controller.documentPath.value != null
                            ? Icons.check_circle_outline
                            : Icons.upload_file_outlined,
                        color: controller.documentPath.value != null
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        controller.documentName.value ?? 'Tap to upload document',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: controller.documentPath.value != null
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                      if (controller.documentPath.value == null)
                        const Text(
                          'JPG, PNG, PDF supported',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                    ],
                  ),
                ),
              )),
              const SizedBox(height: 28),

              Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value ? null : controller.register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Submit for Approval',
                          style: TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              )),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      keyboardType: keyboardType,
      style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
      ),
    );
  }
}
