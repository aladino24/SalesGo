import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

import '../../data/models/sync_item_model.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';
import '../network/network_info.dart';
import '../storage/sync_storage.dart';
import 'attachment_upload_service.dart';

class SyncManager extends GetxController {
  SyncManager({
    NetworkInfo? networkInfo,
    ApiClient? apiClient,
    AttachmentUploadService? attachmentUploadService,
  })  : _networkInfo = networkInfo ?? NetworkInfo(),
        _apiClient = apiClient ?? Get.find<ApiClient>(),
        _attachmentUploadService = attachmentUploadService ?? AttachmentUploadService();

  final NetworkInfo _networkInfo;
  final ApiClient _apiClient;
  final AttachmentUploadService _attachmentUploadService;

  final RxBool isSyncing = false.obs;
  final RxString status = 'offline'.obs;
  final RxMap<String, int> syncStats = <String, int>{}.obs;

  Stream<List<ConnectivityResult>> get connectivityStream =>
      _networkInfo.connectivityStream;

  @override
  void onInit() {
    super.onInit();
    _listenToConnectivity();
  }

  void _listenToConnectivity() {
    connectivityStream.listen((result) {
      final isConnected = !result.contains(ConnectivityResult.none);
      if (isConnected && !isSyncing.value) {
        syncNow();
      }
    });
  }

  Future<void> syncNow({bool force = false}) async {
    final connected = await _networkInfo.isConnected;
    if (!connected) {
      status.value = 'offline';
      _updateStats();
      return;
    }

    isSyncing.value = true;
    status.value = 'synchronizing';

    try {
      final items = SyncStorage.pendingItems(force: force);
      if (items.isEmpty) {
        final stats = SyncStorage.getSyncStats();
        status.value = (stats['failed'] ?? 0) > 0 || (stats['conflict'] ?? 0) > 0 || (stats['blocked'] ?? 0) > 0
            ? 'sync_partial'
            : 'success';
        await SyncStorage.updateLastSync();
        _updateStats();
        return;
      }

      for (final item in items) {
        await _syncItem(item);
      }

      final stats = SyncStorage.getSyncStats();
      status.value = (stats['failed'] ?? 0) > 0 || (stats['conflict'] ?? 0) > 0 || (stats['blocked'] ?? 0) > 0
          ? 'sync_partial'
          : 'success';
      await SyncStorage.updateLastSync();
    } catch (e) {
      status.value = 'sync_failed';
    } finally {
      isSyncing.value = false;
      _updateStats();
    }
  }

  Future<void> _syncItem(SyncItem item) async {
    try {
      await SyncStorage.updateItemStatus(item.id, 'syncing');
      await SyncStorage.addAudit(item: item, event: 'sync_started');

      final payload = await _attachmentUploadService.preparePayload(item.payload);
      if (payload.toString() != item.payload.toString()) {
        await SyncStorage.updateItemPayload(item.id, payload);
      }
      await _dispatchRequest(item.copyWith(payload: payload));

      await SyncStorage.updateItemStatus(item.id, 'success');
      await SyncStorage.addAudit(item: item, event: 'sync_succeeded');
      await SyncStorage.removeItem(item.id);
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        await SyncStorage.updateItemStatus(
          item.id,
          'conflict',
          error: 'Conflict detected: ${e.message}',
          conflict: e.response is Map ? Map<String, dynamic>.from(e.response as Map) : {'message': e.message},
        );
        await SyncStorage.addAudit(item: item, event: 'sync_conflict', message: e.message, details: e.response is Map ? Map<String, dynamic>.from(e.response as Map) : null);
      } else if (e.statusCode == 401 || e.statusCode == 403) {
        await _scheduleRetry(item, 'Auth error: ${e.message}');
      } else {
        await _scheduleRetry(item, e.message);
      }
    } on TimeoutException catch (e) {
      await _scheduleRetry(item, 'Timeout: ${e.message}');
    } on NetworkException catch (e) {
      await _scheduleRetry(item, 'Network error: ${e.message}');
    } catch (e) {
      await _scheduleRetry(item, 'Unknown error: $e');
    }
  }

  Future<void> _scheduleRetry(SyncItem item, String error) async {
    const maxAttempts = 5;
    final attempts = item.attemptCount + 1;
    if (attempts >= maxAttempts) {
      await SyncStorage.updateItemStatus(item.id, 'blocked', error: error, incrementAttempt: true);
      await SyncStorage.addAudit(item: item, event: 'sync_blocked', message: error, details: {'attempts': attempts});
      return;
    }
    final delayMinutes = 1 << (attempts - 1);
    final nextAttempt = DateTime.now().add(Duration(minutes: delayMinutes > 30 ? 30 : delayMinutes));
    await SyncStorage.updateItemStatus(item.id, 'failed', error: error, nextAttemptAt: nextAttempt, incrementAttempt: true);
    await SyncStorage.addAudit(item: item, event: 'sync_retry_scheduled', message: error, details: {'attempts': attempts, 'nextAttemptAt': nextAttempt.toUtc().toIso8601String()});
  }

  Future<void> _dispatchRequest(SyncItem item) async {
    switch (item.method.toUpperCase()) {
      case 'POST':
        await _apiClient.post(
          item.endpoint,
          data: item.payload,
          idempotencyKey: item.idempotencyKey,
        );
      case 'PUT':
        await _apiClient.put(
          item.endpoint,
          data: item.payload,
          idempotencyKey: item.idempotencyKey,
        );
      case 'PATCH':
        await _apiClient.patch(
          item.endpoint,
          data: item.payload,
          idempotencyKey: item.idempotencyKey,
        );
      case 'DELETE':
        await _apiClient.delete(item.endpoint);
      default:
        throw ApiException(
          message: 'Unknown HTTP method: ${item.method}',
          statusCode: 400,
        );
    }
  }

  void _updateStats() {
    syncStats.value = SyncStorage.getSyncStats();
  }

  /// Queue a new sync item (create, update, or delete)
  Future<void> queueItem({
    required String type,
    required String endpoint,
    required String method,
    required Map<String, dynamic> payload,
    required String uuid,
    required String idempotencyKey,
  }) async {
    final item = SyncItem(
      id: uuid,
      uuid: uuid,
      type: type,
      endpoint: endpoint,
      method: method,
      payload: payload,
      status: 'pending',
      idempotencyKey: idempotencyKey,
      createdAt: DateTime.now(),
    );

    await SyncStorage.addItem(item);
    _updateStats();

    // Try to sync immediately if online
    if (await _networkInfo.isConnected) {
      syncNow();
    }
  }
}
