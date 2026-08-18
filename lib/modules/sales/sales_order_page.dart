import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SalesOrderPage extends StatelessWidget {
  const SalesOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Penjualan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Outlet',
                prefixIcon: Icon(Icons.storefront_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Produk',
                prefixIcon: Icon(Icons.inventory_2_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                prefixIcon: Icon(Icons.numbers_rounded),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Get.snackbar('Penjualan', 'Order disimpan secara lokal dan menunggu sync.'),
                icon: const Icon(Icons.save_rounded),
                label: const Text('Submit Order'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
