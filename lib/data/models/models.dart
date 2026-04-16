// ─── User Model ───────────────────────────────────────────────
class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String status;
  final double monthlyAmount;
  final double totalSaved;
  final double dues;
  final String? avatarUrl;
  final String? documentUrl;
  final String? fcmToken;
  final DateTime joinedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.monthlyAmount,
    required this.totalSaved,
    required this.dues,
    this.avatarUrl,
    this.documentUrl,
    this.fcmToken,
    required this.joinedAt,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  bool get isPending  => status == 'pending';
  bool get isActive   => status == 'active';
  bool get isBlocked  => status == 'blocked';
  bool get isAdmin    => role == 'admin';

  /// From Supabase `profiles` row
  factory UserModel.fromSupabase(Map<String, dynamic> json) {
    return UserModel(
      id:            json['id'] ?? '',
      name:          json['name'] ?? '',
      email:         json['email'] ?? '',
      phone:         json['phone'] ?? '',
      role:          json['role'] ?? 'user',
      status:        json['status'] ?? 'pending',
      monthlyAmount: (json['monthly_amount'] ?? 0).toDouble(),
      totalSaved:    (json['total_saved'] ?? 0).toDouble(),
      dues:          (json['dues'] ?? 0).toDouble(),
      avatarUrl:     json['avatar_url'],
      documentUrl:   json['document_url'],
      fcmToken:      json['fcm_token'],
      joinedAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  /// Legacy JSON factory (kept for GetStorage local cache)
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      UserModel.fromSupabase(json);

  Map<String, dynamic> toJson() => {
    'id':             id,
    'name':           name,
    'email':          email,
    'phone':          phone,
    'role':           role,
    'status':         status,
    'monthly_amount': monthlyAmount,
    'total_saved':    totalSaved,
    'dues':           dues,
    'avatar_url':     avatarUrl,
    'document_url':   documentUrl,
    'fcm_token':      fcmToken,
    'created_at':     joinedAt.toIso8601String(),
  };

  UserModel copyWith({
    String? id, String? name, String? email, String? phone,
    String? role, String? status, double? monthlyAmount,
    double? totalSaved, double? dues, String? avatarUrl,
    String? documentUrl, String? fcmToken, DateTime? joinedAt,
  }) {
    return UserModel(
      id:            id            ?? this.id,
      name:          name          ?? this.name,
      email:         email         ?? this.email,
      phone:         phone         ?? this.phone,
      role:          role          ?? this.role,
      status:        status        ?? this.status,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      totalSaved:    totalSaved    ?? this.totalSaved,
      dues:          dues          ?? this.dues,
      avatarUrl:     avatarUrl     ?? this.avatarUrl,
      documentUrl:   documentUrl   ?? this.documentUrl,
      fcmToken:      fcmToken      ?? this.fcmToken,
      joinedAt:      joinedAt      ?? this.joinedAt,
    );
  }
}

// ─── Transaction Model ─────────────────────────────────────────
class TransactionModel {
  final String id;
  final String userId;
  final String userName;
  final double amount;
  final String month;
  final DateTime monthYear;
  final String status;
  final DateTime submittedAt;
  final DateTime? confirmedAt;
  final String? note;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.amount,
    required this.month,
    required this.monthYear,
    required this.status,
    required this.submittedAt,
    this.confirmedAt,
    this.note,
  });

  bool get isConfirmed => status == 'confirmed';
  bool get isPending   => status == 'pending';

  factory TransactionModel.fromSupabase(Map<String, dynamic> json) {
    // profiles join returns nested map when using select('*, profiles!user_id(name)')
    final profileData = json['profiles'];
    final userName = profileData is Map
        ? (profileData['name'] ?? '')
        : (json['user_name'] ?? '');

    return TransactionModel(
      id:          json['id'] ?? '',
      userId:      json['user_id'] ?? '',
      userName:    userName,
      amount:      (json['amount'] ?? 0).toDouble(),
      month:       json['month'] ?? '',
      monthYear:   DateTime.tryParse(json['month_year'] ?? '') ?? DateTime.now(),
      status:      json['status'] ?? 'pending',
      submittedAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.tryParse(json['confirmed_at'])
          : null,
      note: json['note'],
    );
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel.fromSupabase(json);
}

// ─── Notification Model ────────────────────────────────────────
class NotificationModel {
  final String id;
  final String? userId;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromSupabase(Map<String, dynamic> json) {
    return NotificationModel(
      id:        json['id'] ?? '',
      userId:    json['user_id'],
      title:     json['title'] ?? '',
      body:      json['body'] ?? '',
      type:      json['type'] ?? 'general',
      isRead:    json['is_read'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel.fromSupabase(json);
}
