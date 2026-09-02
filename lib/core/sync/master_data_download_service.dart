import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/datasources/local/master_local_data_source.dart';
import '../../data/models/outlet_model.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/information_repository.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../network/network_info.dart';
import '../storage/local_storage.dart';

class MasterDataDownloadService {
  MasterDataDownloadService({
    ApiClient? apiClient,
    NetworkInfo? networkInfo,
    MasterLocalDataSource? localDataSource,
  }) : _api = apiClient ?? Get.find<ApiClient>(),
       _network = networkInfo ?? Get.find<NetworkInfo>(),
       _local = localDataSource ?? MasterLocalDataSource();

  final ApiClient _api;
  final NetworkInfo _network;
  final MasterLocalDataSource _local;

  Future<MasterDataDownloadResult> download({
    void Function(MasterDownloadProgress progress)? onProgress,
  }) async {
    if (!await _network.isConnected) {
      throw StateError(
        'Perangkat sedang offline. Hubungkan internet untuk mengunduh data terbaru.',
      );
    }
    onProgress?.call(
      const MasterDownloadProgress(
        value: .1,
        label: 'Mengunduh snapshot master...',
      ),
    );
    final response = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.masterSnapshot,
    );
    final datasets = response['datasets'];
    if (datasets is! Map)
      throw const FormatException('Snapshot master tidak memiliki datasets.');

    onProgress?.call(
      const MasterDownloadProgress(value: .35, label: 'Memvalidasi produk...'),
    );
    final products = _products(datasets['products']);
    onProgress?.call(
      const MasterDownloadProgress(value: .6, label: 'Memvalidasi outlet...'),
    );
    final outlets = _outlets(datasets['outlets']);
    final orderPolicy = _orderPolicy(datasets['orderPolicy']);

    onProgress?.call(
      const MasterDownloadProgress(
        value: .8,
        label: 'Memperbarui penyimpanan lokal...',
      ),
    );
    await _local.replaceValidatedMasterData(
      products: products,
      outlets: outlets,
    );
    await LocalStorage.appBox.put('order_policy', orderPolicy);
    onProgress?.call(
      const MasterDownloadProgress(
        value: .88,
        label: 'Memperbarui promosi, file, dan master rute...',
      ),
    );
    final extra = await _downloadAdditionalMasterData();
    final generatedAt =
        response['generatedAt']?.toString() ??
        DateTime.now().toUtc().toIso8601String();
    await LocalStorage.appBox.put(
      'last_master_download_at',
      DateTime.now().toIso8601String(),
    );
    final localToday = DateTime.now();
    await LocalStorage.appBox.put(
      'last_master_download_day',
      '${localToday.year}-${localToday.month}-${localToday.day}',
    );
    await LocalStorage.appBox.put('last_master_generated_at', generatedAt);
    await LocalStorage.appBox.put(
      'last_master_revision',
      response['revision']?.toString() ?? '',
    );
    await LocalStorage.appBox.put(
      'last_master_products_count',
      products.length,
    );
    await LocalStorage.appBox.put('last_master_outlets_count', outlets.length);
    await LocalStorage.appBox.put('last_master_routes_count', extra.routes);
    await LocalStorage.appBox.put(
      'last_master_promotions_count',
      extra.promotions,
    );
    await LocalStorage.appBox.put('last_master_files_count', extra.files);
    onProgress?.call(
      const MasterDownloadProgress(
        value: 1,
        label: 'Data terbaru siap digunakan.',
      ),
    );
    return MasterDataDownloadResult(
      products: products.length,
      outlets: outlets.length,
      routes: extra.routes,
      promotions: extra.promotions,
      files: extra.files,
      generatedAt: generatedAt,
    );
  }

  Future<_AdditionalMasterData> _downloadAdditionalMasterData() async {
    var routes = 0;
    await _downloadReceivableCache();
    try {
      final assignments = await _api.get<List<dynamic>>(
        ApiEndpoints.routeAssignments,
      );
      final records = assignments
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      final box = Hive.isBoxOpen('route_master_cache')
          ? Hive.box('route_master_cache')
          : await Hive.openBox('route_master_cache');
      await box.put('records', records);
      routes = records.length;
      try {
        final sales = await _api.get<List<dynamic>>(ApiEndpoints.routeSales);
        await box.put(
          'sales',
          sales
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList(),
        );
      } catch (_) {
        // Sales biasa tidak selalu berhak melihat seluruh daftar sales. Cache
        // assignment tetap valid dan tetap dapat digunakan offline.
      }
    } catch (_) {
      // Cache master rute sebelumnya tidak diganti ketika endpoint gagal.
    }

    // Promosi/file bukan prasyarat untuk master produk dan outlet. Jangan
    // batalkan snapshot atomik hanya karena salah satu endpoint tambahan
    // sedang bermasalah; cache terakhir untuk dataset tersebut dipertahankan.
    final information = InformationRepository(apiClient: _api);
    var promotions = 0;
    var files = 0;
    try {
      promotions = (await information.getPromotions(online: true)).length;
    } catch (_) {
      // Dataset promosi sebelumnya tetap tersedia offline.
    }
    try {
      files = (await information.getFiles(online: true)).length;
    } catch (_) {
      // Dataset file sebelumnya tetap tersedia offline.
    }
    return _AdditionalMasterData(
      routes: routes,
      promotions: promotions,
      files: files,
    );
  }

  /// Piutang yang pernah diunduh tetap dapat dibuka saat perangkat offline.
  /// Cache ini hanya untuk tampilan dan pengisian formulir; backend tetap
  /// memvalidasi saldo faktur kembali ketika pembayaran disinkronkan.
  Future<void> _downloadReceivableCache() async {
    try {
      final response = await _api.get<Map<String, dynamic>>(
        ApiEndpoints.paymentReceivablesSnapshot,
      );
      final rawItems = response['items'];
      if (rawItems is! List) return;
      final box = Hive.isBoxOpen('payment_receivables_cache')
          ? Hive.box('payment_receivables_cache')
          : await Hive.openBox('payment_receivables_cache');
      final replacement = <String, Map<String, dynamic>>{};
      for (final raw in rawItems) {
        if (raw is! Map) continue;
        final item = Map<String, dynamic>.from(raw);
        final outlet = item['outlet'];
        if (outlet is! Map) continue;
        final outletId = outlet['id']?.toString();
        if (outletId == null || outletId.isEmpty) continue;
        replacement[outletId] = item;
      }
      if (replacement.isEmpty && rawItems.isNotEmpty) return;
      final previous = Map<dynamic, dynamic>.from(box.toMap());
      try {
        await box.clear();
        await box.putAll(replacement);
      } catch (_) {
        await box.clear();
        await box.putAll(previous);
        rethrow;
      }
    } catch (_) {
      // Dataset piutang tambahan tidak boleh merusak snapshot master yang
      // telah tervalidasi. Cache pembayaran terakhir tetap dipertahankan.
    }
  }

  List<ProductModel> _products(dynamic raw) {
    if (raw is! List) {
      throw const FormatException('Dataset products tidak valid.');
    }
    return raw.map((item) {
      if (item is! Map) {
        throw const FormatException('Satu atau lebih data produk tidak valid.');
      }
      final product = ProductModel.fromJson(Map<String, dynamic>.from(item));
      if (product.id.isEmpty ||
          product.sku.isEmpty ||
          product.divisionCode.isEmpty) {
        throw const FormatException(
          'Produk wajib memiliki ID, SKU, dan divisi sales.',
        );
      }
      return product;
    }).toList();
  }

  List<OutletModel> _outlets(dynamic raw) {
    if (raw is! List)
      throw const FormatException('Dataset outlets tidak valid.');
    return raw.map((item) {
      if (item is! Map)
        throw const FormatException('Satu atau lebih data outlet tidak valid.');
      return OutletModel.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  Map<String, dynamic> _orderPolicy(dynamic raw) {
    if (raw is! Map) {
      return const {
        'minimumUnits': 1,
        'maximumUnits': 1000,
        'minimumAmount': 0.0,
        'maximumAmount': 0.0,
      };
    }
    final minimumUnits = _integer(
      raw['minimumUnits'],
      fallback: 1,
    ).clamp(1, 100000).toInt();
    final maximumUnits = _integer(
      raw['maximumUnits'],
      fallback: 1000,
    ).clamp(minimumUnits, 100000).toInt();
    return {
      'minimumUnits': minimumUnits,
      'maximumUnits': maximumUnits,
      'minimumAmount': _number(raw['minimumAmount']),
      'maximumAmount': _number(raw['maximumAmount']),
    };
  }

  int _integer(dynamic value, {required int fallback}) => value is num
      ? value.toInt()
      : int.tryParse(value?.toString() ?? '') ?? fallback;
  double _number(dynamic value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;
}

class MasterDownloadProgress {
  const MasterDownloadProgress({required this.value, required this.label});
  final double value;
  final String label;
}

class MasterDataDownloadResult {
  const MasterDataDownloadResult({
    required this.products,
    required this.outlets,
    required this.routes,
    required this.promotions,
    required this.files,
    required this.generatedAt,
  });
  final int products;
  final int outlets;
  final int routes;
  final int promotions;
  final int files;
  final String generatedAt;
}

class _AdditionalMasterData {
  const _AdditionalMasterData({
    required this.routes,
    required this.promotions,
    required this.files,
  });
  final int routes;
  final int promotions;
  final int files;
}
