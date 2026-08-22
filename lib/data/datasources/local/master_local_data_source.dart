import 'package:hive_flutter/hive_flutter.dart';

import '../../models/outlet_model.dart';
import '../../models/product_model.dart';

class MasterLocalDataSource {
  static const _productsBoxName = 'master_products';
  static const _outletsBoxName = 'master_outlets';

  Future<Box> _box(String name) async => Hive.isBoxOpen(name) ? Hive.box(name) : Hive.openBox(name);

  Future<List<ProductModel>> getProducts() async {
    final box = await _box(_productsBoxName);
    return _uniqueProducts(
      box.values
          .map((value) => ProductModel.fromJson(Map<String, dynamic>.from(value as Map)))
          .toList(),
    );
  }

  Future<List<OutletModel>> getOutlets() async {
    final box = await _box(_outletsBoxName);
    return _uniqueOutlets(
      box.values
          .map((value) => OutletModel.fromJson(Map<String, dynamic>.from(value as Map)))
          .toList(),
    );
  }

  Future<void> saveProducts(List<ProductModel> products) async {
    final box = await _box(_productsBoxName);
    final unique = _uniqueProducts(products);
    await box.clear();
    await box.putAll({for (final product in unique) product.id: product.toJson()});
  }

  Future<void> saveOutlets(List<OutletModel> outlets) async {
    final box = await _box(_outletsBoxName);
    final unique = _uniqueOutlets(outlets);
    await box.clear();
    await box.putAll({for (final outlet in unique) outlet.id: outlet.toJson()});
  }

  /// Replaces the supported master datasets only after they have been parsed
  /// successfully. Existing data is restored if a Hive write fails midway.
  Future<void> replaceValidatedMasterData({
    required List<ProductModel> products,
    required List<OutletModel> outlets,
  }) async {
    final productsBox = await _box(_productsBoxName);
    final outletsBox = await _box(_outletsBoxName);
    final previousProducts = Map<dynamic, dynamic>.from(productsBox.toMap());
    final previousOutlets = Map<dynamic, dynamic>.from(outletsBox.toMap());
    try {
      final uniqueProducts = _uniqueProducts(products);
      final uniqueOutlets = _uniqueOutlets(outlets);
      await productsBox.clear();
      await productsBox.putAll({for (final product in uniqueProducts) product.id: product.toJson()});
      await outletsBox.clear();
      await outletsBox.putAll({for (final outlet in uniqueOutlets) outlet.id: outlet.toJson()});
    } catch (_) {
      await productsBox.clear();
      await productsBox.putAll(previousProducts);
      await outletsBox.clear();
      await outletsBox.putAll(previousOutlets);
      rethrow;
    }
  }

  List<ProductModel> _uniqueProducts(List<ProductModel> items) {
    final unique = <String, ProductModel>{};
    for (final item in items) {
      final key = item.sku.trim().isEmpty ? item.id : item.sku.trim().toUpperCase();
      unique[key] = item;
    }
    return unique.values.toList();
  }

  List<OutletModel> _uniqueOutlets(List<OutletModel> items) {
    final unique = <String, OutletModel>{};
    for (final item in items) {
      final key = item.code.trim().isEmpty ? item.id : item.code.trim().toUpperCase();
      unique[key] = item;
    }
    return unique.values.toList();
  }
}
