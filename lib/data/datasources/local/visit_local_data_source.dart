import 'package:hive_flutter/hive_flutter.dart';

import '../../models/visit_model.dart';

class VisitLocalDataSource {
  static const _boxName = 'visits';

  Future<Box> get _box async => Hive.isBoxOpen(_boxName) ? Hive.box(_boxName) : Hive.openBox(_boxName);

  Future<List<VisitModel>> getVisits() async {
    final box = await _box;
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
    final unique = <String, VisitModel>{};
    for (final visit in visits) {
      final key = '${visit.outletId ?? visit.outletName}|${visit.plannedFor ?? ''}';
      final existing = unique[key];
      if (existing == null || visit.createdAt.isAfter(existing.createdAt)) {
        unique[key] = visit;
      }
    }
    await box.clear();
    await box.putAll({for (final visit in unique.values) visit.id: visit.toJson()});
  }
}
