import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/network/network_info.dart';
import '../../core/sync/sync_manager.dart';
import '../models/journey_model.dart';
class JourneyRepository {
  JourneyRepository({ApiClient? apiClient, NetworkInfo? networkInfo, SyncManager? syncManager})
      : _api = apiClient ?? Get.find<ApiClient>(),
        _network = networkInfo ?? Get.find<NetworkInfo>(),
        _sync = syncManager ?? Get.find<SyncManager>();

  final ApiClient _api;
  final NetworkInfo _network;
  final SyncManager _sync;

  Future<Box> get _box async => Hive.isBoxOpen('journeys') ? Hive.box('journeys') : Hive.openBox('journeys');

  Future<List<JourneyModel>> all() async {
    if (await _network.isConnected) {
      try {
        final response = await _api.get<dynamic>(ApiEndpoints.journeys);
        final list = response is List ? response : <dynamic>[];
        final items = list.whereType<Map>().map((item) => JourneyModel.fromJson(Map<String, dynamic>.from(item))).toList();
        final box = await _box;
        final pending = box.values.whereType<Map>().map((value) => JourneyModel.fromJson(Map<String, dynamic>.from(value))).where((item) => item.serverId == null || item.serverId!.isEmpty).toList();
        await box.clear();
        for (final item in items) { await box.put(item.id, item.toJson()); }
        for (final item in pending) { if (!items.any((remote) => remote.id == item.id)) await box.put(item.id, item.toJson()); }
        final state = Hive.isBoxOpen('journey_download_state') ? Hive.box('journey_download_state') : await Hive.openBox('journey_download_state');
        await state.put('lastDownloadedAt', DateTime.now().toUtc().toIso8601String());
        await state.put('periods', items.map((item) => {'id': item.id, 'serverId': item.serverId, 'startsAt': item.startAt.toIso8601String(), 'endsAt': item.endAt.toIso8601String(), 'status': item.status}).toList());
        return _sorted([...items, ...pending.where((item) => !items.any((remote) => remote.id == item.id))]);
      } catch (_) {
        // Cache remains the source of truth while the server is unavailable.
      }
    }
    final items = (await _box).values.whereType<Map>().map((item) => JourneyModel.fromJson(Map<String, dynamic>.from(item))).toList();
    return _sorted(items);
  }

  Future<void> create(JourneyModel item) async {
    await (await _box).put(item.id, item.toJson());
    const uuid = Uuid();
    if (await _network.isConnected) {
      try {
        final response = await _api.post<dynamic>(ApiEndpoints.journeys, data: item.toJson(), idempotencyKey: uuid.v4());
        if (response is Map) await (await _box).put(item.id, JourneyModel.fromJson(Map<String, dynamic>.from(response)).toJson());
        return;
      } catch (_) {}
    }
    await _sync.queueItem(type: 'journey_create', endpoint: ApiEndpoints.journeys, method: 'POST', payload: item.toJson(), uuid: item.id, idempotencyKey: uuid.v4());
  }

  Future<void> updateStatus(JourneyModel item, String status, {String? reason}) async {
    final updated = item.copyWith(status: status);
    await (await _box).put(item.id, updated.toJson());
    const uuid = Uuid();
    final payload = {'status': status, if (reason != null && reason.isNotEmpty) 'reason': reason};
    final endpoint = '${ApiEndpoints.journeys}/${item.id}/status';
    if (await _network.isConnected) {
      try {
        final response = await _api.patch<dynamic>(endpoint, data: payload, idempotencyKey: uuid.v4());
        if (response is Map) await (await _box).put(item.id, JourneyModel.fromJson(Map<String, dynamic>.from(response)).toJson());
        return;
      } catch (_) {}
    }
    await _sync.queueItem(type: 'journey_status', endpoint: endpoint, method: 'PATCH', payload: payload, uuid: uuid.v4(), idempotencyKey: uuid.v4());
  }

  Future<void> start(JourneyModel item) async {
    final serverId = item.serverId;
    if (serverId == null || serverId.isEmpty) throw StateError('Perjalanan belum tersinkron ke server.');
    const uuid = Uuid();
    final response = await _api.post<dynamic>('${ApiEndpoints.journeys}/$serverId/start', data: const <String, dynamic>{}, idempotencyKey: uuid.v4());
    if (response is Map) await (await _box).put(item.id, JourneyModel.fromJson(Map<String, dynamic>.from(response)).toJson());
  }

  List<JourneyModel> _sorted(List<JourneyModel> items) => items..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}
