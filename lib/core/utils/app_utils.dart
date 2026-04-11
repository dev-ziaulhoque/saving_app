import 'package:intl/intl.dart';

class AppUtils {
  /// Format currency in BDT
  static String formatBDT(double amount) {
    if (amount >= 100000) return '৳${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '৳${(amount / 1000).toStringAsFixed(1)}K';
    return '৳${amount.toStringAsFixed(0)}';
  }

  /// Format date as dd MMM yyyy
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  /// Format date as dd/MM/yyyy
  static String formatDateShort(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Time ago string
  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatDate(date);
  }

  /// Get initials from full name
  static String getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (name.length >= 2) return name.substring(0, 2).toUpperCase();
    return name.toUpperCase();
  }

  /// Validate email
  static bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  /// Validate Bangladesh phone
  static bool isValidBDPhone(String phone) {
    return RegExp(r'^(\+8801|8801|01)[3-9]\d{8}$').hasMatch(phone);
  }

  /// Current month string
  static String currentMonth() {
    return DateFormat('MMMM yyyy').format(DateTime.now());
  }
}
