import 'package:flutter_test/flutter_test.dart';
import 'package:salesgo/data/models/dashboard_model.dart';

void main() {
  test('parses dashboard response contract', () {
    final model = DashboardModel.fromJson({'monthlyRevenue': 100000, 'monthlyTarget': 200000, 'visitedOutlets': 4, 'totalOutlets': 8, 'incentive': 5000, 'revenueGrowth': 12.5});
    expect(model.monthlyRevenue, 100000);
    expect(model.visitedOutlets, 4);
    expect(model.toJson()['revenueGrowth'], 12.5);
  });
}
