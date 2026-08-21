import 'package:flutter_test/flutter_test.dart';
import 'package:salesgo/core/location/location_service.dart';
import 'package:salesgo/core/storage/sync_storage.dart';
import 'package:salesgo/data/datasources/local/visit_local_data_source.dart';
import 'package:salesgo/data/models/sync_item_model.dart';
import 'package:salesgo/data/models/visit_model.dart';
import 'package:salesgo/modules/approval/approval_model.dart';

import 'support/hive_test_helper.dart';

void main() {
  setUpAll(() async {
    await HiveTestHelper.initialize();
    await SyncStorage.init();
  });

  setUp(() => HiveTestHelper.clearBoxes(['visits', 'sync_queue_box', 'sync_audit_log']));

  test('offline GPS check-in and approval remain queued until a successful sync', () async {
    const outletLatitude = -7.2575;
    const outletLongitude = 112.7521;
    final gps = LocationSnapshot(
      latitude: -7.25755,
      longitude: 112.75215,
      accuracy: 8,
      capturedAt: DateTime(2026, 8, 21, 9),
    );
    final distance = LocationService().distanceInMeters(
      fromLatitude: gps.latitude,
      fromLongitude: gps.longitude,
      toLatitude: outletLatitude,
      toLongitude: outletLongitude,
    );
    expect(distance, lessThanOrEqualTo(100));

    final visit = VisitModel(
      id: 'VIS-TEST-1',
      outletId: 'OUT-TEST-1',
      outletName: 'Outlet Test',
      status: 'In Progress',
      distanceKm: distance / 1000,
      salesName: 'Sales Test',
      createdAt: DateTime(2026, 8, 21, 9),
    );
    await VisitLocalDataSource().addVisit(visit);

    final approval = ApprovalModel(
      id: 'APR-TEST-1',
      type: 'visit_out_of_radius',
      entityId: visit.id,
      requestedBy: 'Sales Test',
      reason: 'Titik GPS outlet bergeser',
      status: 'Pending',
      createdAt: DateTime(2026, 8, 21, 9),
    );
    final checkInItem = _item('SYNC-CHECK-IN', 'visit_check_in', {'visitId': visit.id, 'location': gps.toJson()});
    final approvalItem = _item('SYNC-APPROVAL', 'approval_request', approval.toJson());
    await SyncStorage.addItem(checkInItem);
    await SyncStorage.addItem(approvalItem);

    expect((await VisitLocalDataSource().findActiveVisitForOutlet(outletId: 'OUT-TEST-1', outletName: 'Outlet Test'))?.id, visit.id);
    expect(SyncStorage.getSyncStats()['pending'], 2);

    // Simulates server acknowledgement after network reconnect.
    await SyncStorage.addAudit(item: checkInItem, event: 'sync_succeeded');
    await SyncStorage.addAudit(item: approvalItem, event: 'sync_succeeded');
    await SyncStorage.removeItem(checkInItem.id);
    await SyncStorage.removeItem(approvalItem.id);

    expect(SyncStorage.pendingItems(), isEmpty);
    expect(SyncStorage.getSyncStats()['pending'], 0);
  });
}

SyncItem _item(String id, String type, Map<String, dynamic> payload) => SyncItem(
      id: id,
      uuid: id,
      type: type,
      endpoint: '/test',
      method: 'POST',
      payload: payload,
      status: 'pending',
      idempotencyKey: 'key-$id',
      createdAt: DateTime(2026, 8, 21, 9),
    );
