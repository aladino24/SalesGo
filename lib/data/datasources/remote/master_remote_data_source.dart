import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../models/outlet_model.dart';
import '../../models/product_model.dart';

class MasterRemoteDataSource {
  MasterRemoteDataSource({ApiClient? apiClient}) : _apiClient = apiClient ?? Get.find<ApiClient>();

  final ApiClient _apiClient;

  Future<List<ProductModel>> getProducts() async {
    final response = await _apiClient.get<List<dynamic>>(ApiEndpoints.products);
    return response.map((item) => ProductModel.fromJson(Map<String, dynamic>.from(item as Map))).toList();
  }

  Future<List<OutletModel>> getOutlets() async {
    final response = await _apiClient.get<List<dynamic>>(ApiEndpoints.outlets);
    return response.map((item) => OutletModel.fromJson(Map<String, dynamic>.from(item as Map))).toList();
  }
}
