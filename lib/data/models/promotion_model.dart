class PromotionModel {
  const PromotionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startAt,
    required this.endAt,
    required this.status,
    this.imageUrl = '',
    this.code = '',
    this.type = '',
    this.value = 0,
    this.minimumOrderAmount = 0,
    this.maximumDiscount,
  });

  final String id;
  final String title;
  final String description;
  final DateTime startAt;
  final DateTime endAt;
  final String status;
  final String imageUrl;
  final String code, type;
  final double value, minimumOrderAmount;
  final double? maximumDiscount;

  factory PromotionModel.fromJson(Map<String, dynamic> json) => PromotionModel(
        id: json['id'].toString(),
        title: json['title']?.toString() ?? 'Tanpa judul',
        description: json['description']?.toString() ?? '',
        startAt: DateTime.tryParse(json['startAt']?.toString() ?? '') ?? DateTime.now(),
        endAt: DateTime.tryParse(json['endAt']?.toString() ?? '') ?? DateTime.now(),
        status: json['status']?.toString() ?? 'Aktif',
        imageUrl: json['imageUrl']?.toString() ?? '',
        code: json['code']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        value: _number(json['value']),
        minimumOrderAmount: _number(json['minimumOrderAmount']),
        maximumDiscount: json['maximumDiscount'] == null ? null : _number(json['maximumDiscount']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'startAt': startAt.toIso8601String(),
        'endAt': endAt.toIso8601String(),
        'status': status,
        'imageUrl': imageUrl,
        'code': code,
        'type': type,
        'value': value,
        'minimumOrderAmount': minimumOrderAmount,
        if (maximumDiscount != null) 'maximumDiscount': maximumDiscount,
      };

  static double _number(dynamic value) => value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;
}
