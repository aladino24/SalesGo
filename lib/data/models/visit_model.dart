class VisitModel {
  VisitModel({
    required this.id,
    required this.outletName,
    required this.status,
    required this.distanceKm,
    required this.salesName,
    required this.createdAt,
  });

  final String id;
  final String outletName;
  final String status;
  final double distanceKm;
  final String salesName;
  final DateTime createdAt;

  factory VisitModel.fromJson(Map<String, dynamic> json) {
    return VisitModel(
      id: json['id'] as String,
      outletName: json['outletName'] as String,
      status: json['status'] as String,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      salesName: json['salesName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'outletName': outletName,
        'status': status,
        'distanceKm': distanceKm,
        'salesName': salesName,
        'createdAt': createdAt.toIso8601String(),
      };

  VisitModel copyWith({
    String? id,
    String? outletName,
    String? status,
    double? distanceKm,
    String? salesName,
    DateTime? createdAt,
  }) {
    return VisitModel(
      id: id ?? this.id,
      outletName: outletName ?? this.outletName,
      status: status ?? this.status,
      distanceKm: distanceKm ?? this.distanceKm,
      salesName: salesName ?? this.salesName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
