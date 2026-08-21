import 'package:flutter_test/flutter_test.dart';
import 'package:salesgo/data/datasources/local/master_local_data_source.dart';

import 'support/hive_test_helper.dart';

void main() {
  setUpAll(HiveTestHelper.initialize);

  group('MasterLocalDataSource', () {
    setUp(() => HiveTestHelper.clearBoxes(['master_products', 'master_outlets']));

    test('returns an empty product list when offline cache has not been downloaded', () async {
      final source = MasterLocalDataSource();

      final products = await source.getProducts();

      expect(products, isEmpty);
    });

    test('returns an empty outlet list when offline cache has not been downloaded', () async {
      final source = MasterLocalDataSource();

      final outlets = await source.getOutlets();

      expect(outlets, isEmpty);
    });
  });
}
