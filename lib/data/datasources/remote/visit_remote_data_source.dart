import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/sync/sync_manager.dart';
import '../../models/visit_model.dart';

class VisitRemoteDataSource {
  VisitRemoteDataSource({ApiClient? apiClient, SyncManager? syncManager})
      : _apiClient = apiClient ?? Get.find<ApiClient>(),
        _syncManager = syncManager ?? Get.find<SyncManager>();

  final ApiClient _apiClient;
  final SyncManager _syncManager;

  Future<List<VisitModel>> getVisits() async {
    final response = await _apiClient.get<List<dynamic>>(ApiEndpoints.visits);
    return response.map((item) => VisitModel.fromJson(Map<String, dynamic>.from(item as Map))).toList();
  }

  Future<VisitModel> createVisit(VisitModel visit) async {
    const uuid = Uuid();
    final transactionId = uuid.v4();
    final idempotencyKey = uuid.v4();
    final payload = visit.toJson();
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.visits,
        data: payload,
        idempotencyKey: idempotencyKey,
      );
      return VisitModel.fromJson(response);
    } catch (_) {
      await _syncManager.queueItem(
        type: 'visit_create',
        endpoint: ApiEndpoints.visits,
        method: 'POST',
        payload: payload,
        uuid: transactionId,
        idempotencyKey: idempotencyKey,
      );
      return visit.copyWith(id: transactionId);
    }
  }
}
