class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final bool isRead;
  final DateTime createdAt;
  final String? attachmentPath;
  final String? attachmentType;
  final String? attachmentName;
  final int? attachmentSize;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.isRead,
    required this.createdAt,
    this.attachmentPath,
    this.attachmentType,
    this.attachmentName,
    this.attachmentSize,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      text: json['text'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      attachmentPath: json['attachment_path'],
      attachmentType: json['attachment_type'],
      attachmentName: json['attachment_name'],
      attachmentSize: (json['attachment_size'] as num?)?.toInt(),
    );
  }

  bool get hasAttachment =>
      attachmentPath != null && attachmentPath!.isNotEmpty;
  bool get isImage => attachmentType == 'image';
}
