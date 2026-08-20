class OutletPerformanceModel {
  const OutletPerformanceModel({
    required this.target,
    required this.achievement,
    required this.topProducts,
    required this.unsoldProducts,
    required this.potentialProducts,
  });

  final double target;
  final double achievement;
  final List<String> topProducts;
  final List<String> unsoldProducts;
  final List<String> potentialProducts;
  double get achievementPercent => target <= 0 ? 0 : (achievement / target).clamp(0, 1).toDouble();

  factory OutletPerformanceModel.fromJson(Map<String, dynamic> json) => OutletPerformanceModel(
        target: (json['target'] as num?)?.toDouble() ?? 0,
        achievement: (json['achievement'] as num?)?.toDouble() ?? 0,
        topProducts: _strings(json['topProducts']),
        unsoldProducts: _strings(json['unsoldProducts']),
        potentialProducts: _strings(json['potentialProducts']),
      );

  Map<String, dynamic> toJson() => {
        'target': target,
        'achievement': achievement,
        'topProducts': topProducts,
        'unsoldProducts': unsoldProducts,
        'potentialProducts': potentialProducts,
      };

  static List<String> _strings(dynamic value) => value is List ? value.map((item) => item is Map ? (item['name'] ?? item['productName'] ?? '-').toString() : item.toString()).toList() : [];
}
