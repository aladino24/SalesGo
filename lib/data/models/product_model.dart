class ProductModel {
  ProductModel({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.price,
    required this.stock,
    required this.imageUrl,
    this.divisionCode = '',
    this.divisionName = '',
    this.brand = '',
    this.variant = '',
    this.size = '',
    this.uom = '',
    this.unitsPerCase = 1,
    this.barcode = '',
  });

  final String id;
  final String name;
  final String sku;
  final String category;
  final double price;
  final int stock;
  final String imageUrl;
  final String divisionCode, divisionName, brand, variant, size, uom, barcode;
  final int unitsPerCase;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '-',
      sku: json['sku']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      price: _number(json['price']),
      stock: _integer(json['stock']),
      imageUrl: json['imageUrl']?.toString() ?? '',
      divisionCode: json['divisionCode']?.toString() ?? '',
      divisionName: json['divisionName']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      variant: json['variant']?.toString() ?? '',
      size: json['size']?.toString() ?? '',
      uom: json['uom']?.toString() ?? '',
      unitsPerCase: _integer(json['unitsPerCase'], fallback: 1),
      barcode: json['barcode']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sku': sku,
        'category': category,
        'price': price,
        'stock': stock,
        'imageUrl': imageUrl,
        'divisionCode': divisionCode,
        'divisionName': divisionName,
        'brand': brand,
        'variant': variant,
        'size': size,
        'uom': uom,
        'unitsPerCase': unitsPerCase,
        'barcode': barcode,
      };

  static double _number(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;
  static int _integer(dynamic value, {int fallback = 0}) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? fallback;
}
