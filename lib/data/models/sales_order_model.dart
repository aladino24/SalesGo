class SalesOrderModel {
  SalesOrderModel({
    required this.id,
    required this.outletName,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String outletName;
  final double total;
  final String status;
  final DateTime createdAt;

  factory SalesOrderModel.fromJson(Map<String, dynamic> json) {
    return SalesOrderModel(
      id: json['id'] as String,
      outletName: json['outletName'] as String,
      total: (json['total'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'outletName': outletName,
        'total': total,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };
}
