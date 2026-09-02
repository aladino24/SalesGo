class SalesOrderItem {
  const SalesOrderItem({required this.productId, required this.productName, required this.quantity, required this.unitPrice, this.productUomId, this.uomCode = '', this.uomName = '', this.conversionToBase = 1, this.baseQuantity, this.discount = 0});
  final String productId, productName;
  final String? productUomId;
  final String uomCode, uomName;
  final int quantity, conversionToBase;
  final int? baseQuantity;
  final double unitPrice, discount;
  double get subtotal => (unitPrice * quantity) - discount;
  int get effectiveBaseQuantity => baseQuantity ?? quantity * conversionToBase;
  factory SalesOrderItem.fromJson(Map<String, dynamic> json) => SalesOrderItem(productId: json['productId']?.toString() ?? '', productName: json['productName']?.toString() ?? '-', productUomId: json['productUomId']?.toString(), uomCode: json['uomCode']?.toString() ?? '', uomName: json['uomName']?.toString() ?? '', conversionToBase: _integer(json['conversionToBase']) <= 0 ? 1 : _integer(json['conversionToBase']), baseQuantity: json['baseQuantity'] == null ? null : _integer(json['baseQuantity']), quantity: _integer(json['quantity']), unitPrice: _number(json['unitPrice']), discount: _number(json['discount']));
  Map<String, dynamic> toJson() => {'productId': productId, 'productName': productName, if (productUomId?.isNotEmpty == true) 'productUomId': productUomId, if (uomCode.isNotEmpty) 'uomCode': uomCode, if (uomName.isNotEmpty) 'uomName': uomName, 'conversionToBase': conversionToBase, 'baseQuantity': effectiveBaseQuantity, 'quantity': quantity, 'unitPrice': unitPrice, 'discount': discount, 'subtotal': subtotal};

  static int _integer(dynamic value) => value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
  static double _number(dynamic value) => value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;
}

class SalesOrderModel {
  SalesOrderModel({required this.id, required this.outletName, this.outletId, this.items = const [], required this.total, required this.status, required this.createdAt, this.discount = 0});
  final String id, outletName, status;
  final String? outletId;
  final List<SalesOrderItem> items;
  final double total, discount;
  final DateTime createdAt;
  factory SalesOrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List?;
    final legacyItem = rawItems == null && json['productName'] != null ? [SalesOrderItem(productId: json['productId']?.toString() ?? '', productName: json['productName'].toString(), quantity: SalesOrderItem._integer(json['quantity']), unitPrice: SalesOrderItem._number(json['unitPrice']))] : <SalesOrderItem>[];
    return SalesOrderModel(id: json['id'].toString(), outletName: json['outletName']?.toString() ?? '-', outletId: json['outletId']?.toString(), items: rawItems?.whereType<Map>().map((item) => SalesOrderItem.fromJson(Map<String, dynamic>.from(item))).toList() ?? legacyItem, total: SalesOrderItem._number(json['total']), discount: SalesOrderItem._number(json['discount']), status: json['status']?.toString() ?? 'Pending Sync', createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now());
  }
  Map<String, dynamic> toJson() => {'id': id, 'outletName': outletName, if (outletId != null) 'outletId': outletId, 'items': items.map((item) => item.toJson()).toList(), 'total': total, 'discount': discount, 'status': status, 'createdAt': createdAt.toIso8601String()};
}
