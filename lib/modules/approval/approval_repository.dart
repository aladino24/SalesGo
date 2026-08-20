import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/network_info.dart';
import '../../core/sync/sync_manager.dart';
import 'approval_model.dart';

class ApprovalRepository {
  ApprovalRepository({ApiClient? apiClient, NetworkInfo? networkInfo}) : _api = apiClient ?? Get.find<ApiClient>(), _network = networkInfo ?? Get.find<NetworkInfo>();
  final ApiClient _api; final NetworkInfo _network; static const _boxName = 'approvals_cache';
  Future<Box> get _box async => Hive.isBoxOpen(_boxName) ? Hive.box(_boxName) : Hive.openBox(_boxName);
  Future<List<ApprovalModel>> getPendingApprovals() async { final box = await _box; if (await _network.isConnected) { try { final response = await _api.get<List<dynamic>>(ApiEndpoints.approvals, queryParameters: {'status': 'Pending'}); await box.clear(); await box.putAll({for (final value in response) (value as Map)['id']: value}); } catch (_) {} } return box.values.map((value) => ApprovalModel.fromJson(Map<String,dynamic>.from(value as Map))).where((item) => item.status == 'Pending' || item.status == 'Waiting Approval').toList(); }
  Future<void> decide({required ApprovalModel item, required bool approved, String? comment}) async { const uuid = Uuid(); final payload = {'status': approved ? 'Approved' : 'Rejected', 'comment': comment ?? ''}; final box = await _box; await box.put(item.id, {...item.toJson(), ...payload}); await Get.find<SyncManager>().queueItem(type: 'approval_decision', endpoint: '${ApiEndpoints.approvals}/${item.id}/decision', method: 'POST', payload: payload, uuid: uuid.v4(), idempotencyKey: uuid.v4()); }
}
