import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsController extends GetxController {
  void showAccount() {
    Get.snackbar('Account', 'Informasi user dan role akan ditampilkan di sini.');
  }

  void syncData() {
    Get.snackbar('Sync', 'Sinkronisasi data dimulai.');
  }

  void changeTheme() {
    Get.snackbar('Theme', 'Tema aplikasi dapat diubah dari pengaturan ini.');
  }

  void deleteAllData() {
    Get.defaultDialog(
      title: 'Hapus Semua Data',
      middleText: 'Semua data lokal akan dihapus dari perangkat.',
      confirm: TextButton(onPressed: () => Get.back(), child: const Text('Hapus')),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
    );
  }

  void logout() {
    Get.offAllNamed('/login');
  }
}
