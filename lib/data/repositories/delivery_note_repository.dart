import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/sync/sync_manager.dart';
import '../models/delivery_note_model.dart';
class DeliveryNoteRepository { Future<Box> get _box async => Hive.isBoxOpen('delivery_notes') ? Hive.box('delivery_notes') : Hive.openBox('delivery_notes'); Future<List<DeliveryNoteModel>> all() async => (await _box).values.whereType<Map>().map((item)=>DeliveryNoteModel.fromJson(Map<String,dynamic>.from(item))).toList(); Future<void> create(DeliveryNoteModel item) async { await (await _box).put(item.id,item.toJson()); const uuid=Uuid(); await Get.find<SyncManager>().queueItem(type:'delivery_note_create',endpoint:ApiEndpoints.deliveryNotes,method:'POST',payload:item.toJson(),uuid:item.id,idempotencyKey:uuid.v4()); } Future<void> changeStatus(DeliveryNoteModel item,String status) async { final updated=item.copyWith(status:status,approvalStatus:status=='Submitted'?'Waiting Approval':item.approvalStatus); await (await _box).put(item.id,updated.toJson()); const uuid=Uuid(); await Get.find<SyncManager>().queueItem(type:'delivery_note_status',endpoint:'${ApiEndpoints.deliveryNotes}/${item.id}/status',method:'PATCH',payload:{'status':status},uuid:uuid.v4(),idempotencyKey:uuid.v4()); } }
