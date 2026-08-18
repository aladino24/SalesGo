import 'approval_model.dart';

class ApprovalRepository {
  Future<List<ApprovalModel>> getPendingApprovals() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    return [
      ApprovalModel(
        id: 'APP-001',
        type: 'Visit',
        entityId: 'VIS-1002',
        requestedBy: 'Raka',
        reason: 'Outlet tutup karena hujan',
        status: 'Waiting Approval',
        createdAt: DateTime.now(),
      ),
      ApprovalModel(
        id: 'APP-002',
        type: 'Delivery Note',
        entityId: 'DN-210',
        requestedBy: 'Raka',
        reason: 'Pengiriman ke outlet area barat',
        status: 'Waiting Approval',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];
  }
}
