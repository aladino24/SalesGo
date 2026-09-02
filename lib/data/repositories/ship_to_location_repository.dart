import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/network_info.dart';
import '../models/outlet_model.dart';
import '../models/sales_order_model.dart';

class ShipToLocationRepository {
  ShipToLocationRepository({ApiClient? apiClient, NetworkInfo? networkInfo})
      : _api = apiClient ?? Get.find<ApiClient>(),
        _network = networkInfo ?? Get.find<NetworkInfo>();

  final ApiClient _api;
  final NetworkInfo _network;

  Future<Box> get _box async => Hive.isBoxOpen('ship_to_locations_cache')
      ? Hive.box('ship_to_locations_cache')
      : Hive.openBox('ship_to_locations_cache');

  Future<List<ShipToLocation>> forOutlet(OutletModel outlet) async {
    final box = await _box;
    if (await _network.isConnected) {
      try {
        final response = await _api.get<List<dynamic>>(
          ApiEndpoints.shipToLocations,
        );
        await _replaceCache(response);
      } catch (_) {
        // Gunakan cache valid terakhir saat refresh master gagal.
      }
    }
    final records = box.values
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) => item['outletId']?.toString() == outlet.id)
        .map(ShipToLocation.fromJson)
        .toList();
    final defaultLocation = ShipToLocation(
      code: outlet.code,
      name: outlet.name,
      address: outlet.address,
      contactName: outlet.contactName,
      phone: outlet.phone,
      latitude: outlet.latitude,
      longitude: outlet.longitude,
      isDefault: true,
    );
    // Alamat utama outlet selalu tersedia agar order lama dan offline tetap
    // dapat dibuat sebelum master Ship-to mempunyai data tambahan.
    if (records.every((item) => item.id != null)) records.insert(0, defaultLocation);
    records.sort((a, b) => b.isDefault == a.isDefault ? a.name.compareTo(b.name) : (b.isDefault ? 1 : -1));
    return records;
  }

  Future<Map<String, dynamic>> requestLocation({
    required OutletModel outlet,
    required Map<String, dynamic> payload,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.outletShipToLocations(outlet.id),
      data: payload,
    );
    final shipTo = response['shipTo'];
    if (shipTo is Map && response['approvalRequired'] == false) {
      final box = await _box;
      final item = Map<String, dynamic>.from(shipTo);
      final id = item['id']?.toString();
      if (id != null && id.isNotEmpty) await box.put(id, item);
    }
    return response;
  }

  Future<void> _replaceCache(List<dynamic> response) async {
    final replacement = <String, Map<String, dynamic>>{};
    for (final raw in response) {
      if (raw is! Map) continue;
      final item = Map<String, dynamic>.from(raw);
      final id = item['id']?.toString();
      if (id == null || id.isEmpty) continue;
      replacement[id] = item;
    }
    final box = await _box;
    final previous = Map<dynamic, dynamic>.from(box.toMap());
    try {
      await box.clear();
      await box.putAll(replacement);
    } catch (_) {
      await box.clear();
      await box.putAll(previous);
      rethrow;
    }
  }
}
