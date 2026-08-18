import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/api_client.dart';
import '../../../core/sync/sync_manager.dart';
import '../../models/visit_model.dart';

class VisitRemoteDataSource {
  VisitRemoteDataSource({
    ApiClient? apiClient,
    SyncManager? syncManager,
  })  : _apiClient = apiClient ?? Get.find<ApiClient>(),
        _syncManager = syncManager ?? Get.find<SyncManager>();

  final ApiClient _apiClient;
  final SyncManager _syncManager;

  static const _endpoint = '/visits';

  Future<List<VisitModel>> getVisits() async {
    try {
      // Try to fetch from remote API
      final response = await _apiClient.get<List<dynamic>>(_endpoint);
      return response
          .map((item) => VisitModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Fallback to mock data if API fails
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return [
        VisitModel(
          id: 'VIS-2001',
          outletName: 'Outlet Server 1',
          status: 'Pending',
          distanceKm: 5.1,
          salesName: 'Raka',
          createdAt: DateTime.now(),
        ),
      ];
    }
  }

  /// Create visit with offline-first + sync queue support
  Future<VisitModel> createVisit(VisitModel visit) async {
    const uuid = Uuid();
    final txId = uuid.v4(); // Transaction ID for deduplication
    final idempotencyKey = uuid.v4(); // Idempotency key for retry safety

    final payload = {
      'outletName': visit.outletName,
      'status': visit.status,
      'distanceKm': visit.distanceKm,
      'salesName': visit.salesName,
      'createdAt': visit.createdAt.toIso8601String(),
    };

    try {
      // Try online API first
      final response = await _apiClient.post<Map<String, dynamic>>(
        _endpoint,
        data: payload,
        idempotencyKey: idempotencyKey,
      );

      return VisitModel.fromJson(response);
    } catch (e) {
      // If offline or error, queue for sync
      await _syncManager.queueItem(
        type: 'visit_create',
        endpoint: _endpoint,
        method: 'POST',
        payload: payload,
        uuid: txId,
        idempotencyKey: idempotencyKey,
      );

      // Return optimistic response locally
      return visit.copyWith(id: txId);
    }
  }

  /// Update visit with offline-first + sync queue support
  Future<VisitModel> updateVisit(String visitId, VisitModel visit) async {
    const uuid = Uuid();
    final txId = uuid.v4();
    final idempotencyKey = uuid.v4();

    final payload = {
      'status': visit.status,
      'distanceKm': visit.distanceKm,
    };

    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '$_endpoint/$visitId',
        data: payload,
        idempotencyKey: idempotencyKey,
      );

      return VisitModel.fromJson(response);
    } catch (e) {
      await _syncManager.queueItem(
        type: 'visit_update',
        endpoint: '$_endpoint/$visitId',
        method: 'PUT',
        payload: payload,
        uuid: txId,
        idempotencyKey: idempotencyKey,
      );

      return visit;
    }
  }
}
