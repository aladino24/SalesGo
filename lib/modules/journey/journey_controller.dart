import 'package:get/get.dart';

import '../../data/models/journey_model.dart';
import '../../data/repositories/journey_repository.dart';
import '../visit/visit_controller.dart';

class JourneyController extends GetxController {
  JourneyController({JourneyRepository? repository})
      : _repository = repository ?? JourneyRepository();

  final JourneyRepository _repository;
  final journeys = <JourneyModel>[].obs;
  final isLoading = false.obs;

  JourneyModel? get activeJourney {
    final today = _dateOnly(DateTime.now());
    for (final item in journeys) {
      final inPeriod = !today.isBefore(_dateOnly(item.startAt)) &&
          !today.isAfter(_dateOnly(item.endAt));
      if (item.status == 'Active' && inPeriod) return item;
    }
    return null;
  }

  int get plannedCount =>
      journeys.where((item) => item.status == 'Planned').length;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      // Menutup status Active yang sudah di luar periode pada cache/server.
      // Daftar lalu dimuat ulang agar rute wajib yang kedaluwarsa hilang.
      await _repository.activeJourneyForToday();
      journeys.assignAll(await _repository.all());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> create(JourneyModel item) async {
    await _repository.create(item);
    await load();
  }

  Future<void> start(JourneyModel item) async {
    await _repository.start(item);
    await load();
    await _refreshVisits();
  }

  Future<void> changeStatus(
    JourneyModel item,
    String status, {
    String? reason,
  }) async {
    if (status == 'Active' &&
        activeJourney != null &&
        activeJourney!.id != item.id) {
      throw StateError('Selesaikan perjalanan aktif terlebih dahulu.');
    }
    await _repository.updateStatus(item, status, reason: reason);
    await load();
    await _refreshVisits();
  }

  Future<void> _refreshVisits() async {
    if (!Get.isRegistered<VisitController>()) return;
    await Get.find<VisitController>().loadVisits();
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
