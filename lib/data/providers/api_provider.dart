import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response, FormData;
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class ApiProvider {
  static const String baseUrl = 'https://api.savesmart.app/api/v1';

  late final Dio _dio;

  ApiProvider() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
    ));

    _dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = Supabase.instance.client.auth.currentSession?.accessToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          AuthService.to.logout();
          Get.offAllNamed('/login');
        }
        return handler.next(error);
      },
    ));
  }

  // ─── Auth ──────────────────────────────────────────────────
  Future<Response> login(String email, String password, String role) async {
    return await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
      'role': role,
    });
  }

  Future<Response> register(Map<String, dynamic> data) async {
    return await _dio.post('/auth/register', data: data);
  }

  Future<Response> registerWithDocument(FormData formData) async {
    return await _dio.post('/auth/register', data: formData);
  }

  // ─── Admin – Users ─────────────────────────────────────────
  Future<Response> getUsers({String? status}) async {
    return await _dio.get('/admin/users', queryParameters: {
      if (status != null) 'status': status,
    });
  }

  Future<Response> getUserDetail(String userId) async {
    return await _dio.get('/admin/users/$userId');
  }

  Future<Response> approveUser(String userId) async {
    return await _dio.post('/admin/users/$userId/approve');
  }

  Future<Response> rejectUser(String userId, {String? reason}) async {
    return await _dio.post('/admin/users/$userId/reject', data: {
      if (reason != null) 'reason': reason,
    });
  }

  Future<Response> blockUser(String userId) async {
    return await _dio.post('/admin/users/$userId/block');
  }

  Future<Response> unblockUser(String userId) async {
    return await _dio.post('/admin/users/$userId/unblock');
  }

  // ─── Admin – Payments ──────────────────────────────────────
  Future<Response> getAllPayments({String? status}) async {
    return await _dio.get('/admin/payments', queryParameters: {
      if (status != null) 'status': status,
    });
  }

  Future<Response> confirmPayment(String paymentId) async {
    return await _dio.post('/admin/payments/$paymentId/confirm');
  }

  // ─── Admin – Notifications ─────────────────────────────────
  Future<Response> sendNotification(String title, String body,
      {String? userId}) async {
    return await _dio.post('/admin/notifications', data: {
      'title': title,
      'body': body,
      if (userId != null) 'user_id': userId,
    });
  }

  // ─── Admin Dashboard Stats ─────────────────────────────────
  Future<Response> getAdminStats() async {
    return await _dio.get('/admin/stats');
  }

  // ─── User ──────────────────────────────────────────────────
  Future<Response> getUserDashboard() async {
    return await _dio.get('/user/dashboard');
  }

  Future<Response> getUserTransactions() async {
    return await _dio.get('/user/transactions');
  }

  Future<Response> getUserNotifications() async {
    return await _dio.get('/user/notifications');
  }

  Future<Response> markNotificationRead(String id) async {
    return await _dio.post('/user/notifications/$id/read');
  }

  Future<Response> updateProfile(Map<String, dynamic> data) async {
    return await _dio.put('/user/profile', data: data);
  }

  // ─── Chat ──────────────────────────────────────────────────
  Future<Response> getChatList() async {
    return await _dio.get('/chat/list');
  }

  Future<Response> getMessages(String userId) async {
    return await _dio.get('/chat/messages/$userId');
  }

  Future<Response> sendMessage(String receiverId, String text) async {
    return await _dio.post('/chat/send', data: {
      'receiver_id': receiverId,
      'text': text,
    });
  }
}
