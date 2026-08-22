class ApprovalModel {
  ApprovalModel({
    required this.id,
    required this.type,
    required this.entityId,
    required this.requestedBy,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.requestedByRole,
    this.outlet,
  });

  final String id;
  final String type;
  final String entityId;
  final String requestedBy;
  final String reason;
  final String status;
  final DateTime createdAt;
  final String? requestedByRole;
  final Map<String, dynamic>? outlet;

  factory ApprovalModel.fromJson(Map<String, dynamic> json) {
    final requester = json['requestedBy'];
    final requesterMap = requester is Map ? Map<String, dynamic>.from(requester) : null;
    return ApprovalModel(
      id: json['id'].toString(), type: json['type'].toString(), entityId: json['entityId'].toString(),
      requestedBy: requesterMap?['name']?.toString() ?? requester?.toString() ?? '-',
      requestedByRole: requesterMap?['role']?.toString(), reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Pending', createdAt: DateTime.parse(json['createdAt'].toString()),
      outlet: json['outlet'] is Map ? Map<String, dynamic>.from(json['outlet'] as Map) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'entityId': entityId,
        'requestedBy': requestedByRole == null ? requestedBy : {'name': requestedBy, 'role': requestedByRole},
        'reason': reason,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        if (outlet != null) 'outlet': outlet,
      };
}
