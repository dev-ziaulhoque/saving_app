import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';
import 'badge_service.dart';

class NotificationService extends GetxService {
  static const _channel = AndroidNotificationChannel(
    'savesmart_notifications',
    'SaveSmart notifications',
    description: 'Account, payment, chat, and general notifications.',
    importance: Importance.high,
  );

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  RealtimeChannel? _databaseChannel;
  final Set<String> _shownNotificationIds = {};

  Future<NotificationService> init() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(initializationSettings);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    await _syncTokenSafely();

    _tokenSubscription = _messaging.onTokenRefresh.listen(_saveToken);
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (event) {
        if (event.session != null) {
          _syncTokenSafely();
          _subscribeToDatabaseNotifications();
        } else {
          _removeDatabaseSubscription();
        }
      },
    );
    _messageSubscription = FirebaseMessaging.onMessage.listen(_showForeground);
    if (Supabase.instance.client.auth.currentUser != null) {
      _subscribeToDatabaseNotifications();
    }
    return this;
  }

  void _subscribeToDatabaseNotifications() {
    _removeDatabaseSubscription();
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return;
    _databaseChannel = client
        .channel('foreground-notifications:$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          callback: (payload) async {
            final row = payload.newRecord;
            if (row['user_id'] != null && row['user_id'] != uid) return;
            final id = row['id']?.toString() ?? '';
            if (id.isNotEmpty && !_shownNotificationIds.add(id)) return;
            await _showLocal(
                id.hashCode, row['title']?.toString(), row['body']?.toString());
            if (Get.isRegistered<BadgeService>()) {
              await BadgeService.to.refresh();
            }
          },
        )
        .subscribe();
  }

  void _removeDatabaseSubscription() {
    final channel = _databaseChannel;
    _databaseChannel = null;
    if (channel != null) Supabase.instance.client.removeChannel(channel);
  }

  Future<void> _syncToken() async {
    final token = await _messaging.getToken();
    if (token != null) await _saveToken(token);
  }

  Future<void> _syncTokenSafely() async {
    try {
      await _syncToken();
    } catch (_) {
      // Push setup must not prevent the rest of the app from starting.
    }
  }

  Future<void> _saveToken(String token) async {
    final uid = SupabaseService.to.userId;
    if (uid == null) return;
    await Supabase.instance.client
        .from('profiles')
        .update({'fcm_token': token}).eq('id', uid);
  }

  Future<void> _showForeground(RemoteMessage message) async {
    if (Get.isRegistered<BadgeService>()) {
      await BadgeService.to.refresh();
    }
    final notification = message.notification;
    if (notification == null) return;

    final notificationId = message.data['notification_id']?.toString();
    if (notificationId != null &&
        notificationId.isNotEmpty &&
        !_shownNotificationIds.add(notificationId)) {
      return;
    }

    await _showLocal(
        message.messageId.hashCode, notification.title, notification.body);
  }

  Future<void> _showLocal(int id, String? title, String? body) async {
    await _localNotifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'savesmart_notifications',
          'SaveSmart notifications',
          channelDescription:
              'Account, payment, chat, and general notifications.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  @override
  void onClose() {
    _tokenSubscription?.cancel();
    _authSubscription?.cancel();
    _messageSubscription?.cancel();
    _removeDatabaseSubscription();
    super.onClose();
  }
}
