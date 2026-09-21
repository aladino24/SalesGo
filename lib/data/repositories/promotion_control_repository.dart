import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';

class PromotionControlRepository {
  PromotionControlRepository({ApiClient? apiClient}) : _api = apiClient ?? Get.find<ApiClient>();
  final ApiClient _api;

  Future<Map<String, dynamic>> dashboard() => _api.get<Map<String, dynamic>>(ApiEndpoints.promotionDashboard);

  Future<void> requestSpecial({
    required String outletId,
    required String type,
    required String reason,
    required DateTime startsAt,
    required DateTime endsAt,
    String? promotionId,
    double? value,
    int? quantity,
    double? potentialRevenue,
  }) async {
    await _api.post<Map<String, dynamic>>(
      ApiEndpoints.promotionSpecialRequests,
      data: {
        'outletId': int.tryParse(outletId) ?? outletId,
        if (promotionId != null) 'promotionId': int.tryParse(promotionId) ?? promotionId,
        'requestedType': type,
        if (value != null) 'requestedValue': value,
        if (quantity != null) 'requestedQuantity': quantity,
        if (potentialRevenue != null) 'potentialRevenue': potentialRevenue,
        'reason': reason,
        'startsAt': startsAt.toIso8601String(),
        'endsAt': endsAt.toIso8601String(),
      },
      idempotencyKey: const Uuid().v4(),
    );
  }
}
