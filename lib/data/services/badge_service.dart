import 'dart:async';

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';

class BadgeService extends GetxService {
  static BadgeService get to => Get.find();

  final unreadChats = 0.obs;
  final unreadNotifications = 0.obs;
  final _client = Supabase.instance.client;
  RealtimeChannel? _channel;
  StreamSubscription<AuthState>? _authSubscription;
  Timer? _debounce;

  Future<BadgeService> init() async {
    _authSubscription = _client.auth.onAuthStateChange.listen((event) {
      if (event.session == null) {
        unreadChats.value = 0;
        unreadNotifications.value = 0;
        _unsubscribe();
      } else {
        _subscribe();
        refresh();
      }
    });
    if (_client.auth.currentUser != null) {
      _subscribe();
      await refresh();
    }
    return this;
  }

  Future<void> refresh() async {
    if (_client.auth.currentUser == null) return;
    try {
      final result = await _client.rpc('get_unread_badge_counts');
      final data = Map<String, dynamic>.from(result as Map);
      unreadChats.value = (data['chats'] as num?)?.toInt() ?? 0;
      unreadNotifications.value = (data['notifications'] as num?)?.toInt() ?? 0;
    } catch (error) {
      AppLogger.error('badges.refresh', error);
    }
  }

  void _scheduleRefresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), refresh);
  }

  void _subscribe() {
    _unsubscribe();
    _channel = _client
        .channel('app-badges:${_client.auth.currentUser!.id}')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'messages',
            callback: (_) => _scheduleRefresh())
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'notifications',
            callback: (_) => _scheduleRefresh())
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'notification_reads',
            callback: (_) => _scheduleRefresh())
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'group_messages',
            callback: (_) => _scheduleRefresh())
        .subscribe();
  }

  void _unsubscribe() {
    final channel = _channel;
    _channel = null;
    if (channel != null) _client.removeChannel(channel);
  }

  @override
  void onClose() {
    _debounce?.cancel();
    _authSubscription?.cancel();
    _unsubscribe();
    super.onClose();
  }
}
