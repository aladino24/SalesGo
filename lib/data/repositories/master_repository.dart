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
      return _remoteDataSource.getProducts();
    }
    return _localDataSource.getProducts();
  }

  Future<List<OutletModel>> getOutlets({required bool isOnline}) async {
    if (isOnline) {
      return _remoteDataSource.getOutlets();
    }
    return _localDataSource.getOutlets();
  }
}
