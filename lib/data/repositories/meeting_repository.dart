import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/sync/sync_manager.dart';
import '../models/meeting_model.dart';

class MeetingRepository {
  MeetingRepository({ApiClient? apiClient, SyncManager? syncManager})
      : _api = apiClient ?? Get.find<ApiClient>(),
        _syncManager = syncManager ?? Get.find<SyncManager>();

  final ApiClient _api;
  final SyncManager _syncManager;

  Future<List<MeetingModel>> getMeetings({required bool online}) async {
    final box = await _box();
    if (online) {
      try {
        final response = await _api.get<dynamic>(ApiEndpoints.meetings);
        final records = response is List
            ? response
            : response is Map
                ? (response['meetings'] as List? ?? const [])
                : const [];
        await box.clear();
        for (final record in records.whereType<Map>()) {
          final map = Map<String, dynamic>.from(record);
          final id = map['id']?.toString();
          if (id != null && id.isNotEmpty) await box.put(id, map);
        }
      } catch (_) {
        // Cached meetings remain available if server refresh fails.
      }
    }
    final meetings = box.values.whereType<Map>().map((item) => MeetingModel.fromJson(Map<String, dynamic>.from(item))).toList();
    meetings.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return meetings;
  }

  Future<void> schedule(MeetingModel item) async {
    final box = await _box();
    await box.put(item.id, item.toJson());
    const uuid = Uuid();
    await _syncManager.queueItem(
      type: 'meeting_create',
      endpoint: ApiEndpoints.meetings,
      method: 'POST',
      payload: item.toJson(),
      uuid: item.id,
      idempotencyKey: uuid.v4(),
    );
  }

  Future<String> join(MeetingModel item, {required bool online}) async {
    if (!online || item.joinUrl.isEmpty) return item.joinUrl;
    final response = await _api.post<dynamic>('${ApiEndpoints.meetings}/${item.id}/join');
    if (response is Map) return response['joinUrl']?.toString() ?? item.joinUrl;
    return item.joinUrl;
  }

  Future<String> joinByCode(String meetingId) async {
    final response = await _api.post<dynamic>(ApiEndpoints.meetingJoinByCode, data: {'meetingId': meetingId});
    return response is Map ? response['joinUrl']?.toString() ?? '' : '';
  }

  Future<Box> _box() => Hive.isBoxOpen('meetings') ? Future.value(Hive.box('meetings')) : Hive.openBox('meetings');
}
