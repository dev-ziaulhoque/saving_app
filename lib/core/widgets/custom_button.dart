import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'custom_text.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final bool isFullWidth;
  final bool isOutlined;
  final double height;
  final double borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.isFullWidth = true,
    this.isOutlined = false,
    this.height = 50,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    // আউটলাইন বাটন হলে একরকম স্টাইল, আর সাধারণ বাটন হলে অন্যরকম
    final buttonStyle = isOutlined
        ? OutlinedButton.styleFrom(
      side: BorderSide(color: backgroundColor ?? AppColors.primary, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
      minimumSize: Size(isFullWidth ? double.infinity : 0, height),
    )
        : ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? AppColors.primary,
      foregroundColor: textColor ?? Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
      minimumSize: Size(isFullWidth ? double.infinity : 0, height),
    );

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height,
      child: isOutlined
          ? OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle,
        child: _buildContent(),
      )
          : ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle,
        child: _buildContent(),
      ),
    );
  }

  // বাটনের ভেতরে কি থাকবে (টেক্সট নাকি লোডার)
  Widget _buildContent() {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: isOutlined ? (backgroundColor ?? AppColors.primary) : Colors.white,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: 8),
        ],
        CustomText.subtitle(
          text,
          color: isOutlined ? (backgroundColor ?? AppColors.primary) : (textColor ?? Colors.white),
        ),
      ],
    );
  }
}