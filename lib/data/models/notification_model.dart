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
