import 'package:hive_flutter/hive_flutter.dart';

import '../../models/sales_order_model.dart';

class SalesOrderLocalDataSource {
  static const _boxName = 'sales_orders';
  Future<Box> get _box async => Hive.isBoxOpen(_boxName) ? Hive.box(_boxName) : Hive.openBox(_boxName);
  Future<void> save(SalesOrderModel order) async => (await _box).put(order.id, order.toJson());
  Future<List<SalesOrderModel>> getAll() async => (await _box).values.map((value) => SalesOrderModel.fromJson(Map<String, dynamic>.from(value as Map))).toList();
}
