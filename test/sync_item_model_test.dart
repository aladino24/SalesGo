import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:salesgo/data/models/sync_item_model.dart';

void main() {
  group('SyncItem Model', () {
    test('creates sync item with required fields', () {
      const uuid = Uuid();
      final syncItem = SyncItem(
        id: '1',
        uuid: uuid.v4(),
        type: 'visit_create',
        endpoint: '/visits',
        method: 'POST',
        payload: {'outletId': 'OUT-001', 'status': 'on_route'},
        status: 'pending',
        idempotencyKey: uuid.v4(),
        createdAt: DateTime.now(),
      );

      expect(syncItem.id, '1');
      expect(syncItem.type, 'visit_create');
      expect(syncItem.status, 'pending');
      expect(syncItem.method, 'POST');
    });

    test('converts to JSON and back', () {
      const uuid = Uuid();
      final key = uuid.v4();
      final now = DateTime.now();
      final original = SyncItem(
        id: '1',
        uuid: key,
        type: 'sales_order_create',
        endpoint: '/sales-orders',
        method: 'POST',
        payload: {'outletId': 'OUT-001', 'total': 50000},
        status: 'pending',
        idempotencyKey: key,
        createdAt: now,
      );

      final json = original.toJson();
      final restored = SyncItem.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.uuid, original.uuid);
      expect(restored.type, original.type);
      expect(restored.status, original.status);
      expect(restored.payload, original.payload);
    });

    test('copyWith creates updated copy', () {
      const uuid = Uuid();
      final original = SyncItem(
        id: '1',
        uuid: uuid.v4(),
        type: 'visit_create',
        endpoint: '/visits',
        method: 'POST',
        payload: {},
        status: 'pending',
        idempotencyKey: uuid.v4(),
        createdAt: DateTime.now(),
      );

      final updated = original.copyWith(
        status: 'syncing',
        attemptCount: 1,
        error: 'timeout',
      );

      expect(updated.status, 'syncing');
      expect(updated.attemptCount, 1);
      expect(updated.error, 'timeout');
      expect(updated.id, original.id); // Unchanged
    });
  });
}
