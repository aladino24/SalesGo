import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/network_info.dart';
import '../../core/sync/sync_manager.dart';
import '../models/app_notification_model.dart';

class NotificationRepository {
  NotificationRepository({ApiClient? apiClient, NetworkInfo? networkInfo, SyncManager? syncManager})
      : _api = apiClient ?? Get.find<ApiClient>(), _network = networkInfo ?? Get.find<NetworkInfo>(), _sync = syncManager ?? Get.find<SyncManager>();
  static const _boxName = 'notifications_cache';
  final ApiClient _api;
  final NetworkInfo _network;
  final SyncManager _sync;

  Future<List<AppNotificationModel>> getNotifications({bool refresh = true}) async {
    final box = await _box;
    if (refresh && await _network.isConnected) {
      try {
        final response = await _api.get<dynamic>(ApiEndpoints.notifications, queryParameters: {'limit': 50});
        final records = response is Map ? (response['data'] as List? ?? const []) : response is List ? response : const [];
        await box.clear();
        for (final record in records.whereType<Map>()) {
          final item = AppNotificationModel.fromJson(Map<String, dynamic>.from(record));
          if (item.id.isNotEmpty) await box.put(item.id, item.toJson());
        }
      } catch (_) {
        // Retain the most recent feed cache when refreshing fails.
      }
    }
    final items = box.values.whereType<Map>().map((value) => AppNotificationModel.fromJson(Map<String, dynamic>.from(value))).toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> markRead(AppNotificationModel item) async {
    if (item.isRead || item.id.isEmpty) return;
    final box = await _box;
    await box.put(item.id, item.copyWith(isRead: true).toJson());
    final endpoint = '${ApiEndpoints.notifications}/${item.id}/read';
    if (await _network.isConnected) {
      try {
        await _api.post<dynamic>(endpoint, idempotencyKey: const Uuid().v4());
        return;
      } catch (_) {}
    }
    const uuid = Uuid();
    await _sync.queueItem(type: 'notification_read', endpoint: endpoint, method: 'POST', payload: const {}, uuid: uuid.v4(), idempotencyKey: uuid.v4());
  }

  Future<Box> get _box => Hive.isBoxOpen(_boxName) ? Future.value(Hive.box(_boxName)) : Hive.openBox(_boxName);
}
