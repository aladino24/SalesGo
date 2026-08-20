class ApprovalModel {
  ApprovalModel({
    required this.id,
    required this.type,
    required this.entityId,
    required this.requestedBy,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String entityId;
  final String requestedBy;
  final String reason;
  final String status;
  final DateTime createdAt;

  factory ApprovalModel.fromJson(Map<String, dynamic> json) => ApprovalModel(id: json['id'] as String, type: json['type'] as String, entityId: json['entityId'] as String, requestedBy: json['requestedBy'] as String, reason: json['reason'] as String, status: json['status'] as String, createdAt: DateTime.parse(json['createdAt'] as String));

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'entityId': entityId,
        'requestedBy': requestedBy,
        'reason': reason,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };
}
