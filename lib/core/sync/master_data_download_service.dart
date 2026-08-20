import 'package:get/get.dart';

import '../../data/datasources/local/master_local_data_source.dart';
import '../../data/models/outlet_model.dart';
import '../../data/models/product_model.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../network/network_info.dart';
import '../storage/local_storage.dart';

class MasterDataDownloadService {
  MasterDataDownloadService({ApiClient? apiClient, NetworkInfo? networkInfo, MasterLocalDataSource? localDataSource})
      : _api = apiClient ?? Get.find<ApiClient>(),
        _network = networkInfo ?? Get.find<NetworkInfo>(),
        _local = localDataSource ?? MasterLocalDataSource();

  final ApiClient _api;
  final NetworkInfo _network;
  final MasterLocalDataSource _local;

  Future<MasterDataDownloadResult> download({void Function(MasterDownloadProgress progress)? onProgress}) async {
    if (!await _network.isConnected) {
      throw StateError('Perangkat sedang offline. Hubungkan internet untuk mengunduh data terbaru.');
    }
    onProgress?.call(const MasterDownloadProgress(value: .1, label: 'Mengunduh snapshot master...'));
    final response = await _api.get<Map<String, dynamic>>(ApiEndpoints.masterSnapshot);
    final datasets = response['datasets'];
    if (datasets is! Map) throw const FormatException('Snapshot master tidak memiliki datasets.');

    onProgress?.call(const MasterDownloadProgress(value: .35, label: 'Memvalidasi produk...'));
    final products = _products(datasets['products']);
    onProgress?.call(const MasterDownloadProgress(value: .6, label: 'Memvalidasi outlet...'));
    final outlets = _outlets(datasets['outlets']);

    onProgress?.call(const MasterDownloadProgress(value: .8, label: 'Memperbarui penyimpanan lokal...'));
    await _local.replaceValidatedMasterData(products: products, outlets: outlets);
    final generatedAt = response['generatedAt']?.toString() ?? DateTime.now().toUtc().toIso8601String();
    await LocalStorage.appBox.put('last_master_download_at', DateTime.now().toIso8601String());
    await LocalStorage.appBox.put('last_master_generated_at', generatedAt);
    await LocalStorage.appBox.put('last_master_revision', response['revision']?.toString() ?? '');
    await LocalStorage.appBox.put('last_master_products_count', products.length);
    await LocalStorage.appBox.put('last_master_outlets_count', outlets.length);
    onProgress?.call(const MasterDownloadProgress(value: 1, label: 'Data terbaru siap digunakan.'));
    return MasterDataDownloadResult(products: products.length, outlets: outlets.length, generatedAt: generatedAt);
  }

  List<ProductModel> _products(dynamic raw) {
    if (raw is! List) throw const FormatException('Dataset products tidak valid.');
    return raw.map((item) {
      if (item is! Map) throw const FormatException('Satu atau lebih data produk tidak valid.');
      return ProductModel.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  List<OutletModel> _outlets(dynamic raw) {
    if (raw is! List) throw const FormatException('Dataset outlets tidak valid.');
    return raw.map((item) {
      if (item is! Map) throw const FormatException('Satu atau lebih data outlet tidak valid.');
      return OutletModel.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }
}

class MasterDownloadProgress {
  const MasterDownloadProgress({required this.value, required this.label});
  final double value;
  final String label;
}

class MasterDataDownloadResult {
  const MasterDataDownloadResult({required this.products, required this.outlets, required this.generatedAt});
  final int products;
  final int outlets;
  final String generatedAt;
}
