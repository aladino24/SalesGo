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
      final online = await _networkInfo.isConnected;
      final data = await _repository.getProducts(isOnline: online);
      products.assignAll(data);
    } finally {
      isLoading.value = false;
    }
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
