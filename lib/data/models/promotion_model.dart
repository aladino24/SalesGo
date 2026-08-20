class PromotionModel {
  const PromotionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startAt,
    required this.endAt,
    required this.status,
    this.imageUrl = '',
  });

  final String id;
  final String title;
  final String description;
  final DateTime startAt;
  final DateTime endAt;
  final String status;
  final String imageUrl;

  factory PromotionModel.fromJson(Map<String, dynamic> json) => PromotionModel(
        id: json['id'].toString(),
        title: json['title']?.toString() ?? 'Tanpa judul',
        description: json['description']?.toString() ?? '',
        startAt: DateTime.tryParse(json['startAt']?.toString() ?? '') ?? DateTime.now(),
        endAt: DateTime.tryParse(json['endAt']?.toString() ?? '') ?? DateTime.now(),
        status: json['status']?.toString() ?? 'Aktif',
        imageUrl: json['imageUrl']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'startAt': startAt.toIso8601String(),
        'endAt': endAt.toIso8601String(),
        'status': status,
        'imageUrl': imageUrl,
      };
}
