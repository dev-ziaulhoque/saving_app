abstract class AppRoutes {
  static const SPLASH = '/splash';
  static const LOGIN = '/login';
  static const REGISTER = '/register';
  static const PENDING_APPROVAL = '/pending-approval';

  // Admin
  static const ADMIN_DASHBOARD = '/admin/dashboard';
  static const ADMIN_USERS = '/admin/users';
  static const ADMIN_USER_DETAIL = '/admin/users/detail';
  static const ADMIN_PAYMENTS = '/admin/payments';
  static const ADMIN_NOTIFICATIONS = '/admin/notifications';
  static const ADMIN_CHAT = '/admin/chat';
  static const ADMIN_CHAT_DETAIL = '/admin/chat/detail';
  static const ADMIN_AUDIT = '/admin/audit';
  static const ADMIN_ACCOUNTING = '/admin/accounting';
  static const ADMIN_COMMUNITY = '/admin/community';

  // User
  static const USER_DASHBOARD = '/user/dashboard';
  static const USER_HISTORY = '/user/history';
  static const USER_NOTIFICATIONS = '/user/notifications';
  static const USER_CHAT = '/user/chat';
  static const USER_DIRECT_CHAT = '/user/chat/direct';
  static const USER_PROFILE = '/user/profile';
  static const USER_EDIT_PROFILE = '/user/profile/edit';
  static const PAYMENT_REQUEST = '/user/payment-request';
  static const USER_FOUNDATION_REPORT = '/user/foundation-report';
}
