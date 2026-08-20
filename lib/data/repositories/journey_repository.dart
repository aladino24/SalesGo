import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/sync/sync_manager.dart';
import '../models/journey_model.dart';
class JourneyRepository { Future<Box> get _box async => Hive.isBoxOpen('journeys') ? Hive.box('journeys') : Hive.openBox('journeys'); Future<List<JourneyModel>> all() async { final items = (await _box).values.whereType<Map>().map((item) => JourneyModel.fromJson(Map<String,dynamic>.from(item))).toList(); items.sort((a,b) => b.createdAt.compareTo(a.createdAt)); return items; } Future<void> create(JourneyModel item) async { await (await _box).put(item.id,item.toJson()); const uuid=Uuid(); await Get.find<SyncManager>().queueItem(type:'journey_create',endpoint:ApiEndpoints.journeys,method:'POST',payload:item.toJson(),uuid:item.id,idempotencyKey:uuid.v4()); } Future<void> updateStatus(JourneyModel item,String status) async { final updated=item.copyWith(status:status); await (await _box).put(item.id,updated.toJson()); const uuid=Uuid(); await Get.find<SyncManager>().queueItem(type:'journey_status',endpoint:'${ApiEndpoints.journeys}/${item.id}/status',method:'PATCH',payload:{'status':status},uuid:uuid.v4(),idempotencyKey:uuid.v4()); } }
