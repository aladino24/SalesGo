import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/location/location_service.dart';
import '../../core/location/route_estimate_service.dart';
import '../../data/models/visit_model.dart';
import '../../data/models/journey_model.dart';
import '../../data/models/outlet_model.dart';
import '../../data/repositories/visit_repository.dart';
import '../../data/repositories/journey_repository.dart';
import '../../data/repositories/master_repository.dart';
import '../../core/auth/session_service.dart';

class VisitController extends GetxController with WidgetsBindingObserver {
  VisitController({VisitRepository? repository, JourneyRepository? journeyRepository, LocationService? locationService, RouteEstimateService? routeService})
      : _repository = repository ?? VisitRepository(),
        _journeyRepository = journeyRepository ?? JourneyRepository(),
        _locationService = locationService ?? LocationService(),
        _routeService = routeService ?? RouteEstimateService();

  final VisitRepository _repository;
  final JourneyRepository _journeyRepository;
  final LocationService _locationService;
  final RouteEstimateService _routeService;

  final RxString status = 'Planned'.obs;
  final RxInt totalOutlet = 0.obs;
  final RxList<VisitModel> visits = <VisitModel>[].obs;
  final RxList<VisitModel> optionalRouteVisits = <VisitModel>[].obs;
  final Rxn<JourneyModel> activeJourney = Rxn<JourneyModel>();
  final Rxn<VisitModel> activeVisit = Rxn<VisitModel>();
  final RxBool isLoading = false.obs;
  final Rxn<LocationSnapshot> currentLocation = Rxn<LocationSnapshot>();
  final RxMap<String, RouteEstimate> routeEstimates = <String, RouteEstimate>{}.obs;
  final requiredOnly = true.obs;
  final RxString searchTerm = ''.obs;
  final RxBool isStartingJourney = false.obs;
  final RxDouble journeyStartProgress = 0.0.obs;
  final RxString journeyStartLabel = ''.obs;
  Timer? _calendarWatcher;
  String _calendarDay = '';

  void selectVisitCategory(bool value) => requiredOnly.value = value;

  void searchOutlets(String value) => searchTerm.value = value;

  @override
  void onInit() {
    super.onInit();
    _calendarDay = _todayKey();
    WidgetsBinding.instance.addObserver(this);
    loadVisits();
    _calendarWatcher = Timer.periodic(const Duration(minutes: 1), (_) {
      final day = _todayKey();
      if (day == _calendarDay) return;
      _calendarDay = day;
      unawaited(loadVisits());
    });
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _calendarWatcher?.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final day = _todayKey();
    if (day == _calendarDay) return;
    _calendarDay = day;
    unawaited(loadVisits());
  }

  Future<void> loadVisits() async {
    isLoading.value = true;
    try {
      activeJourney.value =
          await _journeyRepository.activeJourneyForToday();
      // Cache adalah sumber tampilan utama. Data server masuk ke cache hanya
      // melalui Download Data Terbaru/Pulihkan State, sehingga buka halaman
      // kunjungan tetap cepat dan konsisten saat jaringan berubah.
      final data = await _repository.getVisits(isOnline: false);
      final hydratedVisits = await _hydrateRequiredRouteVisits(data);
      visits.assignAll(hydratedVisits);
      optionalRouteVisits.assignAll(await _loadOptionalRouteVisits(hydratedVisits));
      activeVisit.value = _findActive(hydratedVisits);
      totalOutlet.value = requiredTodayVisits.length + optionalRouteVisits.length;
    } finally {
      isLoading.value = false;
    }
    // GPS dan estimate rute tidak boleh menahan tampilan daftar kunjungan.
    unawaited(loadRouteEstimates());
  }

  /// Dipakai setelah notifikasi keputusan approval agar cache visit lokal
  /// segera memantulkan status server (mis. Pending menjadi In Progress).
  Future<void> refreshFromServer() async {
    isLoading.value = true;
    try {
      activeJourney.value = await _journeyRepository.activeJourneyForToday();
      final data = await _repository.getVisits(isOnline: true);
      final hydratedVisits = await _hydrateRequiredRouteVisits(data);
      visits.assignAll(hydratedVisits);
      optionalRouteVisits.assignAll(
        await _loadOptionalRouteVisits(hydratedVisits),
      );
      activeVisit.value = _findActive(hydratedVisits);
      totalOutlet.value = requiredTodayVisits.length + optionalRouteVisits.length;
    } finally {
      isLoading.value = false;
    }
    unawaited(loadRouteEstimates());
  }

  Future<void> loadRouteEstimates() async {
    try {
      routeEstimates.clear();
      final location = await _locationService.currentLocation();
      currentLocation.value = location;
      final routeVisits = [
        ...requiredTodayVisits,
        ...optionalRouteVisits,
      ].where((visit) => visit.latitude != null && visit.longitude != null && visit.status != 'Completed').toList();
      for (final visit in routeVisits) {
        routeEstimates[visit.id] = await _routeService.estimate(origin: location, destinationLatitude: visit.latitude!, destinationLongitude: visit.longitude!);
      }
    } on LocationFailure {
      // The visit list remains usable when the user declines location access.
    }
  }

  void beginJourneyStart() {
    isStartingJourney.value = true;
    journeyStartProgress.value = .12;
    journeyStartLabel.value = 'Menyiapkan perjalanan...';
  }

  void updateJourneyStartProgress(double value, String label) {
    journeyStartProgress.value = value;
    journeyStartLabel.value = label;
  }

  void finishJourneyStart() {
    journeyStartProgress.value = 1;
    journeyStartLabel.value = 'Rencana kunjungan siap offline.';
    isStartingJourney.value = false;
  }

  List<VisitModel> recommendedRoute(List<VisitModel> source) {
    final remaining = source.where((visit) => visit.status != 'Completed' && visit.latitude != null && visit.longitude != null).toList();
    final result = <VisitModel>[];
    var latitude = currentLocation.value?.latitude;
    var longitude = currentLocation.value?.longitude;
    while (remaining.isNotEmpty) {
      if (latitude == null || longitude == null) {
        result.addAll(remaining);
        break;
      }
      remaining.sort((a, b) => _locationService.distanceInMeters(fromLatitude: latitude!, fromLongitude: longitude!, toLatitude: a.latitude!, toLongitude: a.longitude!).compareTo(_locationService.distanceInMeters(fromLatitude: latitude!, fromLongitude: longitude!, toLatitude: b.latitude!, toLongitude: b.longitude!)));
      final next = remaining.removeAt(0);
      result.add(next);
      latitude = next.latitude;
      longitude = next.longitude;
    }
    return result;
  }

  void updateStatus(String value) => status.value = value;

  void setActiveVisit(VisitModel visit) {
    final index = visits.indexWhere((item) => item.id == visit.id);
    if (index >= 0) {
      visits[index] = visit;
    } else {
      visits.add(visit);
    }
    activeVisit.value = visit;
  }

  void closeActiveVisit(String visitId, String status) {
    final index = visits.indexWhere((item) => item.id == visitId);
    if (index >= 0) visits[index] = visits[index].copyWith(status: status);
    if (activeVisit.value?.id == visitId) activeVisit.value = null;
  }

  List<VisitModel> get requiredTodayVisits {
    final journey = activeJourney.value;
    if (journey == null) return const <VisitModel>[];
    return visits.where((visit) {
      if (!visit.isRequired || !_isToday(visit)) return false;
      return visit.journeyId == journey.id || visit.journeyId == journey.serverId;
    }).toList();
  }

  List<VisitModel> get currentCategoryVisits =>
      requiredOnly.value ? requiredTodayVisits : optionalRouteVisits;

  bool _isToday(VisitModel visit) {
    final date = DateTime.tryParse(visit.plannedFor ?? '')?.toLocal() ??
        visit.createdAt.toLocal();
    final today = DateTime.now();
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  String _todayKey() {
    final today = DateTime.now();
    return '${today.year}-${today.month}-${today.day}';
  }

  /// Setelah pemulihan state, endpoint visit mungkin belum sempat mengirim
  /// ulang snapshot terbaru. Bentuk daftar wajib dari cache master rute agar
  /// journey aktif tetap langsung dapat dipakai offline.
  Future<List<VisitModel>> _hydrateRequiredRouteVisits(
    List<VisitModel> existingVisits,
  ) async {
    final journey = activeJourney.value;
    if (journey == null) return existingVisits;

    final box = Hive.isBoxOpen('route_master_cache')
        ? Hive.box('route_master_cache')
        : await Hive.openBox('route_master_cache');
    final records = box.get('records');
    if (records is! List) return existingVisits;

    final masterOutlets = await MasterRepository().getOutlets(isOnline: false);
    final outletsById = <String, OutletModel>{
      for (final outlet in masterOutlets) outlet.id: outlet,
    };
    final today = DateTime.now();
    final dateKey =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final week = ((today.day - 1) ~/ 7 + 1).clamp(1, 4).toInt();
    final userId = Get.find<SessionService>().userId.value;
    final merged = <String, VisitModel>{
      for (final visit in existingVisits) visit.id: visit,
    };

    for (final raw in records.whereType<Map>()) {
      final record = Map<String, dynamic>.from(raw);
      if (userId.isNotEmpty && record['salesId']?.toString() != userId) {
        continue;
      }
      if (record['isActive'] == false ||
          (record['dayOfWeek'] as num?)?.toInt() != today.weekday ||
          (record['weekOfMonth'] as num?)?.toInt() != week) {
        continue;
      }
      final outletRaw = record['outlet'];
      final outlet = outletRaw is Map
          ? Map<String, dynamic>.from(outletRaw)
          : <String, dynamic>{};
      final outletId = (record['outletId'] ?? outlet['id'])?.toString() ?? '';
      if (outletId.isEmpty) continue;
      final exists = merged.values.any((visit) =>
          visit.isRequired &&
          visit.outletId == outletId &&
          _isToday(visit) &&
          (visit.journeyId == journey.id ||
              visit.journeyId == journey.serverId));
      if (exists) continue;
      final cachedOutlet = outletsById[outletId];
      final id = 'REQUIRED-${journey.serverId ?? journey.id}-$outletId-$dateKey';
      merged[id] = VisitModel(
        id: id,
        outletName:
            outlet['name']?.toString() ?? cachedOutlet?.name ?? 'Outlet',
        status: 'Planned',
        distanceKm: 0,
        salesName: Get.find<SessionService>().userName.value,
        createdAt: today,
        outletId: outletId,
        latitude: _coordinate(outlet['latitude'], cachedOutlet?.latitude),
        longitude: _coordinate(outlet['longitude'], cachedOutlet?.longitude),
        journeyId: journey.serverId ?? journey.id,
        isRequired: true,
        plannedFor: dateKey,
        outletAddress:
            outlet['address']?.toString() ?? cachedOutlet?.address,
        outletCode: outlet['code']?.toString() ?? cachedOutlet?.code,
      );
    }
    return merged.values.toList();
  }

  Future<List<VisitModel>> _loadOptionalRouteVisits(
    List<VisitModel> existingVisits,
  ) async {
    final box = Hive.isBoxOpen('route_master_cache')
        ? Hive.box('route_master_cache')
        : await Hive.openBox('route_master_cache');
    final records = box.get('records');
    final masterOutlets =
        await MasterRepository().getOutlets(isOnline: false);
    final outletsById = <String, OutletModel>{
      for (final outlet in masterOutlets) outlet.id: outlet,
    };
    final outletsByCode = <String, OutletModel>{
      for (final outlet in masterOutlets) outlet.code: outlet,
    };
    final requiredOutletIds = requiredTodayVisits
        .map((visit) => visit.outletId ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    final today = DateTime.now();
    final dateKey =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final currentUserId = Get.find<SessionService>().userId.value;
    final result = <String, VisitModel>{};

    if (records is List) {
      for (final raw in records.whereType<Map>()) {
        final record = Map<String, dynamic>.from(raw);
        final outletRaw = record['outlet'];
        if (outletRaw is! Map) continue;
        if (currentUserId.isNotEmpty &&
            record['salesId']?.toString() != currentUserId) {
          continue;
        }
        final outlet = Map<String, dynamic>.from(outletRaw);
        final outletId = (record['outletId'] ?? outlet['id'])?.toString() ?? '';
        if (outletId.isEmpty || requiredOutletIds.contains(outletId)) continue;
        final cachedOutlet = outletsById[outletId] ??
            outletsByCode[outlet['code']?.toString() ?? ''];
        VisitModel? current;
        for (final visit in existingVisits) {
          if (!visit.isRequired && visit.outletId == outletId && _isToday(visit)) {
            current = visit;
            break;
          }
        }
        result[outletId] = current ?? VisitModel(
          id: 'ROUTE-$outletId-$dateKey',
          outletName:
              outlet['name']?.toString() ?? cachedOutlet?.name ?? 'Outlet',
          status: 'Planned',
          distanceKm: 0,
          salesName: Get.find<SessionService>().userName.value,
          createdAt: today,
          outletId: outletId,
          latitude: _coordinate(outlet['latitude'], cachedOutlet?.latitude),
          longitude:
              _coordinate(outlet['longitude'], cachedOutlet?.longitude),
          isRequired: false,
          plannedFor: dateKey,
          outletAddress:
              outlet['address']?.toString() ?? cachedOutlet?.address,
          outletCode: outlet['code']?.toString() ?? cachedOutlet?.code,
        );
      }
    }

    // Cache rute lama atau versi aplikasi sebelumnya mungkin belum tersedia.
    // Pertahankan kunjungan tidak wajib hari ini sebagai fallback offline.
    for (final visit in existingVisits.where(
      (visit) => !visit.isRequired && _isToday(visit),
    )) {
      final key = visit.outletId ?? visit.outletName;
      if (!requiredOutletIds.contains(key)) result.putIfAbsent(key, () => visit);
    }
    return result.values.toList()
      ..sort((a, b) => a.outletName.compareTo(b.outletName));
  }

  double? _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  double? _coordinate(dynamic value, double? fallback) {
    final parsed = _number(value);
    if (parsed == null || !parsed.isFinite) return fallback;
    return parsed == 0 ? fallback : parsed;
  }

  VisitModel? _findActive(List<VisitModel> items) {
    for (final item in items) {
      if (item.status == 'In Progress') return item;
    }
    return null;
  }
}
