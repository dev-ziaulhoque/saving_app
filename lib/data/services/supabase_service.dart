import 'dart:io';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app/app_config/app_config.dart';
import '../../core/utils/app_logger.dart';
import '../models/notification_model.dart';
import '../models/audit_log_model.dart';
import '../models/foundation_report_model.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import 'cloudinary_service.dart';

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
    AppLogger.request('auth.signUp', {
      'email': email,
      'name': name,
      'phone': phone,
      'has_document': documentFile != null,
    });
    // ১. ইউজার সাইন আপ (এটি সেশন তৈরি করবে)
    final res = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'name': name, 'phone': phone, 'role': 'user'},
    );

    AppLogger.success('auth.signUp', {
      'user_id': res.user?.id,
      'has_session': res.session != null,
    });
    if (res.user == null) throw Exception('Sign up failed');
    if (res.session == null) {
      throw Exception(
        'Account created. Verify your email, then sign in to continue.',
      );
    }
    final uid = res.user!.id;

    // ২. ডকুমেন্টস আপলোড (RLS Policy অনুযায়ী এখন সেশন থাকায় এটি কাজ করবে)
    if (documentFile != null) {
      try {
        final ext = documentFile.path.split('.').last;
        final path = '$uid/document.$ext';
        AppLogger.request('storage.uploadDocument', {
          'user_id': uid,
          'path': path,
          'bytes': await documentFile.length(),
        });

        // ফাইল আপলোড
        await supabase.storage.from('documents').upload(
              path,
              documentFile,
              fileOptions: const FileOptions(upsert: true),
            );

        // পাবলিক ইউআরএল বা পাথ প্রোফাইলে সেভ করা (পাথ সেভ করাই ভালো)
        await supabase
            .from('profiles')
            .update({'document_url': path, 'status': 'pending'}).eq('id', uid);
        AppLogger.success('storage.uploadDocument', {'path': path});
      } catch (storageError) {
        AppLogger.error('storage.uploadDocument', storageError);
      }
    }

    return await getProfile(uid);
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    AppLogger.request('auth.signIn', {'email': email});
    final res = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (res.user == null) throw Exception('Invalid credentials');
    AppLogger.success('auth.signIn', {'user_id': res.user!.id});
    return await getProfile(res.user!.id);
  }

  Future<void> signOut() async {
    AppLogger.request('auth.signOut', {'user_id': userId});
    await supabase.auth.signOut();
    AppLogger.success('auth.signOut');
  }

  // ─────────────────────────────────────────────────────
  // PROFILES
  // ─────────────────────────────────────────────────────

  Future<UserModel> getProfile(String uid) async {
    AppLogger.request('profiles.get', {'user_id': uid});
    final data =
        await supabase.from('profiles').select().eq('id', uid).single();
    AppLogger.success('profiles.get', data);
    return UserModel.fromSupabase(data);
  }

  Future<UserModel> updateProfile({
    required String uid,
    String? name,
    String? phone,
    String? fcmToken,
    File? avatarFile,
  }) async {
    AppLogger.request('profiles.update', {
      'user_id': uid,
      'name': name,
      'phone': phone,
      'fcm_token': fcmToken,
      'has_avatar': avatarFile != null,
    });
    try {
      String? finalAvatarUrl;

      // Public profile avatars are stored in Cloudinary.
      if (avatarFile != null) {
        finalAvatarUrl = await CloudinaryService.uploadAvatar(avatarFile);
      }

      // ২. আপডেট ডাটা তৈরি করা
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (fcmToken != null) updates['fcm_token'] = fcmToken;
      if (finalAvatarUrl != null) updates['avatar_url'] = finalAvatarUrl;

      // ৩. ডাটাবেস আপডেট
      if (updates.isNotEmpty) {
        await supabase.from('profiles').update(updates).eq('id', uid);
      }

      // ৪. আপডেট হওয়া প্রোফাইল রিটার্ন করা
      final profile = await getProfile(uid);
      AppLogger.success('profiles.update', profile.toJson());
      return profile;
    } catch (e) {
      AppLogger.error('profiles.update', e);
      throw 'Update failed: $e';
    }
  }

  // ─────────────────────────────────────────────────────
  // ADMIN – USERS
  // ─────────────────────────────────────────────────────

  Future<List<UserModel>> getUsers({String? status}) async {
    AppLogger.request('profiles.list', {'status': status});
    // ✅ FIX: eq() filters BEFORE order() — no more chaining on TransformBuilder
    var query = supabase.from('profiles').select().eq('role', 'user');

    if (status != null && status != 'all') {
      query = query.eq('status', status);
    }

    final data = await query.order('created_at', ascending: false);
    AppLogger.success('profiles.list', {'count': (data as List).length});
    return data.map((u) => UserModel.fromSupabase(u)).toList();
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
    AppLogger.request('transactions.listAll', {'status': status});
    // ✅ FIX: eq() filter BEFORE order()
    var query =
        supabase.from('transactions').select('*, profiles!user_id(name)');

    if (status != null && status != 'all') {
      query = query.eq('status', status);
    }

    final data = await query.order('created_at', ascending: false);
    final rows = (data as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
    for (final row in rows) {
      final receiptPath = row['receipt_url'] as String?;
      if (receiptPath != null &&
          receiptPath.isNotEmpty &&
          !receiptPath.startsWith('http')) {
        row['receipt_url'] = await supabase.storage
            .from('receipts')
            .createSignedUrl(receiptPath, 3600);
      }
    }
    AppLogger.success('transactions.listAll', {'count': rows.length});
    return rows.map(TransactionModel.fromSupabase).toList();
  }

  Future<void> confirmPayment(String paymentId) async {
    await supabase.rpc('confirm_payment', params: {'payment_id': paymentId});
  }

  Future<String> addManualPaymentAdmin({
    required String targetUserId,
    required double amount,
    required List<DateTime> months,
    required File proofFile,
    required String note,
  }) async {
    final ext = proofFile.path.split('.').last;
    final proofPath =
        '$targetUserId/admin-manual-${DateTime.now().millisecondsSinceEpoch}.$ext';
    AppLogger.request('transactions.adminManual', {
      'target_user_id': targetUserId,
      'amount': amount,
      'months': months.map((m) => m.toIso8601String()).toList(),
      'proof_bytes': await proofFile.length(),
    });
    await supabase.storage.from('receipts').upload(proofPath, proofFile);
    try {
      final result = await supabase
          .rpc('add_manual_selected_months_payment_admin', params: {
        'target_user_id': targetUserId,
        'amount_per_month': amount,
        'payment_months': months
            .map((m) =>
                DateTime(m.year, m.month, 1).toIso8601String().substring(0, 10))
            .toList(),
        'proof_path': proofPath,
        'payment_note': note,
      });
      AppLogger.success('transactions.adminManual', {'transaction_id': result});
      return result as String;
    } catch (_) {
      try {
        await supabase.storage.from('receipts').remove([proofPath]);
      } catch (_) {
        // The database error remains the primary failure; orphan cleanup can be
        // handled by a scheduled storage maintenance job.
      }
      rethrow;
    }
  }

  Future<String> addTransaction({
    required String userId,
    required double amount,
    required String month,
    required DateTime monthYear,
    String? note,
  }) async {
    final result = await supabase.rpc('add_transaction', params: {
      'p_user_id': userId,
      'p_amount': amount,
      'p_month': month,
      'p_month_year': monthYear.toIso8601String().substring(0, 10),
      'p_note': note,
    });
    return result as String;
  }

  // ১. ইউজার পেমেন্ট রিকোয়েস্ট পাঠাবে
  // ইউজার পেমেন্ট রিকোয়েস্ট পাঠাবে
  Future<void> requestPayment({
    required List<DateTime> months,
    required double amountPerMonth,
    required String phone,
    File? receiptFile,
  }) async {
    final uid = supabase.auth.currentUser!.id;
    AppLogger.request('transactions.requestPayment', {
      'user_id': uid,
      'months': months.map((m) => m.toIso8601String()).toList(),
      'amount_per_month': amountPerMonth,
      'phone': phone,
      'has_receipt': receiptFile != null,
    });
    String? receiptUrl;

    // ১. যদি রিসিপ্ট থাকে তবে আপলোড করো
    if (receiptFile != null) {
      final ext = receiptFile.path.split('.').last;
      final path = '$uid/${DateTime.now().millisecondsSinceEpoch}.$ext';
      AppLogger.request('storage.uploadReceipt', {
        'path': path,
        'bytes': await receiptFile.length(),
      });
      await supabase.storage.from('receipts').upload(path, receiptFile);
      receiptUrl = path;
      AppLogger.success('storage.uploadReceipt', {'path': path});
    }

    try {
      await supabase.rpc('create_payment_request', params: {
        'payment_phone': phone,
        'receipt_path': receiptUrl ?? '',
        'allocation_months': months
            .map((m) =>
                DateTime(m.year, m.month, 1).toIso8601String().substring(0, 10))
            .toList(),
        'allocation_amounts':
            List<double>.filled(months.length, amountPerMonth),
      });
      AppLogger.success('transactions.requestPayment', {
        'user_id': uid,
        'month_count': months.length,
        'total': amountPerMonth * months.length,
      });
    } catch (_) {
      if (receiptUrl != null) {
        try {
          await supabase.storage.from('receipts').remove([receiptUrl]);
        } catch (_) {}
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUserPaymentCalendar(
      {String? targetUserId}) async {
    final data = await supabase.rpc('get_user_payment_calendar', params: {
      'target_user_id': targetUserId,
    });
    return (data as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<void> setUserSavingsStart(String userId, DateTime startDate) async {
    await supabase.rpc('set_user_savings_start_admin', params: {
      'target_user_id': userId,
      'start_date': DateTime(startDate.year, startDate.month, 1)
          .toIso8601String()
          .substring(0, 10),
    });
  }

// ইউজারের সব ট্রানজেকশন হিস্ট্রি
  Future<List<TransactionModel>> getUserTransactions(String userId) async {
    AppLogger.request('transactions.listForUser', {'user_id': userId});
    final data = await supabase
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    final rows = (data as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
    for (final row in rows) {
      final receiptPath = row['receipt_url'] as String?;
      if (receiptPath != null &&
          receiptPath.isNotEmpty &&
          !receiptPath.startsWith('http')) {
        row['receipt_url'] = await supabase.storage
            .from('receipts')
            .createSignedUrl(receiptPath, 3600);
      }
    }
    AppLogger.success('transactions.listForUser', {'count': rows.length});
    return rows.map(TransactionModel.fromSupabase).toList();
  }

// ২. এডমিন স্পেশাল চার্জ যোগ করবে
  Future<void> addSpecialCharge(
      {String? userId, required String title, required double amount}) async {
    await supabase.from('special_charges').insert({
      'user_id': userId, // userId null হলে লজিক অনুযায়ী সবার dues বাড়বে
      'title': title,
      'amount': amount,
    });

    // প্রোফাইলে dues আপডেট করার লজিক (সব ইউজার বা নির্দিষ্ট ইউজার)
    if (userId == null) {
      await supabase
          .rpc('add_global_special_charge', params: {'p_amount': amount});
    } else {
      await supabase.from('profiles').update({
        'dues': supabase
            .rpc('increment_dues', params: {'p_id': userId, 'p_amount': amount})
      }).eq('id', userId);
    }
  }

  Future<void> applySpecialCharge({
    required String title,
    required double amount,
    String? userId, // null পাঠালে সবার জন্য হবে
  }) async {
    await supabase.rpc('apply_special_charge', params: {
      'p_title': title,
      'p_amount': amount,
      'p_target_user_id': userId,
    });
  }

// ৩. এডমিন মান্থলি অ্যামাউন্ট ফিক্স করবে
  Future<void> setMonthlyAmount(String userId, double amount) async {
    await supabase.rpc('set_user_monthly_amount', params: {
      'target_user_id': userId,
      'new_amount': amount,
    });
  }

  // ─────────────────────────────────────────────────────
  // ADMIN – STATS
  // ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAdminStats() async {
    final result = await supabase.rpc('get_admin_stats');
    return Map<String, dynamic>.from(result);
  }

  Future<List<AuditLogModel>> getAuditLogs({int limit = 100}) async {
    AppLogger.request('auditLogs.list', {'limit': limit});
    final data = await supabase
        .from('audit_logs')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    final logs = (data as List)
        .map((row) => AuditLogModel.fromJson(
              Map<String, dynamic>.from(row as Map),
            ))
        .toList();
    AppLogger.success('auditLogs.list', {'count': logs.length});
    return logs;
  }

  Future<List<Map<String, dynamic>>> getInvestments() async {
    final data = await supabase
        .from('investments')
        .select()
        .order('invested_at', ascending: false);
    return (data as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<void> addInvestment({
    required String title,
    required double amount,
    required DateTime investedAt,
    String? notes,
  }) async {
    await supabase.from('investments').insert({
      'title': title,
      'amount': amount,
      'invested_at': investedAt.toIso8601String().substring(0, 10),
      'notes': notes,
      'created_by': userId,
    });
  }

  Future<void> addInvestmentProfit({
    required String investmentId,
    required double amount,
    required DateTime month,
    String? notes,
  }) async {
    await supabase.from('investment_profits').upsert({
      'investment_id': investmentId,
      'amount': amount,
      'profit_month': DateTime(month.year, month.month, 1)
          .toIso8601String()
          .substring(0, 10),
      'received_at': DateTime.now().toIso8601String().substring(0, 10),
      'notes': notes,
      'created_by': userId,
    }, onConflict: 'investment_id,profit_month');
  }

  Future<void> addFoundationExpense({
    required String title,
    required double amount,
    required DateTime expenseDate,
    String category = 'general',
    String? notes,
  }) async {
    await supabase.from('foundation_expenses').insert({
      'title': title,
      'amount': amount,
      'expense_date': expenseDate.toIso8601String().substring(0, 10),
      'category': category,
      'notes': notes,
      'created_by': userId,
    });
  }

  Future<FoundationReportModel> getLiveFoundationReport() async {
    final data = await supabase.rpc('get_live_foundation_report');
    return FoundationReportModel.fromJson(Map<String, dynamic>.from(data));
  }

  // ─────────────────────────────────────────────────────
  // USER – DASHBOARD & TRANSACTIONS
  // ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getUserDashboard() async {
    final result = await supabase.rpc('get_user_dashboard');
    return Map<String, dynamic>.from(result);
  }

  // Future<List<TransactionModel>> getUserTransactions(String userId) async {
  //   final data = await supabase
  //       .from('transactions')
  //       .select()
  //       .eq('user_id', userId)
  //       .order('month_year', ascending: false);
  //   return (data as List).map((t) => TransactionModel.fromSupabase(t)).toList();
  // }

  // ─────────────────────────────────────────────────────
  // NOTIFICATIONS
  // ─────────────────────────────────────────────────────

  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    AppLogger.request('notifications.list', {'user_id': userId});
    final data = await supabase
        .from('notifications')
        .select()
        .or('user_id.eq.$userId,user_id.is.null')
        .order('created_at', ascending: false);
    final reads = await supabase
        .from('notification_reads')
        .select('notification_id,completed_at')
        .eq('user_id', userId);
    final readIds =
        (reads as List).map((row) => row['notification_id'] as String).toSet();
    final completedIds = (reads as List)
        .where((row) => row['completed_at'] != null)
        .map((row) => row['notification_id'] as String)
        .toSet();

    final notifications = (data as List).map((row) {
      final notification = Map<String, dynamic>.from(row as Map);
      notification['is_read'] = readIds.contains(notification['id']);
      notification['is_completed'] = completedIds.contains(notification['id']);
      return NotificationModel.fromSupabase(notification);
    }).toList();
    AppLogger.success('notifications.list', {
      'count': notifications.length,
      'read_count': readIds.length,
    });
    return notifications;
  }

  Future<void> completeNotification(String notificationId) async {
    AppLogger.request('notifications.complete', {
      'notification_id': notificationId,
    });
    await supabase.rpc('complete_notification', params: {
      'target_notification_id': notificationId,
    });
    AppLogger.success('notifications.complete');
  }

  Future<void> markNotificationRead(String notifId) async {
    final uid = userId;
    if (uid == null) throw StateError('No authenticated user');
    AppLogger.request('notifications.markRead', {
      'notification_id': notifId,
      'user_id': uid,
    });
    await supabase.from('notification_reads').upsert({
      'notification_id': notifId,
      'user_id': uid,
      'read_at': DateTime.now().toIso8601String(),
    });
    AppLogger.success('notifications.markRead');
  }

  Future<void> sendNotification({
    required String title,
    required String body,
    required String type,
    String? userId,
  }) async {
    AppLogger.request('notifications.send', {
      'title': title,
      'body': body,
      'type': type,
      'user_id': userId,
    });
    final notificationId =
        await supabase.rpc('send_admin_notification', params: {
      'notification_title': title,
      'notification_body': body,
      'notification_type': type,
      'target_user_id': userId,
    });
    final response = await supabase.functions.invoke(
      'send-push',
      body: {'notification_id': notificationId},
    );
    AppLogger.success('notifications.push', response.data);
    AppLogger.success('notifications.send');
  }

  RealtimeChannel subscribeToNotifications({
    required String userId,
    required void Function() onChanged,
  }) {
    return supabase
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          callback: (payload) {
            final target = payload.newRecord['user_id'];
            if (target == null || target == userId) onChanged();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notification_reads',
          callback: (_) => onChanged(),
        )
        .subscribe();
  }

// ইউজারের লেজার আনা (কে কোন মাসের টাকা দিয়েছে)
  Future<List<dynamic>> getUserLedger(String userId) async {
    final res =
        await supabase.rpc('get_user_ledger', params: {'p_user_id': userId});
    return res as List<dynamic>;
  }

  // সেটিংস পড়া
  Future<Map<String, dynamic>> getAppSettings() async {
    AppLogger.request('appSettings.get');
    final data =
        await supabase.from('app_settings').select().eq('id', 1).single();
    AppLogger.success('appSettings.get', data);
    return data;
  }

// সেটিংস আপডেট করা
  Future<void> updateAppSettings(double amount, DateTime startDate) async {
    await supabase.rpc('update_app_settings_admin', params: {
      'new_amount': amount,
      'new_start_date': startDate.toIso8601String().substring(0, 10),
    }).eq('id', 1);
  }

  // ১. কোনো মাসের বাজেট সেট করা (Regular/Special)
  Future<void> setMonthRequirement(
      DateTime month, double amount, String title, bool isSpecial) async {
    await supabase.rpc('set_month_requirement_admin', params: {
      'requirement_month': DateTime(month.year, month.month, 1)
          .toIso8601String()
          .substring(0, 10),
      'requirement_amount': amount,
      'requirement_title': title,
      'requirement_is_special': isSpecial,
    });
  }

// ২. নির্দিষ্ট মাসের সব ইউজারের রিপোর্ট আনা (ডাউনলোডের জন্য)
  Future<List<dynamic>> getMonthlyReport(DateTime month) async {
    final dateStr =
        DateTime(month.year, month.month, 1).toIso8601String().substring(0, 10);
    return await supabase
        .rpc('get_monthly_report', params: {'p_month_year': dateStr});
  }
}
