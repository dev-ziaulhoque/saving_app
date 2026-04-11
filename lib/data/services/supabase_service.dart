import 'dart:io';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app/app_config/app_config.dart';
import '../models/models.dart';

final supabase = Supabase.instance.client;

class SupabaseService extends GetxService {
  static SupabaseService get to => Get.find();

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }

  SupabaseClient get client => supabase;

  User? get currentAuthUser => supabase.auth.currentUser;
  bool get isLoggedIn => currentAuthUser != null;
  String? get userId => currentAuthUser?.id;

  String getDocumentUrl(String path) =>
      supabase.storage.from('documents').getPublicUrl(path);

  String getAvatarUrl(String path) =>
      supabase.storage.from('avatars').getPublicUrl(path);

  // ─────────────────────────────────────────────────────
  // AUTH
  // ─────────────────────────────────────────────────────

  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    File? documentFile,
  }) async {
    final res = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'name': name, 'phone': phone, 'role': 'user'},
    );

    if (res.user == null) throw Exception('Sign up failed');
    final uid = res.user!.id;

    if (documentFile != null) {
      final ext = documentFile.path.split('.').last;
      final path = '$uid/document.$ext';
      await supabase.storage
          .from('documents')
          .upload(path, documentFile,
          fileOptions: const FileOptions(upsert: true));
      await supabase
          .from('profiles')
          .update({'document_url': path}).eq('id', uid);
    }

    return await getProfile(uid);
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final res = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (res.user == null) throw Exception('Invalid credentials');
    return await getProfile(res.user!.id);
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  // ─────────────────────────────────────────────────────
  // PROFILES
  // ─────────────────────────────────────────────────────

  Future<UserModel> getProfile(String uid) async {
    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', uid)
        .single();
    return UserModel.fromSupabase(data);
  }

  Future<UserModel> updateProfile({
    required String uid,
    String? name,
    String? phone,
    String? fcmToken,
    File? avatarFile,
  }) async {
    String? avatarUrl;
    if (avatarFile != null) {
      final ext = avatarFile.path.split('.').last;
      final path = '$uid/avatar.$ext';
      await supabase.storage
          .from('avatars')
          .upload(path, avatarFile,
          fileOptions: const FileOptions(upsert: true));
      avatarUrl = path;
    }

    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (fcmToken != null) updates['fcm_token'] = fcmToken;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    await supabase.from('profiles').update(updates).eq('id', uid);
    return await getProfile(uid);
  }

  // ─────────────────────────────────────────────────────
  // ADMIN – USERS
  // ─────────────────────────────────────────────────────

  Future<List<UserModel>> getUsers({String? status}) async {
    // ✅ FIX: eq() filters BEFORE order() — no more chaining on TransformBuilder
    var query = supabase
        .from('profiles')
        .select()
        .eq('role', 'user');

    if (status != null && status != 'all') {
      query = query.eq('status', status);
    }

    final data = await query.order('created_at', ascending: false);
    return (data as List).map((u) => UserModel.fromSupabase(u)).toList();
  }

  Future<void> approveUser(String userId) async {
    await supabase.rpc('approve_user', params: {'target_user_id': userId});
  }

  Future<void> rejectUser(String userId, {String? reason}) async {
    await supabase.rpc('reject_user', params: {
      'target_user_id': userId,
      'reason': reason,
    });
  }

  Future<void> blockUser(String userId) async {
    await supabase.rpc('block_user', params: {'target_user_id': userId});
  }

  Future<void> unblockUser(String userId) async {
    await supabase.rpc('unblock_user', params: {'target_user_id': userId});
  }

  // ─────────────────────────────────────────────────────
  // ADMIN – TRANSACTIONS / PAYMENTS
  // ─────────────────────────────────────────────────────

  Future<List<TransactionModel>> getAllPayments({String? status}) async {
    // ✅ FIX: eq() filter BEFORE order()
    var query = supabase
        .from('transactions')
        .select('*, profiles!user_id(name)');

    if (status != null && status != 'all') {
      query = query.eq('status', status);
    }

    final data = await query.order('created_at', ascending: false);
    return (data as List).map((t) => TransactionModel.fromSupabase(t)).toList();
  }

  Future<void> confirmPayment(String paymentId) async {
    await supabase.rpc('confirm_payment', params: {'payment_id': paymentId});
  }

  Future<String> addTransaction({
    required String userId,
    required double amount,
    required String month,
    required DateTime monthYear,
    String? note,
  }) async {
    final result = await supabase.rpc('add_transaction', params: {
      'p_user_id':    userId,
      'p_amount':     amount,
      'p_month':      month,
      'p_month_year': monthYear.toIso8601String().substring(0, 10),
      'p_note':       note,
    });
    return result as String;
  }

  // ─────────────────────────────────────────────────────
  // ADMIN – STATS
  // ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAdminStats() async {
    final result = await supabase.rpc('get_admin_stats');
    return Map<String, dynamic>.from(result);
  }

  // ─────────────────────────────────────────────────────
  // USER – DASHBOARD & TRANSACTIONS
  // ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getUserDashboard() async {
    final result = await supabase.rpc('get_user_dashboard');
    return Map<String, dynamic>.from(result);
  }

  Future<List<TransactionModel>> getUserTransactions(String userId) async {
    final data = await supabase
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('month_year', ascending: false);
    return (data as List).map((t) => TransactionModel.fromSupabase(t)).toList();
  }

  // ─────────────────────────────────────────────────────
  // NOTIFICATIONS
  // ─────────────────────────────────────────────────────

  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    final data = await supabase
        .from('notifications')
        .select()
        .or('user_id.eq.$userId,user_id.is.null')
        .order('created_at', ascending: false);
    return (data as List).map((n) => NotificationModel.fromSupabase(n)).toList();
  }

  Future<void> markNotificationRead(String notifId) async {
    await supabase
        .from('notifications')
        .update({'is_read': true}).eq('id', notifId);
  }

  Future<void> sendNotification({
    required String title,
    required String body,
    required String type,
    String? userId,
  }) async {
    await supabase.from('notifications').insert({
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
    });
  }

  // ─────────────────────────────────────────────────────
  // CHAT – MESSAGES
  // ─────────────────────────────────────────────────────

  Future<List<MessageModel>> getMessages({
    required String userAId,
    required String userBId,
  }) async {
    final data = await supabase
        .from('messages')
        .select()
        .or('and(sender_id.eq.$userAId,receiver_id.eq.$userBId),and(sender_id.eq.$userBId,receiver_id.eq.$userAId)')
        .order('created_at', ascending: true);
    return (data as List).map((m) => MessageModel.fromSupabase(m)).toList();
  }

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    await supabase.from('messages').insert({
      'sender_id': senderId,
      'receiver_id': receiverId,
      'text': text,
    });
  }

  Future<void> markMessagesRead({
    required String senderId,
    required String receiverId,
  }) async {
    await supabase
        .from('messages')
        .update({'is_read': true})
        .eq('sender_id', senderId)
        .eq('receiver_id', receiverId)
        .eq('is_read', false);
  }

  Future<List<Map<String, dynamic>>> getAdminChatList() async {
    final result = await supabase.rpc('get_admin_chat_list');
    return List<Map<String, dynamic>>.from(result);
  }

  // ─────────────────────────────────────────────────────
  // REALTIME SUBSCRIPTIONS
  // ─────────────────────────────────────────────────────

  RealtimeChannel subscribeToMessages({
    required String userAId,
    required String userBId,
    required void Function(MessageModel) onMessage,
  }) {
    return supabase
        .channel('messages:$userAId:$userBId')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        final msg = MessageModel.fromSupabase(payload.newRecord);
        final relevant =
            (msg.senderId == userAId && msg.receiverId == userBId) ||
                (msg.senderId == userBId && msg.receiverId == userAId);
        if (relevant) onMessage(msg);
      },
    )
        .subscribe();
  }

  RealtimeChannel subscribeToNotifications({
    required String userId,
    required void Function(NotificationModel) onNotification,
  }) {
    return supabase
        .channel('notifications:$userId')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'notifications',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      callback: (payload) {
        onNotification(NotificationModel.fromSupabase(payload.newRecord));
      },
    )
        .subscribe();
  }
}
