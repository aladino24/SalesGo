import 'package:hive_flutter/hive_flutter.dart';

import '../../models/visit_model.dart';

class VisitLocalDataSource {
  static const _boxName = 'visits';

  Future<Box> get _box async => Hive.isBoxOpen(_boxName) ? Hive.box(_boxName) : Hive.openBox(_boxName);

  Future<List<VisitModel>> getVisits() async {
    final box = await _box;
    final appBox = Hive.box('app_box');
    final hasServerSnapshot = appBox.get('has_server_state_snapshot', defaultValue: false) as bool;
    if (box.isEmpty && !hasServerSnapshot) await _seed(box);
    final visits = box.values.map((value) => VisitModel.fromJson(Map<String, dynamic>.from(value as Map))).toList();
    visits.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return visits;
  }

  Future<void> addVisit(VisitModel visit) async => (await _box).put(visit.id, visit.toJson());

  Future<void> updateStatus(String visitId, String status) async {
    final box = await _box;
    final raw = box.get(visitId);
    if (raw is! Map) return;
    final visit = VisitModel.fromJson(Map<String, dynamic>.from(raw));
    await box.put(visitId, visit.copyWith(status: status).toJson());
  }

  Future<VisitModel?> findActiveVisitForOutlet({
    required String outletId,
    required String outletName,
  }) async {
    final visits = await getVisits();
    for (final visit in visits) {
      final isMatchingOutlet = visit.outletId == outletId ||
          (visit.outletId == null && visit.outletName == outletName);
      if (isMatchingOutlet && visit.status == 'In Progress') return visit;
    }
    return null;
  }

  Future<void> replaceVisits(List<VisitModel> visits) async {
    final box = await _box;
    await box.clear();
    await box.putAll({for (final visit in visits) visit.id: visit.toJson()});
  }

  Future<void> _seed(Box box) async {
    final now = DateTime.now();
    await box.putAll({
      'VIS-1001': VisitModel(id: 'VIS-1001', outletName: 'Toko Sumber Rejeki', status: 'Completed', distanceKm: 1.2, salesName: 'Raka', createdAt: now.subtract(const Duration(days: 1))).toJson(),
      'VIS-1002': VisitModel(id: 'VIS-1002', outletName: 'Toko Maju Jaya', status: 'In Progress', distanceKm: 2.8, salesName: 'Raka', createdAt: now).toJson(),
    });
  }
}
