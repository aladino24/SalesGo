import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/network_info.dart';
import '../../core/sync/sync_manager.dart';
import '../models/delivery_note_model.dart';

class DeliveryNoteRepository {
  DeliveryNoteRepository({ApiClient? apiClient, NetworkInfo? networkInfo, SyncManager? syncManager})
      : _api = apiClient ?? Get.find<ApiClient>(),
        _network = networkInfo ?? Get.find<NetworkInfo>(),
        _sync = syncManager ?? Get.find<SyncManager>();

  final ApiClient _api;
  final NetworkInfo _network;
  final SyncManager _sync;

  Future<Box> get _box async => Hive.isBoxOpen('delivery_notes') ? Hive.box('delivery_notes') : Hive.openBox('delivery_notes');

  Future<List<DeliveryNoteModel>> all() async {
    if (await _network.isConnected) {
      try {
        final response = await _api.get<dynamic>(ApiEndpoints.deliveryNotes);
        final remote = (response is List ? response : <dynamic>[]).whereType<Map>().map((value) => DeliveryNoteModel.fromJson(Map<String, dynamic>.from(value))).toList();
        final box = await _box;
        await box.clear();
        for (final item in remote) { await box.put(item.id, item.toJson()); }
        return _sorted(remote);
      } catch (_) {}
    }
    return _sorted((await _box).values.whereType<Map>().map((value) => DeliveryNoteModel.fromJson(Map<String, dynamic>.from(value))).toList());
  }

  Future<void> create(DeliveryNoteModel item) async {
    await (await _box).put(item.id, item.toJson());
    const uuid = Uuid();
    if (await _network.isConnected) {
      try {
        final response = await _api.post<dynamic>(ApiEndpoints.deliveryNotes, data: item.toJson(), idempotencyKey: uuid.v4());
        if (response is Map) await (await _box).put(item.id, DeliveryNoteModel.fromJson(Map<String, dynamic>.from(response)).toJson());
        return;
      } catch (_) {}
    }
    await _sync.queueItem(type: 'delivery_note_create', endpoint: ApiEndpoints.deliveryNotes, method: 'POST', payload: item.toJson(), uuid: item.id, idempotencyKey: uuid.v4());
  }

  Future<void> changeStatus(DeliveryNoteModel item, String status) async {
    final action = switch (status) { 'Submitted' => 'submit', 'Completed' => 'use', 'Cancelled' => 'cancel', _ => null };
    if (action == null) throw ArgumentError.value(status, 'status', 'Status surat jalan tidak didukung backend.');
    final updated = item.copyWith(status: status, approvalStatus: status == 'Submitted' ? 'Waiting Approval' : item.approvalStatus);
    await (await _box).put(item.id, updated.toJson());
    const uuid = Uuid();
    final endpoint = '${ApiEndpoints.deliveryNotes}/${item.id}/$action';
    if (await _network.isConnected) {
      try {
        final response = await _api.post<dynamic>(endpoint, data: const <String, dynamic>{}, idempotencyKey: uuid.v4());
        if (response is Map) await (await _box).put(item.id, DeliveryNoteModel.fromJson(Map<String, dynamic>.from(response)).toJson());
        return;
      } catch (_) {}
    }
    await _sync.queueItem(type: 'delivery_note_$action', endpoint: endpoint, method: 'POST', payload: const <String, dynamic>{}, uuid: uuid.v4(), idempotencyKey: uuid.v4());
  }

  List<DeliveryNoteModel> _sorted(List<DeliveryNoteModel> items) => items..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}
