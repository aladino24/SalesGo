import 'package:get/get.dart';

import '../../data/models/visit_model.dart';
import '../../data/repositories/visit_repository.dart';

class VisitController extends GetxController {
  VisitController({VisitRepository? repository}) : _repository = repository ?? VisitRepository();

  final VisitRepository _repository;

  final RxString status = 'Planned'.obs;
  final RxInt totalOutlet = 25.obs;
  final RxList<VisitModel> visits = <VisitModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadVisits();
  }

  Future<void> loadVisits() async {
    isLoading.value = true;
    try {
      final data = await _repository.getVisits(isOnline: false);
      visits.assignAll(data);
    } finally {
      isLoading.value = false;
    }
  }

  void updateStatus(String value) => status.value = value;

  Future<void> addMockVisit() async {
    final newVisit = VisitModel(
      id: 'VIS-${DateTime.now().millisecondsSinceEpoch}',
      outletName: 'Outlet Baru',
      status: 'On Route',
      distanceKm: 0.8,
      salesName: 'Raka',
      createdAt: DateTime.now(),
    );

    await _repository.createVisit(newVisit, isOnline: false);
    visits.insert(0, newVisit);
  }
}
