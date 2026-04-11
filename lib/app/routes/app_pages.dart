import 'package:get/get.dart';

import '../../modules/auth/login/login_binding.dart';
import '../../modules/auth/login/login_view.dart';
import '../../modules/auth/register/register_binding.dart';
import '../../modules/auth/register/register_view.dart';
import '../../modules/auth/pending/pending_view.dart';
import '../../modules/admin/dashboard/admin_dashboard_binding.dart';
import '../../modules/admin/dashboard/admin_dashboard_view.dart';
import '../../modules/admin/users/admin_users_binding.dart';
import '../../modules/admin/users/admin_users_view.dart' hide AdminUsersBinding;
import '../../modules/admin/users/admin_user_detail_view.dart';
import '../../modules/admin/payments/admin_payments_binding.dart';
import '../../modules/admin/payments/admin_payments_view.dart';
import '../../modules/admin/notifications/admin_notifications_view.dart';
import '../../modules/admin/chat/admin_chat_binding.dart';
import '../../modules/admin/chat/admin_chat_list_view.dart';
import '../../modules/admin/chat/admin_chat_detail_view.dart';
import '../../modules/user/dashboard/user_dashboard_binding.dart';
import '../../modules/user/dashboard/user_dashboard_view.dart';
import '../../modules/user/history/user_history_binding.dart';
import '../../modules/user/history/user_history_view.dart';
import '../../modules/user/notifications/user_notifications_binding.dart';
import '../../modules/user/notifications/user_notifications_view.dart';
import '../../modules/user/chat/user_chat_binding.dart';
import '../../modules/user/chat/user_chat_view.dart';
import '../../modules/user/profile/user_profile_binding.dart';
import '../../modules/user/profile/user_profile_view.dart';
import '../../modules/user/profile/user_edit_profile_view.dart';
import '../splash/splash_view.dart';
import '../splash/splash_binding.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.SPLASH,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.LOGIN,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: AppRoutes.REGISTER,
      page: () => const RegisterView(),
      binding: RegisterBinding(),
    ),
    GetPage(
      name: AppRoutes.PENDING_APPROVAL,
      page: () => const PendingApprovalView(),
    ),

    // Admin Routes
    GetPage(
      name: AppRoutes.ADMIN_DASHBOARD,
      page: () => const AdminDashboardView(),
      binding: AdminDashboardBinding(),
    ),
    GetPage(
      name: AppRoutes.ADMIN_USERS,
      page: () => const AdminUsersView(),
      binding: AdminUsersBinding(),
    ),
    GetPage(
      name: AppRoutes.ADMIN_USER_DETAIL,
      page: () => const AdminUserDetailView(),
    ),
    GetPage(
      name: AppRoutes.ADMIN_PAYMENTS,
      page: () => const AdminPaymentsView(),
      binding: AdminPaymentsBinding(),
    ),
    GetPage(
      name: AppRoutes.ADMIN_NOTIFICATIONS,
      page: () => const AdminNotificationsView(),
      binding: AdminNotificationsBinding(),
    ),
    GetPage(
      name: AppRoutes.ADMIN_CHAT,
      page: () => const AdminChatListView(),
      binding: AdminChatBinding(),
    ),
    GetPage(
      name: AppRoutes.ADMIN_CHAT_DETAIL,
      page: () => const AdminChatDetailView(),
    ),

    // User Routes
    GetPage(
      name: AppRoutes.USER_DASHBOARD,
      page: () => const UserDashboardView(),
      binding: UserDashboardBinding(),
    ),
    GetPage(
      name: AppRoutes.USER_HISTORY,
      page: () => const UserHistoryView(),
      binding: UserHistoryBinding(),
    ),
    GetPage(
      name: AppRoutes.USER_NOTIFICATIONS,
      page: () => const UserNotificationsView(),
      binding: UserNotificationsBinding(),
    ),
    GetPage(
      name: AppRoutes.USER_CHAT,
      page: () => const UserChatView(),
      binding: UserChatBinding(),
    ),
    GetPage(
      name: AppRoutes.USER_PROFILE,
      page: () => const UserProfileView(),
      binding: UserProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.USER_EDIT_PROFILE,
      page: () => const UserProfileView(),
    ),
  ];
}
