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
