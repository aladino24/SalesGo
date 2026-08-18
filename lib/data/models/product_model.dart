class ProductModel {
  ProductModel({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.price,
    required this.stock,
    required this.imageUrl,
  });

  final String id;
  final String name;
  final String sku;
  final String category;
  final double price;
  final int stock;
  final String imageUrl;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      sku: json['sku'] as String,
      category: json['category'] as String,
      price: (json['price'] as num).toDouble(),
      stock: json['stock'] as int,
      imageUrl: json['imageUrl'] as String? ?? '',
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
      };
}
