import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
    // Pemulihan antrean setelah aplikasi dibuka kembali tidak boleh menunggu
    // perubahan sinyal Wi-Fi/data seluler terlebih dahulu.
    Future<void>.microtask(syncNow);
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
    // Beberapa pemicu (koneksi pulih, tombol manual, item baru) dapat datang
    // berdekatan. Satu worker mobile cukup; paralel dapat membuat state queue
    // tampak terus-menerus `syncing`.
    if (isSyncing.value) return;
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
        // Versi lama aplikasi pernah mengantrekan endpoint approval override
        // terpisah yang tidak tersedia. Approval sekarang dibuat atomik oleh
        // endpoint check-in, sehingga item lama aman untuk dibuang.
        if (item.type == 'visit_out_of_radius_approval') {
          await SyncStorage.addAudit(
            item: item,
            event: 'sync_legacy_discarded',
            message: 'Antrean override lama dihapus; approval dibuat saat check-in tersinkron.',
          );
          await SyncStorage.removeItem(item.id);
          continue;
        }
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
      final response = await _dispatchRequest(item.copyWith(payload: payload));
      if (item.type == 'payment_create' && response is Map) {
        final box = Hive.isBoxOpen('payments_local')
            ? Hive.box('payments_local')
            : await Hive.openBox('payments_local');
        final current = box.get(item.uuid);
        final server = Map<String, dynamic>.from(response);
        if (current is Map) {
          server
            ..['id'] = item.uuid
            ..['status'] = server['status']?.toString() ?? 'SUBMITTED'
            ..['createdAt'] = current['createdAt'];
        }
        await box.put(item.uuid, server);
      }

      await SyncStorage.updateItemStatus(item.id, 'success');
      await SyncStorage.addAudit(item: item, event: 'sync_succeeded');
      await SyncStorage.removeItem(item.id);
    } on ApiException catch (e) {
      if (item.type == 'journey_status' && e.statusCode == 422) {
        await SyncStorage.addAudit(item: item, event: 'sync_rejected', message: 'Status perjalanan sudah tidak valid di server; antrean dihapus.');
        await SyncStorage.removeItem(item.id);
        return;
      }
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
      } else if (e.statusCode == 422 &&
          e.message.contains('Foto belum selesai diproses')) {
        await _scheduleRetry(
          item,
          'Foto sedang diproses server; menunggu sebelum mengirim ulang.',
          delay: const Duration(seconds: 15),
        );
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

  Future<void> _scheduleRetry(
    SyncItem item,
    String error, {
    Duration? delay,
  }) async {
    final attempts = item.attemptCount + 1;
    final delayMinutes = 1 << (attempts - 1);
    final retryDelay = delay ??
        Duration(minutes: delayMinutes > 30 ? 30 : delayMinutes);
    final nextAttempt = DateTime.now().add(retryDelay);
    await SyncStorage.updateItemStatus(item.id, 'failed', error: error, nextAttemptAt: nextAttempt, incrementAttempt: true);
    await SyncStorage.addAudit(item: item, event: 'sync_retry_scheduled', message: error, details: {'attempts': attempts, 'nextAttemptAt': nextAttempt.toUtc().toIso8601String()});
  }

  Future<dynamic> _dispatchRequest(SyncItem item) async {
    switch (item.method.toUpperCase()) {
      case 'POST':
        return _apiClient.post<dynamic>(
          item.endpoint,
          data: item.payload,
          idempotencyKey: item.idempotencyKey,
        );
      case 'PUT':
        return _apiClient.put<dynamic>(
          item.endpoint,
          data: item.payload,
          idempotencyKey: item.idempotencyKey,
        );
      case 'PATCH':
        return _apiClient.patch<dynamic>(
          item.endpoint,
          data: item.payload,
          idempotencyKey: item.idempotencyKey,
        );
      case 'DELETE':
        return _apiClient.delete<dynamic>(item.endpoint);
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
