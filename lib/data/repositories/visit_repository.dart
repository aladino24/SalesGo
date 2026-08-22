import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../core/network/api_endpoints.dart';
import '../../core/sync/sync_manager.dart';
import '../datasources/local/visit_local_data_source.dart';
import '../datasources/remote/visit_remote_data_source.dart';
import '../models/visit_model.dart';

class VisitRepository {
  VisitRepository({
    VisitLocalDataSource? localDataSource,
    VisitRemoteDataSource? remoteDataSource,
  })  : _localDataSource = localDataSource ?? VisitLocalDataSource(),
        _remoteDataSource = remoteDataSource ?? VisitRemoteDataSource();

  final VisitLocalDataSource _localDataSource;
  final VisitRemoteDataSource _remoteDataSource;

  Future<List<VisitModel>> getVisits({required bool isOnline}) async {
    if (isOnline) {
      try {
        final local = await _localDataSource.getVisits();
        final visits = _mergePendingLocalVisits(
          _deduplicate(await _remoteDataSource.getVisits()),
          local,
        );
        await _localDataSource.replaceVisits(visits);
        return visits;
      } catch (_) {
        return _localDataSource.getVisits();
      }
    }
    return _localDataSource.getVisits();
  }

  List<VisitModel> _mergePendingLocalVisits(
    List<VisitModel> remote,
    List<VisitModel> local,
  ) {
    final merged = <String, VisitModel>{for (final item in remote) item.id: item};
    for (final item in local) {
      // Check-in/out/tunda/batal lokal dapat masih mengantre ke server. Jangan
      // mengembalikan status lokal tersebut menjadi Planned dari snapshot lama.
      final serverItem = merged[item.id];
      if (item.status != 'Planned' &&
          (serverItem == null || serverItem.status == 'Planned')) {
        merged[item.id] = item;
      }
    }
    return _deduplicate(merged.values.toList());
  }

  List<VisitModel> _deduplicate(List<VisitModel> visits) {
    final unique = <String, VisitModel>{};
    for (final visit in visits) {
      final planned = DateTime.tryParse(visit.plannedFor ?? '')?.toLocal();
      final dateKey = planned == null
          ? (visit.plannedFor ?? '')
          : '${planned.year}-${planned.month}-${planned.day}';
      final key = '${visit.outletId ?? visit.outletName}|$dateKey|${visit.isRequired}';
      final existing = unique[key];
      if (existing == null || visit.createdAt.isAfter(existing.createdAt)) {
        unique[key] = visit;
      }
    }
    return unique.values.toList();
  }

  Future<void> createVisit(VisitModel visit, {required bool isOnline}) async {
    await _localDataSource.addVisit(visit);
    if (!isOnline) {
      const uuid = Uuid();
      await Get.find<SyncManager>().queueItem(
        type: 'visit_create',
        endpoint: ApiEndpoints.visits,
        method: 'POST',
        payload: visit.toJson(),
        uuid: uuid.v4(),
        idempotencyKey: uuid.v4(),
      );
      return;
    }

    final remoteVisit = await _remoteDataSource.createVisit(visit);
    await _localDataSource.addVisit(remoteVisit);
  }
}
