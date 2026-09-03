import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user_model.dart';
import 'supabase_service.dart';

class AuthService extends GetxService {
  static AuthService get to => Get.find();

  final _box = GetStorage();
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  static const _keyUser = 'current_user';

  Future<AuthService> init() async {
    // Restore cached user immediately for fast startup
    final cached = _box.read(_keyUser);
    if (cached != null) {
      currentUser.value = UserModel.fromJson(Map<String, dynamic>.from(cached));
    }

    // If Supabase session still alive, refresh profile from DB
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      try {
        final profile = await SupabaseService.to.getProfile(session.user.id);
        await _saveLocal(profile);
      } catch (_) {}
    }

    // Listen for auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      if (event == AuthChangeEvent.signedOut) {
        currentUser.value = null;
        await _box.remove(_keyUser);
      }
    });

    return this;
  }

  bool get isLoggedIn =>
      currentUser.value != null &&
      Supabase.instance.client.auth.currentSession != null;
  bool get isAdmin => currentUser.value?.isAdmin ?? false;
  bool get isPendingApproval => currentUser.value?.isPending ?? false;

  Future<void> _saveLocal(UserModel user) async {
    await _box.write(_keyUser, user.toJson());
    currentUser.value = user;
  }

  Future<void> saveSession(UserModel user) async => _saveLocal(user);

  Future<void> updateUser(UserModel user) async => _saveLocal(user);

  Future<void> logout() async {
    await SupabaseService.to.signOut();
    await _box.remove(_keyUser);
    currentUser.value = null;
  }
}
