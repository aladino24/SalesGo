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
        // Kembalikan hasil yang sudah dinormalisasi dari cache, bukan payload
        // mentah, agar daftar yang tampil langsung bebas SKU duplikat.
        return _localDataSource.getProducts();
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
        // Kode outlet adalah identitas bisnis pada perangkat; hasil online dan
        // offline harus melalui sumber lokal yang sama agar tidak menumpuk.
        return _localDataSource.getOutlets();
      } catch (_) {
        return _localDataSource.getOutlets();
      }
    }
    return _localDataSource.getOutlets();
  }
}
