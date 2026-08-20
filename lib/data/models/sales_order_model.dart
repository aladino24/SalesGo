class SalesOrderItem {
  const SalesOrderItem({required this.productId, required this.productName, required this.quantity, required this.unitPrice, this.discount = 0});
  final String productId, productName;
  final int quantity;
  final double unitPrice, discount;
  double get subtotal => (unitPrice * quantity) - discount;
  factory SalesOrderItem.fromJson(Map<String, dynamic> json) => SalesOrderItem(productId: json['productId']?.toString() ?? '', productName: json['productName']?.toString() ?? '-', quantity: (json['quantity'] as num?)?.toInt() ?? 0, unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0, discount: (json['discount'] as num?)?.toDouble() ?? 0);
  Map<String, dynamic> toJson() => {'productId': productId, 'productName': productName, 'quantity': quantity, 'unitPrice': unitPrice, 'discount': discount, 'subtotal': subtotal};
}

class SalesOrderModel {
  SalesOrderModel({required this.id, required this.outletName, this.items = const [], required this.total, required this.status, required this.createdAt, this.discount = 0});
  final String id, outletName, status;
  final List<SalesOrderItem> items;
  final double total, discount;
  final DateTime createdAt;
  factory SalesOrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List?;
    final legacyItem = rawItems == null && json['productName'] != null ? [SalesOrderItem(productId: json['productId']?.toString() ?? '', productName: json['productName'].toString(), quantity: (json['quantity'] as num?)?.toInt() ?? 0, unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0)] : <SalesOrderItem>[];
    return SalesOrderModel(id: json['id'].toString(), outletName: json['outletName']?.toString() ?? '-', items: rawItems?.whereType<Map>().map((item) => SalesOrderItem.fromJson(Map<String, dynamic>.from(item))).toList() ?? legacyItem, total: (json['total'] as num?)?.toDouble() ?? 0, discount: (json['discount'] as num?)?.toDouble() ?? 0, status: json['status']?.toString() ?? 'Pending Sync', createdAt: DateTime.parse(json['createdAt'].toString()));
  }
  Map<String, dynamic> toJson() => {'id': id, 'outletName': outletName, 'items': items.map((item) => item.toJson()).toList(), 'total': total, 'discount': discount, 'status': status, 'createdAt': createdAt.toIso8601String()};
}
