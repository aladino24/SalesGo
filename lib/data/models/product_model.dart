class ProductUomModel {
  const ProductUomModel({
    required this.id,
    required this.code,
    required this.name,
    required this.conversionToBase,
    required this.price,
    this.minimumQuantity = 1,
    this.maximumQuantity,
    this.isDefault = false,
  });

  final String id, code, name;
  final int conversionToBase, minimumQuantity;
  final int? maximumQuantity;
  final double price;
  final bool isDefault;

  factory ProductUomModel.fromJson(Map<String, dynamic> json) => ProductUomModel(
        id: json['id']?.toString() ?? '',
        code: json['code']?.toString() ?? 'PCS',
        name: json['name']?.toString() ?? json['code']?.toString() ?? 'PCS',
        conversionToBase: _integer(json['conversionToBase'] ?? json['conversion_to_base'], fallback: 1).clamp(1, 1000000),
        price: _number(json['price']),
        minimumQuantity: _integer(json['minimumQuantity'] ?? json['minimum_quantity'], fallback: 1).clamp(1, 1000000),
        maximumQuantity: (json['maximumQuantity'] ?? json['maximum_quantity']) == null ? null : _integer(json['maximumQuantity'] ?? json['maximum_quantity']),
        isDefault: json['isDefault'] == true || json['isDefault']?.toString() == '1' || json['is_default'] == true || json['is_default']?.toString() == '1',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'conversionToBase': conversionToBase,
        'price': price,
        'minimumQuantity': minimumQuantity,
        if (maximumQuantity != null) 'maximumQuantity': maximumQuantity,
        'isDefault': isDefault,
      };
}

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
    this.uoms = const [],
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
  final List<ProductUomModel> uoms;

  List<ProductUomModel> get sellableUoms {
    if (uoms.isNotEmpty) return uoms;
    return [
      ProductUomModel(
        id: '',
        code: uom.isEmpty ? 'PCS' : uom.split('/').first.trim(),
        name: uom.isEmpty ? 'PCS' : uom.split('/').first.trim(),
        conversionToBase: 1,
        price: price,
        isDefault: true,
      ),
    ];
  }

  ProductUomModel get defaultUom => sellableUoms.firstWhere(
        (item) => item.isDefault,
        orElse: () => sellableUoms.first,
      );

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
      uoms: (json['uoms'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => ProductUomModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
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
        'uoms': uoms.map((item) => item.toJson()).toList(),
      };

  static double _number(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;
  static int _integer(dynamic value, {int fallback = 0}) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _number(dynamic value) => value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;
int _integer(dynamic value, {int fallback = 0}) => value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? fallback;
