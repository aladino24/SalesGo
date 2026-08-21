import 'package:flutter_test/flutter_test.dart';
import 'package:salesgo/data/models/app_notification_model.dart';

void main() {
  test('parses the notification contract and preserves read state', () {
    final item = AppNotificationModel.fromJson({
      'id': 'not-1',
      'type': 'approval_decision',
      'title': 'Approval diterima',
      'message': 'Pengajuan disetujui.',
      'isRead': false,
      'createdAt': '2026-08-22T09:30:00Z',
      'deepLink': '/approval?approvalId=10',
    });

    expect(item.id, 'not-1');
    expect(item.isRead, isFalse);
    expect(item.deepLink, '/approval?approvalId=10');
    expect(item.copyWith(isRead: true).toJson()['isRead'], isTrue);
  });
}
