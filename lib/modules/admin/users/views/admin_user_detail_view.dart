import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/custom_text.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/services/supabase_service.dart';
import '../controllers/admin_users_controller.dart';

class AdminUserDetailView extends StatelessWidget {
  const AdminUserDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Get.arguments as UserModel;
    final ctrl = Get.find<AdminUsersController>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(children: [
        _buildHeader(user),
        Expanded(
          child: SingleChildScrollView(
            child: Column(children: [
              const SizedBox(height: 16),
              _infoCard(user),
              const SizedBox(height: 12),
              _savingsCard(user),
              const SizedBox(height: 12),
              _monthlyLedger(user),
              const SizedBox(height: 12),
              _actionButtons(user, ctrl),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildHeader(UserModel user) {
    return Container(
      color: AppColors.bgDark,
      padding: EdgeInsets.only(
        top: MediaQuery.of(Get.context!).padding.top + 8,
        left: 18,
        right: 18,
        bottom: 20,
      ),
      child: Column(children: [
        Row(children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          const CustomText.title('User Detail', color: Colors.white),
        ]),
        const SizedBox(height: 20),
        UserAvatar(initials: user.initials, color: AppColors.primary, size: 64),
        const SizedBox(height: 10),
        CustomText.heading(user.name, color: Colors.white),
        const SizedBox(height: 4),
        StatusBadge(status: user.status),
      ]),
    );
  }

  Widget _infoCard(UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderColor)),
        child: Column(children: [
          _row('Phone', user.phone),
          _divider(),
          _row('Email', user.email),
          _divider(),
          _row('Member ID', '#${user.id.substring(0, 6).toUpperCase()}'),
          _divider(),
          _row('Joined',
              '${user.joinedAt.day}/${user.joinedAt.month}/${user.joinedAt.year}'),
        ]),
      ),
    );
  }

  Widget _savingsCard(UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderColor)),
        child: Column(children: [
          _row('Monthly Amount', '৳${user.monthlyAmount.toStringAsFixed(0)}'),
          _divider(),
          _row('Total Saved', '৳${user.totalSaved.toStringAsFixed(0)}'),
          _divider(),
          _row('Dues', '৳${user.dues.toStringAsFixed(0)}',
              valueColor: user.dues > 0 ? AppColors.error : AppColors.success),
        ]),
      ),
    );
  }

  Widget _monthlyLedger(UserModel user) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future:
              SupabaseService.to.getUserPaymentCalendar(targetUserId: user.id),
          builder: (_, snapshot) {
            if (!snapshot.hasData) {
              return const Card(
                  child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Center(child: CircularProgressIndicator())));
            }
            final rows = snapshot.data!;
            return Card(
              child: ExpansionTile(
                title: const Text('Month-by-month ledger',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('${rows.length} tracked months'),
                children: rows.reversed.map((row) {
                  final date = DateTime.parse(row['month'].toString());
                  final status = row['status']?.toString() ?? 'due';
                  final color = status == 'paid'
                      ? AppColors.success
                      : status == 'pending'
                          ? AppColors.warning
                          : status == 'future'
                              ? AppColors.primary
                              : AppColors.error;
                  return ListTile(
                    dense: true,
                    leading: Icon(Icons.calendar_month, color: color),
                    title: Text(
                        '${date.month.toString().padLeft(2, '0')}/${date.year}'),
                    subtitle: Text(
                        'Required ৳${(row['required'] as num? ?? 0).toStringAsFixed(0)} • Paid ৳${(row['confirmed'] as num? ?? 0).toStringAsFixed(0)}'),
                    trailing: Text(status.toUpperCase(),
                        style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w800)),
                  );
                }).toList(),
              ),
            );
          },
        ),
      );

  Widget _actionButtons(UserModel user, AdminUsersController ctrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        if (user.isActive) ...[
          OutlinedButton.icon(
            onPressed: () => _showMonthlyAmountDialog(user, ctrl),
            icon: const Icon(Icons.edit_calendar_outlined),
            label: const CustomText.subtitle('Set Member Monthly Amount'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _showSavingsStartDialog(user, ctrl),
            icon: const Icon(Icons.history),
            label: const CustomText.subtitle('Set Savings Start Month'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (user.isPending) ...[
          ElevatedButton.icon(
            onPressed: () {
              ctrl.approveUser(user.id);
              Get.back();
            },
            icon: const Icon(Icons.check_circle_outline),
            label:
                const CustomText.subtitle('Approve User', color: Colors.white),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              ctrl.rejectUser(user.id);
              Get.back();
            },
            icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
            label: const CustomText.subtitle('Reject User',
                color: AppColors.error),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              side: const BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
        // ... অন্যান্য বাটন গুলোতেও একই ভাবে CustomText যোগ করুন
      ]),
    );
  }

  void _showMonthlyAmountDialog(UserModel user, AdminUsersController ctrl) {
    final amount =
        TextEditingController(text: user.monthlyAmount.toStringAsFixed(0));
    Get.dialog(AlertDialog(
      title: Text('Monthly amount — ${user.name}'),
      content: TextField(
          controller: amount,
          keyboardType: TextInputType.number,
          decoration:
              const InputDecoration(labelText: 'Required amount per month')),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        FilledButton(
            onPressed: () {
              final value = double.tryParse(amount.text);
              if (value == null || value < 0) {
                Get.snackbar(
                    'Invalid amount', 'Enter zero or a positive amount.');
                return;
              }
              ctrl.setMonthlyAmountForUser(user.id, value);
            },
            child: const Text('Save')),
      ],
    ));
  }

  void _showSavingsStartDialog(UserModel user, AdminUsersController ctrl) {
    Get.dialog(AlertDialog(
      title: Text('Savings start — ${user.name}'),
      content: const Text(
          'Select the month this member originally started saving. Old monthly payments can then be entered with proof from the Payments screen.'),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        FilledButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                  context: Get.context!,
                  initialDate: user.joinedAt,
                  firstDate: DateTime(2015),
                  lastDate: DateTime.now());
              if (picked != null) ctrl.setSavingsStart(user.id, picked);
            },
            icon: const Icon(Icons.calendar_month),
            label: const Text('Select month')),
      ],
    ));
  }

  Widget _row(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        CustomText.small(label, color: AppColors.textSecondary),
        CustomText.subtitle(value, color: valueColor ?? AppColors.textPrimary),
      ]),
    );
  }

  Widget _divider() => const Divider(height: 1, color: AppColors.borderColor);
}
