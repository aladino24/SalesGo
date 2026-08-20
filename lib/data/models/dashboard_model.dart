class DashboardModel {
  const DashboardModel({required this.monthlyRevenue, required this.monthlyTarget, required this.visitedOutlets, required this.totalOutlets, required this.incentive, required this.revenueGrowth});
  final double monthlyRevenue, monthlyTarget, incentive, revenueGrowth;
  final int visitedOutlets, totalOutlets;
  factory DashboardModel.fromJson(Map<String, dynamic> json) => DashboardModel(monthlyRevenue: (json['monthlyRevenue'] as num? ?? 0).toDouble(), monthlyTarget: (json['monthlyTarget'] as num? ?? 0).toDouble(), visitedOutlets: json['visitedOutlets'] as int? ?? 0, totalOutlets: json['totalOutlets'] as int? ?? 0, incentive: (json['incentive'] as num? ?? 0).toDouble(), revenueGrowth: (json['revenueGrowth'] as num? ?? 0).toDouble());
  Map<String, dynamic> toJson() => {'monthlyRevenue': monthlyRevenue, 'monthlyTarget': monthlyTarget, 'visitedOutlets': visitedOutlets, 'totalOutlets': totalOutlets, 'incentive': incentive, 'revenueGrowth': revenueGrowth};
}
