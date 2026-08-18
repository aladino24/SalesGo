class SyncItem {
  SyncItem({
    required this.id,
    required this.uuid,
    required this.type,
    required this.endpoint,
    required this.method,
    required this.payload,
    required this.status,
    required this.idempotencyKey,
    required this.createdAt,
    this.lastAttemptAt,
    this.attemptCount = 0,
    this.error,
  });

  final String id; // Local primary key
  final String uuid; // Unique identifier for the transaction (for deduplication)
  final String type; // visit_create, sales_order_create, etc.
  final String endpoint; // /visits, /sales-orders, etc.
  final String method; // POST, PUT, PATCH, DELETE
  final Map<String, dynamic> payload; // Request body
  final String status; // pending, syncing, success, failed, conflict
  final String idempotencyKey; // Unique key for idempotency (UUID-based)
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
  final int attemptCount;
  final String? error;

  factory SyncItem.fromJson(Map<String, dynamic> json) {
    return SyncItem(
      id: json['id'] as String,
      uuid: json['uuid'] as String,
      type: json['type'] as String,
      endpoint: json['endpoint'] as String,
      method: json['method'] as String,
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      status: json['status'] as String,
      idempotencyKey: json['idempotencyKey'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastAttemptAt: json['lastAttemptAt'] != null
          ? DateTime.parse(json['lastAttemptAt'] as String)
          : null,
      attemptCount: json['attemptCount'] as int? ?? 0,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'uuid': uuid,
        'type': type,
        'endpoint': endpoint,
        'method': method,
        'payload': payload,
        'status': status,
        'idempotencyKey': idempotencyKey,
        'createdAt': createdAt.toIso8601String(),
        'lastAttemptAt': lastAttemptAt?.toIso8601String(),
        'attemptCount': attemptCount,
        'error': error,
      };

  SyncItem copyWith({
    String? status,
    DateTime? lastAttemptAt,
    int? attemptCount,
    String? error,
  }) {
    return SyncItem(
      id: id,
      uuid: uuid,
      type: type,
      endpoint: endpoint,
      method: method,
      payload: payload,
      status: status ?? this.status,
      idempotencyKey: idempotencyKey,
      createdAt: createdAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      attemptCount: attemptCount ?? this.attemptCount,
      error: error ?? this.error,
    );
  }
}
