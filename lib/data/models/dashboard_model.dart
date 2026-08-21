class DashboardModel {
  const DashboardModel({required this.monthlyRevenue, required this.monthlyTarget, required this.visitedOutlets, required this.totalOutlets, required this.incentive, required this.revenueGrowth, this.chart = const []});
  final double monthlyRevenue, monthlyTarget, incentive, revenueGrowth;
  final int visitedOutlets, totalOutlets;
  final List<Map<String, dynamic>> chart;
  factory DashboardModel.fromJson(Map<String, dynamic> json) => DashboardModel(monthlyRevenue: (json['monthlyRevenue'] as num? ?? 0).toDouble(), monthlyTarget: (json['monthlyTarget'] as num? ?? 0).toDouble(), visitedOutlets: json['visitedOutlets'] as int? ?? 0, totalOutlets: json['totalOutlets'] as int? ?? 0, incentive: (json['incentive'] as num? ?? 0).toDouble(), revenueGrowth: (json['revenueGrowth'] as num? ?? 0).toDouble(), chart: (json['chart'] as List? ?? []).whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList());
  Map<String, dynamic> toJson() => {'monthlyRevenue': monthlyRevenue, 'monthlyTarget': monthlyTarget, 'visitedOutlets': visitedOutlets, 'totalOutlets': totalOutlets, 'incentive': incentive, 'revenueGrowth': revenueGrowth, 'chart': chart};
}
