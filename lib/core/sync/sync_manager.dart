import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

import '../../data/models/sync_item_model.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';
import '../network/network_info.dart';
import '../storage/sync_storage.dart';

class SyncManager extends GetxController {
  SyncManager({
    NetworkInfo? networkInfo,
    ApiClient? apiClient,
  })  : _networkInfo = networkInfo ?? NetworkInfo(),
        _apiClient = apiClient ?? Get.find<ApiClient>();

  final NetworkInfo _networkInfo;
  final ApiClient _apiClient;

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

  Future<void> syncNow() async {
    final connected = await _networkInfo.isConnected;
    if (!connected) {
      status.value = 'offline';
      _updateStats();
      return;
    }

    isSyncing.value = true;
    status.value = 'synchronizing';

    try {
      final items = SyncStorage.pendingItems;
      if (items.isEmpty) {
        status.value = 'success';
        await SyncStorage.updateLastSync();
        _updateStats();
        return;
      }

      for (final item in items) {
        await _syncItem(item);
      }

      status.value = 'success';
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
      // Mark as syncing
      await SyncStorage.updateItemStatus(item.id, 'syncing');

      // Dispatch API call based on method
      await _dispatchRequest(item);

      // Mark as success and remove from queue
      await SyncStorage.updateItemStatus(item.id, 'success');
      await SyncStorage.removeItem(item.id);
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        // Conflict: duplicate/conflict detected, mark as conflict
        await SyncStorage.updateItemStatus(
          item.id,
          'conflict',
          error: 'Conflict detected: ${e.message}',
        );
      } else if (e.statusCode == 401 || e.statusCode == 403) {
        // Auth error, mark as failed
        await SyncStorage.updateItemStatus(
          item.id,
          'failed',
          error: 'Auth error: ${e.message}',
        );
      } else {
        // Other API error, keep as pending for retry
        await SyncStorage.updateItemStatus(
          item.id,
          'failed',
          error: e.message,
        );
      }
    } on TimeoutException catch (e) {
      // Timeout, keep as pending for retry
      await SyncStorage.updateItemStatus(
        item.id,
        'failed',
        error: 'Timeout: ${e.message}',
      );
    } on NetworkException catch (e) {
      // Network error, keep as pending for retry
      await SyncStorage.updateItemStatus(
        item.id,
        'failed',
        error: 'Network error: ${e.message}',
      );
    } catch (e) {
      // Unknown error
      await SyncStorage.updateItemStatus(
        item.id,
        'failed',
        error: 'Unknown error: $e',
      );
    }
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
      id: DateTime.now().millisecondsSinceEpoch.toString(),
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
