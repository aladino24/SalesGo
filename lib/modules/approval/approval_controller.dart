import 'package:get/get.dart';

import '../../core/auth/app_roles.dart';
import '../../core/auth/session_service.dart';
import 'approval_model.dart';
import 'approval_repository.dart';

class ApprovalController extends GetxController {
  ApprovalController({
    ApprovalRepository? repository,
    SessionService? sessionService,
  })  : _repository = repository ?? ApprovalRepository(),
        _sessionService = sessionService ?? Get.find<SessionService>();

  final ApprovalRepository _repository;
  final SessionService _sessionService;

  final RxList<ApprovalModel> approvals = <ApprovalModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadPendingApprovals();
  }

  Future<void> loadPendingApprovals() async {
    isLoading.value = true;
    try {
      final currentRole = _sessionService.currentRole.value;
      final isAllowed = currentRole == AppRole.supervisor || currentRole == AppRole.branchManager;

      if (!isAllowed) {
        approvals.clear();
        return;
      }

      approvals.assignAll(await _repository.getPendingApprovals());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> decide(
    String approvalId, {
    required bool approved,
    String? comment,
  }) async {
    final index = approvals.indexWhere((item) => item.id == approvalId);
    if (index >= 0) {
      final updated = ApprovalModel(
        id: approvals[index].id,
        type: approvals[index].type,
        entityId: approvals[index].entityId,
        requestedBy: approvals[index].requestedBy,
        reason: approvals[index].reason,
        status: approved ? 'Approved' : 'Rejected',
        createdAt: approvals[index].createdAt,
        requestedByRole: approvals[index].requestedByRole,
        outlet: approvals[index].outlet,
        visit: approvals[index].visit,
      );
      approvals[index] = updated;
      await _repository.decide(
        item: updated,
        approved: approved,
        comment: comment,
      );
    }
  }
}
