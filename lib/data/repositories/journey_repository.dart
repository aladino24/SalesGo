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

  Future<JourneyModel> create(JourneyModel item) async {
    await (await _box).put(item.id, item.toJson());
    const uuid = Uuid();
    final idempotencyKey = uuid.v4();
    if (await _network.isConnected) {
      try {
        final response = await _api.post<dynamic>(ApiEndpoints.journeys, data: item.toJson(), idempotencyKey: idempotencyKey);
        if (response is Map) {
          final saved = JourneyModel.fromJson(Map<String, dynamic>.from(response));
          if (saved.serverId == null || saved.serverId!.isEmpty) {
            throw const FormatException('Server tidak mengembalikan ID perjalanan.');
          }
          await (await _box).put(item.id, saved.toJson());
          return saved;
        }
        throw const FormatException('Respons pembuatan perjalanan tidak valid.');
      } catch (_) {
        // Respons dapat hilang setelah server menerima request. Simpan operasi
        // dengan key yang sama agar retry adalah replay idempoten, bukan create
        // perjalanan baru.
      }
    }
    await _sync.queueItem(type: 'journey_create', endpoint: ApiEndpoints.journeys, method: 'POST', payload: item.toJson(), uuid: item.id, idempotencyKey: idempotencyKey);
    return item;
  }

  Future<void> updateStatus(JourneyModel item, String status, {String? reason}) async {
    final updated = item.copyWith(status: status);
    await (await _box).put(item.id, updated.toJson());
    const uuid = Uuid();
    final idempotencyKey = uuid.v4();
    final payload = {'status': status, if (reason != null && reason.isNotEmpty) 'reason': reason};
    final journeyId = item.serverId;
    if (journeyId == null || journeyId.isEmpty) throw StateError('Perjalanan belum tersinkron ke server.');
    final endpoint = '${ApiEndpoints.journeys}/$journeyId/status';
    if (await _network.isConnected) {
      try {
        final response = await _api.patch<dynamic>(endpoint, data: payload, idempotencyKey: idempotencyKey);
        if (response is Map) await (await _box).put(item.id, JourneyModel.fromJson(Map<String, dynamic>.from(response)).toJson());
        await _recordActivity(item, status);
        return;
      } catch (_) {}
    }
    final operationId = uuid.v4();
    await _sync.queueItem(type: 'journey_status', endpoint: endpoint, method: 'PATCH', payload: payload, uuid: operationId, idempotencyKey: idempotencyKey);
    await _recordActivity(item, status);
  }

  Future<void> start(JourneyModel item) async {
    final resolved = await _resolveServerJourney(item);
    final serverId = resolved.serverId;
    if (serverId == null || serverId.isEmpty) throw StateError('Perjalanan belum tersinkron ke server.');
    const uuid = Uuid();
    final response = await _api.post<dynamic>('${ApiEndpoints.journeys}/$serverId/start', data: const <String, dynamic>{}, idempotencyKey: uuid.v4());
    if (response is Map) await (await _box).put(item.id, JourneyModel.fromJson(Map<String, dynamic>.from(response)).toJson());
    await _recordActivity(resolved, 'Active');
  }

  Future<JourneyModel> _resolveServerJourney(JourneyModel item) async {
    if (item.serverId != null && item.serverId!.isNotEmpty) return item;
    if (!await _network.isConnected) return item;

    final response = await _api.get<dynamic>(ApiEndpoints.journeys);
    if (response is List) {
      for (final value in response.whereType<Map>()) {
        final remote = JourneyModel.fromJson(Map<String, dynamic>.from(value));
        if (remote.id == item.id && remote.serverId != null && remote.serverId!.isNotEmpty) {
          await (await _box).put(item.id, remote.toJson());
          return remote;
        }
      }
    }

    // Journey dari aplikasi versi sebelumnya mungkin hanya ada di Hive karena
    // respons create gagal/tidak tersimpan. Kirim ulang dengan client ID yang
    // sama; backend memakai firstOrCreate sehingga tidak menggandakan data.
    const uuid = Uuid();
    final created = await _api.post<dynamic>(
      ApiEndpoints.journeys,
      data: item.toJson(),
      idempotencyKey: uuid.v4(),
    );
    if (created is! Map) {
      throw const FormatException('Respons sinkronisasi perjalanan tidak valid.');
    }
    final remote = JourneyModel.fromJson(Map<String, dynamic>.from(created));
    if (remote.serverId == null || remote.serverId!.isEmpty) {
      throw const FormatException('Server tidak mengembalikan ID perjalanan.');
    }
    await (await _box).put(item.id, remote.toJson());
    return remote;
  }

  List<JourneyModel> _sorted(List<JourneyModel> items) => items..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Future<void> _recordActivity(JourneyModel item, String status) async {
    if (status != 'Active' && status != 'Completed') return;
    final box = Hive.isBoxOpen('journey_activities')
        ? Hive.box('journey_activities')
        : await Hive.openBox('journey_activities');
    final event = status == 'Active' ? 'Perjalanan dimulai' : 'Perjalanan diakhiri';
    final id = '${item.id}-$status';
    await box.put(id, {
      'id': id,
      'journeyId': item.id,
      'event': event,
      'description': item.destination,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
