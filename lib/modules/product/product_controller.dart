import 'package:get/get.dart';

import '../../core/network/network_info.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/master_repository.dart';

class ProductController extends GetxController {
  ProductController({
    MasterRepository? repository,
    NetworkInfo? networkInfo,
  })  : _repository = repository ?? MasterRepository(),
        _networkInfo = networkInfo ?? Get.find<NetworkInfo>();

  final MasterRepository _repository;
  final NetworkInfo _networkInfo;

  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchTerm = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  Future<void> loadProducts() async {
    isLoading.value = true;
    try {
      // Tampilkan cache lebih dulu agar Master Produk tetap responsif saat
      // perangkat tidak memiliki internet atau tunnel backend sedang mati.
      products.assignAll(await _repository.getProducts(isOnline: false));
      final online = await _networkInfo.isConnected;
      if (online) {
        products.assignAll(await _repository.getProducts(isOnline: true));
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshFromCache() async {
    products.assignAll(await _repository.getProducts(isOnline: false));
  }

  List<ProductModel> get filteredProducts {
    final query = searchTerm.value.trim().toLowerCase();
    if (query.isEmpty) {
      return products;
    }

    return products.where((product) {
      return product.name.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query) ||
          product.sku.toLowerCase().contains(query);
    }).toList();
  }
}
