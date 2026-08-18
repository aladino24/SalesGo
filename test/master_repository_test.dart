import 'package:flutter_test/flutter_test.dart';
import 'package:salesgo/data/repositories/master_repository.dart';

void main() {
  group('MasterRepository', () {
    test('returns product list from local data source when offline', () async {
      final repository = MasterRepository();

      final products = await repository.getProducts(isOnline: false);

      expect(products, isNotEmpty);
      expect(products.first.name, isNotEmpty);
    });

    test('returns outlet list from local data source when offline', () async {
      final repository = MasterRepository();

      final outlets = await repository.getOutlets(isOnline: false);

      expect(outlets, isNotEmpty);
      expect(outlets.first.name, isNotEmpty);
    });
  });
}
