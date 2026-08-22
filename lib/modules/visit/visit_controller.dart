import 'dart:async';

import 'package:get/get.dart';

import '../../core/network/network_info.dart';
import '../../core/location/location_service.dart';
import '../../core/location/route_estimate_service.dart';
import '../../data/models/visit_model.dart';
import '../../data/repositories/visit_repository.dart';

class VisitController extends GetxController {
  VisitController({VisitRepository? repository, NetworkInfo? networkInfo, LocationService? locationService, RouteEstimateService? routeService})
      : _repository = repository ?? VisitRepository(),
        _networkInfo = networkInfo ?? Get.find<NetworkInfo>(),
        _locationService = locationService ?? LocationService(),
        _routeService = routeService ?? RouteEstimateService();

  final VisitRepository _repository;
  final NetworkInfo _networkInfo;
  final LocationService _locationService;
  final RouteEstimateService _routeService;

  final RxString status = 'Planned'.obs;
  final RxInt totalOutlet = 0.obs;
  final RxList<VisitModel> visits = <VisitModel>[].obs;
  final RxBool isLoading = false.obs;
  final Rxn<LocationSnapshot> currentLocation = Rxn<LocationSnapshot>();
  final RxMap<String, RouteEstimate> routeEstimates = <String, RouteEstimate>{}.obs;
  final requiredOnly = true.obs;
  final RxString searchTerm = ''.obs;
  final RxBool isStartingJourney = false.obs;
  final RxDouble journeyStartProgress = 0.0.obs;
  final RxString journeyStartLabel = ''.obs;

  void selectVisitCategory(bool value) => requiredOnly.value = value;

  void searchOutlets(String value) => searchTerm.value = value;

  @override
  void onInit() {
    super.onInit();
    loadVisits();
  }

  Future<void> loadVisits() async {
    isLoading.value = true;
    try {
      final data = await _repository.getVisits(isOnline: await _networkInfo.isConnected);
      visits.assignAll(data);
      totalOutlet.value = data.length;
    } finally {
      isLoading.value = false;
    }
    // GPS dan estimate rute tidak boleh menahan tampilan daftar kunjungan.
    unawaited(loadRouteEstimates());
  }

  Future<void> loadRouteEstimates() async {
    try {
      routeEstimates.clear();
      final location = await _locationService.currentLocation();
      currentLocation.value = location;
      final routeVisits = visits.where((visit) => visit.latitude != null && visit.longitude != null && visit.status != 'Completed').toList();
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
}
