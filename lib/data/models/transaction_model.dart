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
  final String? phoneNumber; // নতুন যুক্ত হয়েছে
  final String? receiptUrl;  // নতুন যুক্ত হয়েছে

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
    this.phoneNumber,
    this.receiptUrl,
  });

  bool get isConfirmed => status == 'confirmed';
  bool get isPending   => status == 'pending';

  // --- copyWith Method: এটি আপনার 'confirmed' আপডেট এররটি সমাধান করবে ---
  TransactionModel copyWith({
    String? id,
    String? userId,
    String? userName,
    double? amount,
    String? month,
    DateTime? monthYear,
    String? status,
    DateTime? submittedAt,
    DateTime? confirmedAt,
    String? note,
    String? phoneNumber,
    String? receiptUrl,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      amount: amount ?? this.amount,
      month: month ?? this.month,
      monthYear: monthYear ?? this.monthYear,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      note: note ?? this.note,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      receiptUrl: receiptUrl ?? this.receiptUrl,
    );
  }

  factory TransactionModel.fromSupabase(Map<String, dynamic> json) {
    // profiles join returns nested map when using select('*, profiles!user_id(name)')
    final profileData = json['profiles'];
    final nameFromJoin = profileData is Map ? (profileData['name'] ?? '') : '';
    final userName = nameFromJoin.isNotEmpty ? nameFromJoin : (json['user_name'] ?? 'Unknown');

    return TransactionModel(
      id:          json['id'] ?? '',
      userId:      json['user_id'] ?? '',
      userName:    userName,
      amount:      (json['amount'] ?? 0).toDouble(),
      month:       json['month'] ?? '',
      monthYear:   DateTime.tryParse(json['month_year'] ?? '') ?? DateTime.now(),
      status:      json['status'] ?? 'pending',
      submittedAt: DateTime.tryParse(json['created_at'] ?? '')?.toLocal() ?? DateTime.now(),
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.tryParse(json['confirmed_at'])?.toLocal()
          : null,
      note:        json['note'],
      phoneNumber: json['phone_number'], // ডাটাবেস থেকে ফোন নম্বর রিড করা
      receiptUrl:  json['receipt_url'],  // ডাটাবেস থেকে রিসিপ্ট ইউআরএল রিড করা
    );
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel.fromSupabase(json);
}