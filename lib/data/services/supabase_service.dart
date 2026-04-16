import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app/app_config/app_config.dart';
import '../models/models.dart';
import '../models/notification_model.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';

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
    // ১. ইউজার সাইন আপ (এটি সেশন তৈরি করবে)
    final res = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'name': name, 'phone': phone, 'role': 'user'},
    );

    if (res.user == null) throw Exception('Sign up failed');
    final uid = res.user!.id;

    // ২. ডকুমেন্টস আপলোড (RLS Policy অনুযায়ী এখন সেশন থাকায় এটি কাজ করবে)
    if (documentFile != null) {
      try {
        final ext = documentFile.path.split('.').last;
        final path = '$uid/document.$ext';

        // ফাইল আপলোড
        await supabase.storage.from('documents').upload(
          path,
          documentFile,
          fileOptions: const FileOptions(upsert: true),
        );

        // পাবলিক ইউআরএল বা পাথ প্রোফাইলে সেভ করা (পাথ সেভ করাই ভালো)
        await supabase.from('profiles').update({
          'document_url': path,
          'status': 'pending'
        }).eq('id', uid);
      } catch (storageError) {
        debugPrint('Storage Upload Error: $storageError');
      }
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
    try {
      String? finalAvatarUrl;

      // ১. যদি ইমেজ থাকে তবে আপলোড করো
      if (avatarFile != null) {
        final ext = avatarFile.path.split('.').last;
        final path = '$uid/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext'; // ক্যাশিং সমস্যা এড়াতে টাইমস্ট্যাম্প যোগ করা ভালো

        await supabase.storage.from('avatars').upload(
          path,
          avatarFile,
          fileOptions: const FileOptions(upsert: true),
        );

        // ইমেজের পাবলিক ইউআরএল নেওয়া
        finalAvatarUrl = supabase.storage.from('avatars').getPublicUrl(path);
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
      return await getProfile(uid);
    } catch (e) {
      throw 'Update failed: $e';
    }
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

  // ১. ইউজার পেমেন্ট রিকোয়েস্ট পাঠাবে
  // ইউজার পেমেন্ট রিকোয়েস্ট পাঠাবে
  Future<void> requestPayment({
    required double amount,
    required String month,
    required String phone,
    File? receiptFile,
  }) async {
    final uid = supabase.auth.currentUser!.id;
    String? receiptUrl;

    // ১. যদি রিসিপ্ট থাকে তবে আপলোড করো
    if (receiptFile != null) {
      final ext = receiptFile.path.split('.').last;
      final path = 'receipts/$uid/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await supabase.storage.from('receipts').upload(path, receiptFile);
      receiptUrl = supabase.storage.from('receipts').getPublicUrl(path);
    }

    // ২. ট্রানজেকশন ইনসার্ট
    await supabase.from('transactions').insert({
      'user_id': uid,
      'amount': amount,
      'month': month,
      'phone_number': phone,
      'receipt_url': receiptUrl,
      'status': 'pending',
      'month_year': DateTime.now().toIso8601String().substring(0, 10), // বর্তমান মাসের রেকর্ড হিসেবে
    });
  }

// ইউজারের সব ট্রানজেকশন হিস্ট্রি
  Future<List<TransactionModel>> getUserTransactions(String userId) async {
    final data = await supabase
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (data as List).map((t) => TransactionModel.fromSupabase(t)).toList();
  }

// ২. এডমিন স্পেশাল চার্জ যোগ করবে
  Future<void> addSpecialCharge({String? userId, required String title, required double amount}) async {
    await supabase.from('special_charges').insert({
      'user_id': userId, // userId null হলে লজিক অনুযায়ী সবার dues বাড়বে
      'title': title,
      'amount': amount,
    });

    // প্রোফাইলে dues আপডেট করার লজিক (সব ইউজার বা নির্দিষ্ট ইউজার)
    if (userId == null) {
      await supabase.rpc('add_global_special_charge', params: {'p_amount': amount});
    } else {
      await supabase.from('profiles').update({
        'dues': supabase.rpc('increment_dues', params: {'p_id': userId, 'p_amount': amount})
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
    await supabase.from('profiles').update({'monthly_amount': amount}).eq('id', userId);
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

// ইউজারের লেজার আনা (কে কোন মাসের টাকা দিয়েছে)
  Future<List<dynamic>> getUserLedger(String userId) async {
    final res = await supabase.rpc('get_user_ledger', params: {'p_user_id': userId});
    return res as List<dynamic>;
  }
  // সেটিংস পড়া
  Future<Map<String, dynamic>> getAppSettings() async {
    final data = await supabase.from('app_settings').select().eq('id', 1).single();
    return data;
  }

// সেটিংস আপডেট করা
  Future<void> updateAppSettings(double amount, DateTime startDate) async {
    await supabase.from('app_settings').update({
      'monthly_amount': amount,
      'start_date': startDate.toIso8601String().substring(0, 10),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', 1);
  }
  // ১. কোনো মাসের বাজেট সেট করা (Regular/Special)
  Future<void> setMonthRequirement(DateTime month, double amount, String title, bool isSpecial) async {
    await supabase.from('monthly_requirements').upsert({
      'month_year': DateTime(month.year, month.month, 1).toIso8601String().substring(0, 10),
      'amount': amount,
      'title': title,
      'is_special': isSpecial,
    });
  }

// ২. নির্দিষ্ট মাসের সব ইউজারের রিপোর্ট আনা (ডাউনলোডের জন্য)
  Future<List<dynamic>> getMonthlyReport(DateTime month) async {
    final dateStr = DateTime(month.year, month.month, 1).toIso8601String().substring(0, 10);
    return await supabase.rpc('get_monthly_report', params: {'p_month_year': dateStr});
  }


}
