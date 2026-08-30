import 'package:get/get.dart';
import 'package:salesgo/core/auth/app_roles.dart';

import '../../core/auth/session_service.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/network_info.dart';
import '../../data/repositories/monitoring_repository.dart';

class MonitoringController extends GetxController {
  MonitoringController({
    MonitoringRepository? repository,
    NetworkInfo? networkInfo,
    SessionService? session,
  }) : _repository = repository ?? MonitoringRepository(),
       _networkInfo = networkInfo ?? Get.find<NetworkInfo>(),
       _session = session ?? Get.find<SessionService>();

  final MonitoringRepository _repository;
  final NetworkInfo _networkInfo;
  final SessionService _session;
  final members = <Map<String, dynamic>>[].obs;
  final activities = <Map<String, dynamic>>[].obs;
  final visits = <Map<String, dynamic>>[].obs;
  final performance = <Map<String, dynamic>>[].obs;
  final locationHistory = <Map<String, dynamic>>[].obs;
  final selectedTrackingMemberId = ''.obs;
  final selectedActivityMemberId = ''.obs;
  final isLoading = false.obs;
  final isTrackingLoading = false.obs;
  final isActivityLoading = false.obs;

  bool get isAllowed => _session.currentRole.value?.canMonitorTeam ?? false;

  Map<String, dynamic>? get selectedTrackingMember {
    for (final member in members) {
      if (member['id']?.toString() == selectedTrackingMemberId.value)
        return member;
    }
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    if (!isAllowed) return;
    isLoading.value = true;
    try {
      final online = await _networkInfo.isConnected;
      final team = await _repository.getList(
        endpoint: ApiEndpoints.monitoringTeam,
        cacheKey: 'team',
        online: online,
      );
      members.assignAll(team);
      visits.assignAll(
        team
            .where((item) => item['activeVisit'] is Map)
            .map(
              (item) => {
                ...Map<String, dynamic>.from(item['activeVisit'] as Map),
                'salesName': item['name'],
                'employeeCode': item['employeeCode'],
                'role': item['role'],
              },
            )
            .toList(),
      );
      performance.clear();
      if (selectedTrackingMemberId.value.isEmpty && members.isNotEmpty)
        selectedTrackingMemberId.value = members.first['id'].toString();
      if (selectedActivityMemberId.value.isNotEmpty &&
          !members.any(
            (item) => item['id']?.toString() == selectedActivityMemberId.value,
          ))
        selectedActivityMemberId.value = '';
      await Future.wait([loadActivities(), loadLocationHistory()]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectTrackingMember(String? memberId) async {
    if (memberId == null || memberId == selectedTrackingMemberId.value) return;
    selectedTrackingMemberId.value = memberId;
    await loadLocationHistory();
  }

  Future<void> selectActivityMember(String? memberId) async {
    selectedActivityMemberId.value = memberId ?? '';
    await loadActivities();
  }

  Future<void> loadActivities() async {
    if (!isAllowed) return;
    isActivityLoading.value = true;
    try {
      final online = await _networkInfo.isConnected;
      final filter = selectedActivityMemberId.value;
      final response = await _repository.getPaged(
        endpoint: ApiEndpoints.monitoringActivities,
        cacheKey: 'activities_${filter.isEmpty ? 'all' : filter}',
        online: online,
        query: {'perPage': 50, if (filter.isNotEmpty) 'salesId': filter},
      );
      final raw = response['data'];
      activities.assignAll(
        raw is List
            ? raw
                  .whereType<Map>()
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList()
            : const <Map<String, dynamic>>[],
      );
    } finally {
      isActivityLoading.value = false;
    }
  }

  Future<void> loadLocationHistory() async {
    final memberId = selectedTrackingMemberId.value;
    if (!isAllowed || memberId.isEmpty) {
      locationHistory.clear();
      return;
    }
    isTrackingLoading.value = true;
    try {
      final online = await _networkInfo.isConnected;
      final response = await _repository.getPaged(
        endpoint: '${ApiEndpoints.monitoringTeam}/$memberId/locations',
        cacheKey: 'locations_$memberId',
        online: online,
        query: const {'perPage': 100},
      );
      final raw = response['data'];
      final history = raw is List
          ? raw
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : <Map<String, dynamic>>[];
      history.sort(
        (a, b) => (a['recordedAt']?.toString() ?? '').compareTo(
          b['recordedAt']?.toString() ?? '',
        ),
      );
      locationHistory.assignAll(history);
    } finally {
      isTrackingLoading.value = false;
    }
  }
}
