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
      await loadRouteEstimates();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadRouteEstimates() async {
    try {
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

  void updateStatus(String value) => status.value = value;
}
