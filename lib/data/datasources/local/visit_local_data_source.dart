import '../../models/visit_model.dart';

class VisitLocalDataSource {
  final List<VisitModel> _visits = [
    VisitModel(
      id: 'VIS-1001',
      outletName: 'Outlet A',
      status: 'Completed',
      distanceKm: 1.2,
      salesName: 'Raka',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    VisitModel(
      id: 'VIS-1002',
      outletName: 'Outlet B',
      status: 'In Progress',
      distanceKm: 2.8,
      salesName: 'Raka',
      createdAt: DateTime.now(),
    ),
  ];

  Future<List<VisitModel>> getVisits() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _visits;
  }

  Future<void> addVisit(VisitModel visit) async {
    _visits.insert(0, visit);
  }
}
