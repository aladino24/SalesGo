import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/product_model.dart';
import 'product_controller.dart';

class ProductPage extends GetView<ProductController> {
  const ProductPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Produk'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Cari produk, SKU, kategori',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => controller.searchTerm.value = value,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final items = controller.filteredProducts;
                  if (items.isEmpty) {
                    return const Center(child: Text('Produk tidak ditemukan'));
                  }

                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final product = items[index];
                      return _ProductCard(product: product);
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.inventory_2_rounded),
        ),
        title: Text(product.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${product.category} • ${product.sku}'),
            const SizedBox(height: 4),
            Text('Stok: ${product.stock} | Harga: ${product.price.toStringAsFixed(0)}'),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
