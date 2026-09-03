class AuditLogModel {
  final int id;
  final String? actorId;
  final String action;
  final String entityType;
  final String? entityId;
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;
  final DateTime createdAt;

  const AuditLogModel({
    required this.id,
    this.actorId,
    required this.action,
    required this.entityType,
    this.entityId,
    this.oldData,
    this.newData,
    required this.createdAt,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: json['id'] as int,
      actorId: json['actor_id'] as String?,
      action: json['action'] as String? ?? 'unknown',
      entityType: json['entity_type'] as String? ?? 'unknown',
      entityId: json['entity_id'] as String?,
      oldData: json['old_data'] == null
          ? null
          : Map<String, dynamic>.from(json['old_data'] as Map),
      newData: json['new_data'] == null
          ? null
          : Map<String, dynamic>.from(json['new_data'] as Map),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
    );
  }
}
