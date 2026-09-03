import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/count_badge.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../data/services/badge_service.dart';
import '../controllers/admin_dashboard_controller.dart';

class AdminDashboardView extends GetView<AdminDashboardController> {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () => _showSpecialChargeDialog(context),
      //   backgroundColor: AppColors.primary,
      //   icon: const Icon(Icons.add, color: Colors.white),
      //   label: const CustomText.body('Special Charge', color: Colors.white),
      // ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Obx(() => controller.isLoading.value
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : RefreshIndicator(
                    onRefresh: controller.fetchDashboard,
                    color: AppColors.primary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatCards(),
                          _buildAccountingShortcut(),
                          SectionHeader(
                            title: 'Approval Requests',
                            actionText: 'See All',
                            onAction: () => Get.toNamed(AppRoutes.ADMIN_USERS,
                                arguments: 'pending'),
                          ),
                          Obx(() => controller.pendingUsers.isEmpty
                              ? const EmptyState(
                                  icon: '✅',
                                  title: 'No pending requests',
                                  subtitle:
                                      'All user registrations have been reviewed.',
                                )
                              : Column(
                                  children: controller.pendingUsers
                                      .take(5)
                                      .map((u) => _pendingUserItem(u))
                                      .toList(),
                                )),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  )),
          ),
          _buildBottomNav(0),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.bgDark,
      padding: EdgeInsets.only(
        top: MediaQuery.of(Get.context!).padding.top + 12,
        left: 18,
        right: 18,
        bottom: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Admin Panel',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            Text('Welcome back, Admin',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.5))),
          ]),
          PopupMenuButton(
            child: const UserAvatar(initials: 'AD', color: AppColors.primary),
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'accounting', child: Text('Foundation Accounting')),
              const PopupMenuItem(value: 'audit', child: Text('Audit Logs')),
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
            onSelected: (v) async {
              if (v == 'accounting') {
                Get.toNamed(AppRoutes.ADMIN_ACCOUNTING);
              }
              if (v == 'audit') {
                Get.toNamed(AppRoutes.ADMIN_AUDIT);
              }
              if (v == 'logout') {
                await AuthService.to.logout();
                Get.offAllNamed(AppRoutes.LOGIN);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    return Obx(() => Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              _statCard('Total Users', '${controller.totalUsers.value}',
                  'Active members', AppColors.cardBlue, Icons.people_outline),
              _statCard(
                  'Total Collected',
                  '৳${_fmt(controller.totalCollected.value)}',
                  'This year',
                  AppColors.cardGreen,
                  Icons.account_balance_wallet_outlined),
              _statCard(
                  'Pending',
                  '৳${_fmt(controller.pendingAmount.value)}',
                  'Awaiting confirm',
                  AppColors.cardAmber,
                  Icons.pending_outlined),
              _statCard(
                  'New Requests',
                  '${controller.newRequests.value}',
                  'Awaiting approval',
                  AppColors.cardPurple,
                  Icons.person_add_outlined),
            ],
          ),
        ));
  }

  Widget _buildAccountingShortcut() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Get.toNamed(AppRoutes.ADMIN_ACCOUNTING),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: .2)),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.cardGreen,
                  child:
                      Icon(Icons.account_balance_outlined, color: Colors.white),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Foundation Accounting',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Members, investments, profits, expenses & PDF report',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    size: 16, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard(
      String label, String value, String sub, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label,
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.6),
                    fontWeight: FontWeight.w600)),
            Icon(icon, color: Colors.white.withOpacity(0.5), size: 18),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            Text(sub,
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.4))),
          ]),
        ],
      ),
    );
  }

  Widget _pendingUserItem(UserModel user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(children: [
        UserAvatar(
            initials: user.initials, color: AppColors.cardBlue, size: 44),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user.name,
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            Text(user.phone,
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: AppColors.textSecondary)),
          ]),
        ),
        Row(children: [
          GestureDetector(
            onTap: () => controller.rejectUser(user.id),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.close, color: AppColors.error, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => controller.approveUser(user.id),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(10)),
              child:
                  const Icon(Icons.check, color: AppColors.success, size: 18),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildBottomNav(int currentIndex) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderColor)),
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(children: [
        _navItem(Icons.dashboard_outlined, 'Dashboard', 0, currentIndex, () {}),
        _navItem(Icons.people_outline, 'Users', 1, currentIndex,
            () => Get.toNamed(AppRoutes.ADMIN_USERS)),
        _navItem(Icons.payments_outlined, 'Payments', 2, currentIndex,
            () => Get.toNamed(AppRoutes.ADMIN_PAYMENTS)),
        _navItem(Icons.chat_bubble_outline, 'Chat', 3, currentIndex,
            () => Get.toNamed(AppRoutes.ADMIN_CHAT)),
      ]),
    );
  }

  Widget _navItem(
      IconData icon, String label, int index, int current, VoidCallback onTap) {
    final active = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(children: [
          if (label == 'Chat')
            Obx(() => CountBadge(
                  count: BadgeService.to.unreadChats.value,
                  child: Icon(icon,
                      color:
                          active ? AppColors.primary : AppColors.textSecondary,
                      size: 24),
                ))
          else
            Icon(icon,
                color: active ? AppColors.primary : AppColors.textSecondary,
                size: 24),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: active ? AppColors.primary : AppColors.textSecondary)),
        ]),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

// --- পপ-আপ ডায়ালগ ---
  /*
  void _showSpecialChargeDialog(BuildContext context) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomText.title('Add Special Charge'),
              const SizedBox(height: 4),
              const CustomText.small('Manual charge to increase user dues.', color: AppColors.textSecondary),
              const SizedBox(height: 20),

              // --- Toggle: All vs Single ---
              Obx(() => Row(
                children: [
                  Expanded(
                    child: _selectBtn('All Users', controller.isGlobalCharge.value,
                            () => controller.isGlobalCharge.value = true),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _selectBtn('Single User', !controller.isGlobalCharge.value,
                            () => controller.isGlobalCharge.value = false),
                  ),
                ],
              )),

              const SizedBox(height: 20),

              // --- User Dropdown ---
              Obx(() => (controller.isGlobalCharge.value)
                  ? const SizedBox.shrink()
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CustomText.label('Select User'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<UserModel>(
                        isExpanded: true,
                        hint: const CustomText.small('Choose a member'),
                        value: controller.selectedUserForCharge.value,
                        items: controller.allActiveUsers.map((user) {
                          return DropdownMenuItem(
                            value: user,
                            child: CustomText.small(user.name),
                          );
                        }).toList(),
                        onChanged: (val) => controller.selectedUserForCharge.value = val,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              )),

              _buildDialogField(controller.chargeTitleCtrl, 'Reason (e.g. Picnic, Late Fee)', Icons.description_outlined),
              const SizedBox(height: 12),
              _buildDialogField(controller.chargeAmountCtrl, 'Amount (৳)', Icons.payments_outlined, isNumber: true),

              const SizedBox(height: 24),

              // --- Action Buttons ---
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    child: const CustomText.body('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Obx(() => ElevatedButton(
                    onPressed: controller.isLoading.value ? null : controller.submitSpecialCharge,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: controller.isLoading.value
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const CustomText.body('Apply Charge', color: Colors.white),
                  )),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // --- হেল্পার উইজেট (এইগুলো ক্লাসের ভেতরেই থাকবে) ---
  Widget _selectBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface2,
          borderRadius: BorderRadius.circular(12),
          border: active ? null : Border.all(color: AppColors.borderColor),
        ),
        child: Center(
          child: CustomText.label(label, color: active ? Colors.white : AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildDialogField(TextEditingController ctrl, String hint, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontFamily: 'Nunito', fontSize: 14),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.surface2,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }*/
}
