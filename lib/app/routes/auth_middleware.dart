import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/services/auth_service.dart';
import 'app_routes.dart';

class AdminMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final auth = AuthService.to;
    if (!auth.isLoggedIn) {
      return const RouteSettings(name: AppRoutes.LOGIN);
    }
    final user = auth.currentUser.value;
    if (user == null || !user.isAdmin || !user.isActive) {
      return RouteSettings(
        name: user?.isPending == true
            ? AppRoutes.PENDING_APPROVAL
            : AppRoutes.USER_DASHBOARD,
      );
    }
    return null;
  }
}

class UserMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final auth = AuthService.to;
    if (!auth.isLoggedIn) {
      return const RouteSettings(name: AppRoutes.LOGIN);
    }
    final user = auth.currentUser.value;
    if (user == null || !user.isActive) {
      return const RouteSettings(name: AppRoutes.PENDING_APPROVAL);
    }
    if (user.isAdmin) {
      return const RouteSettings(name: AppRoutes.ADMIN_DASHBOARD);
    }
    return null;
  }
}
