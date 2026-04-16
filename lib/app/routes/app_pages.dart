import 'package:get/get.dart';

import '../../modules/auth/login/login_binding.dart';
import '../../modules/auth/login/login_view.dart';
import '../../modules/auth/register/register_binding.dart';
import '../../modules/auth/register/register_view.dart';
import '../../modules/auth/pending/pending_view.dart';
import '../../modules/admin/dashboard/binding/admin_dashboard_binding.dart';
import '../../modules/admin/dashboard/views/admin_dashboard_view.dart';
import '../../modules/admin/users/binding/admin_users_binding.dart';
import '../../modules/admin/users/views/admin_users_view.dart' hide AdminUsersBinding;
import '../../modules/admin/users/views/admin_user_detail_view.dart';
import '../../modules/admin/payments/binding/admin_payments_binding.dart';
import '../../modules/admin/payments/views/admin_payments_view.dart';
import '../../modules/admin/notifications/admin_notifications_view.dart';
import '../../modules/chat/binding/chat_binding.dart';
import '../../modules/chat/views/admin_inbox_view.dart';
import '../../modules/chat/views/chat_details_view.dart';
import '../../modules/chat/views/chat_view.dart';
import '../../modules/user/dashboard/binding/user_dashboard_binding.dart';
import '../../modules/user/dashboard/views/user_dashboard_view.dart';
import '../../modules/user/history/binding/user_history_binding.dart';
import '../../modules/user/history/controllers/user_payment_request_controller.dart';
import '../../modules/user/history/views/user_history_view.dart';
import '../../modules/user/history/views/user_payment_request_view.dart';
import '../../modules/user/notifications/user_notifications_binding.dart';
import '../../modules/user/notifications/user_notifications_view.dart';
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
      page: () => const AdminInboxView(),
      binding: ChatBinding(),
    ),
    GetPage(
      name: AppRoutes.ADMIN_CHAT_DETAIL,
      page: () => const ChatDetailsView(),
      binding: ChatBinding(),
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
      page: () => const ChatDetailsView(),
      binding: ChatBinding(),
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

    GetPage(
      name: AppRoutes.PAYMENT_REQUEST,
      page: () => const PaymentRequestView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => PaymentRequestController());
      }),
    ),
  ];
}
