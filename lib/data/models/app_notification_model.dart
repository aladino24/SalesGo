class AppNotificationModel {
  const AppNotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.entityType,
    this.entityId,
    this.deepLink,
  });

  final String id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String? entityType;
  final String? entityId;
  final String? deepLink;

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) => AppNotificationModel(
        id: json['id']?.toString() ?? '',
        type: json['type']?.toString() ?? 'system',
        title: json['title']?.toString() ?? 'Notifikasi',
        message: json['message']?.toString() ?? '',
        isRead: json['isRead'] == true || json['is_read'] == true,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? json['created_at']?.toString() ?? '') ?? DateTime.now(),
        entityType: json['entityType']?.toString() ?? json['entity_type']?.toString(),
        entityId: json['entityId']?.toString() ?? json['entity_id']?.toString(),
        deepLink: json['deepLink']?.toString() ?? json['deep_link']?.toString(),
      );

  AppNotificationModel copyWith({bool? isRead}) => AppNotificationModel(
        id: id, type: type, title: title, message: message, isRead: isRead ?? this.isRead, createdAt: createdAt,
        entityType: entityType, entityId: entityId, deepLink: deepLink,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'type': type, 'title': title, 'message': message, 'isRead': isRead,
        'createdAt': createdAt.toIso8601String(), 'entityType': entityType, 'entityId': entityId, 'deepLink': deepLink,
      };
}
