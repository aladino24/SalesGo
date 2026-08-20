class VisitModel {
  VisitModel({
    required this.id,
    required this.outletName,
    required this.status,
    required this.distanceKm,
    required this.salesName,
    required this.createdAt,
    this.outletId,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String outletName;
  final String status;
  final double distanceKm;
  final String salesName;
  final DateTime createdAt;
  final String? outletId;
  final double? latitude;
  final double? longitude;

  factory VisitModel.fromJson(Map<String, dynamic> json) {
    return VisitModel(
      id: json['id'] as String,
      outletName: json['outletName'] as String,
      status: json['status'] as String,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      salesName: json['salesName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      outletId: json['outletId']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'outletName': outletName,
        'status': status,
        'distanceKm': distanceKm,
        'salesName': salesName,
        'createdAt': createdAt.toIso8601String(),
        if (outletId != null) 'outletId': outletId,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };

  VisitModel copyWith({
    String? id,
    String? outletName,
    String? status,
    double? distanceKm,
    String? salesName,
    DateTime? createdAt,
    String? outletId,
    double? latitude,
    double? longitude,
  }) {
    return VisitModel(
      id: id ?? this.id,
      outletName: outletName ?? this.outletName,
      status: status ?? this.status,
      distanceKm: distanceKm ?? this.distanceKm,
      salesName: salesName ?? this.salesName,
      createdAt: createdAt ?? this.createdAt,
      outletId: outletId ?? this.outletId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
