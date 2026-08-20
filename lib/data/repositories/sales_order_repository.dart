import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/sync/sync_manager.dart';
import '../datasources/local/sales_order_local_data_source.dart';
import '../models/sales_order_model.dart';

class SalesOrderRepository {
  SalesOrderRepository({SalesOrderLocalDataSource? localDataSource}) : _localDataSource = localDataSource ?? SalesOrderLocalDataSource();
  final SalesOrderLocalDataSource _localDataSource;
  /// Parameter produk lama dipertahankan agar pemanggil satu-produk yang belum
  /// direfresh tetap dapat membangun aplikasi. Cart baru mengirim [order.items].
  Future<void> create(SalesOrderModel order, {String? productName, int? quantity, double? unitPrice}) async {
    await _localDataSource.save(order);
    const uuid = Uuid();
    final payload = order.toJson();
    if (order.items.isEmpty && productName != null) {
      payload['items'] = [SalesOrderItem(productId: '', productName: productName, quantity: quantity ?? 0, unitPrice: unitPrice ?? 0).toJson()];
    }
    await Get.find<SyncManager>().queueItem(type: 'sales_order_create', endpoint: ApiEndpoints.salesOrders, method: 'POST', uuid: order.id, idempotencyKey: uuid.v4(), payload: payload);
  }
}
