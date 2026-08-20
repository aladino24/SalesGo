import '../datasources/local/master_local_data_source.dart';
import '../datasources/remote/master_remote_data_source.dart';
import '../models/outlet_model.dart';
import '../models/product_model.dart';

class MasterRepository {
  MasterRepository({
    MasterLocalDataSource? localDataSource,
    MasterRemoteDataSource? remoteDataSource,
  })  : _localDataSource = localDataSource ?? MasterLocalDataSource(),
        _remoteDataSource = remoteDataSource ?? MasterRemoteDataSource();

  final MasterLocalDataSource _localDataSource;
  final MasterRemoteDataSource _remoteDataSource;

  Future<List<ProductModel>> getProducts({required bool isOnline}) async {
    if (isOnline) {
      try {
        final products = await _remoteDataSource.getProducts();
        await _localDataSource.saveProducts(products);
        return products;
      } catch (_) {
        return _localDataSource.getProducts();
      }
    }
    return _localDataSource.getProducts();
  }

  Future<List<OutletModel>> getOutlets({required bool isOnline}) async {
    if (isOnline) {
      try {
        final outlets = await _remoteDataSource.getOutlets();
        await _localDataSource.saveOutlets(outlets);
        return outlets;
      } catch (_) {
        return _localDataSource.getOutlets();
      }
    }
    return _localDataSource.getOutlets();
  }
}
