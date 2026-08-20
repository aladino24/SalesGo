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
        final visits = await _remoteDataSource.getVisits();
        await _localDataSource.replaceVisits(visits);
        return visits;
      } catch (_) {
        return _localDataSource.getVisits();
      }
    }
    return _localDataSource.getVisits();
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
