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
      return _remoteDataSource.getVisits();
    }

    return _localDataSource.getVisits();
  }

  Future<void> createVisit(VisitModel visit, {required bool isOnline}) async {
    if (isOnline) {
      // Real API call would go here.
      return;
    }

    await _localDataSource.addVisit(visit);
  }
}
