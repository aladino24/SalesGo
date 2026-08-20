import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/auth/session_service.dart';
import '../../core/storage/sync_storage.dart';
import '../../core/storage/local_storage.dart';
import '../../core/sync/sync_manager.dart';
import '../../core/sync/server_state_restore_service.dart';
import '../../core/sync/master_data_download_service.dart';
import '../home/home_controller.dart';
import '../visit/visit_controller.dart';
import '../product/product_controller.dart';
import '../outlet/outlet_controller.dart';

class SettingsController extends GetxController {
  final RxBool isDarkMode = false.obs;
  final RxBool isRestoringServerState = false.obs;
  final RxString lastServerStateRestoreAt = ''.obs;
  final RxBool isDownloadingMasterData = false.obs;
  final RxDouble masterDownloadProgress = 0.0.obs;
  final RxString masterDownloadLabel = ''.obs;
  final RxString lastMasterDownloadAt = ''.obs;
  final RxString lastMasterDownloadSummary = ''.obs;

  @override
  void onInit() {
    super.onInit();
    isDarkMode.value = LocalStorage.appBox.get('dark_mode', defaultValue: false) as bool;
    lastServerStateRestoreAt.value =
        LocalStorage.appBox.get('last_server_state_restore_at', defaultValue: '') as String;
    lastMasterDownloadAt.value =
        LocalStorage.appBox.get('last_master_download_at', defaultValue: '') as String;
    _loadMasterDownloadSummary();
  }
  void showAccount() {
    Get.snackbar('Account', 'Informasi user dan role akan ditampilkan di sini.');
  }

  Future<void> syncData() async {
    final sync = Get.find<SyncManager>();
    await sync.syncNow(force: true);
    final stats = sync.syncStats;
    final unresolved = (stats['conflict'] ?? 0) + (stats['blocked'] ?? 0);
    Get.snackbar(
      unresolved > 0 ? 'Sync perlu perhatian' : 'Sync',
      unresolved > 0
          ? '$unresolved item conflict/gagal perlu ditinjau.'
          : 'Sinkronisasi data selesai diproses.',
    );
  }

  Future<void> downloadLatestMasterData() async {
    if (isDownloadingMasterData.value) return;
    isDownloadingMasterData.value = true;
    masterDownloadProgress.value = 0;
    masterDownloadLabel.value = 'Menyiapkan unduhan...';
    try {
      final result = await Get.find<MasterDataDownloadService>().download(
        onProgress: (progress) {
          masterDownloadProgress.value = progress.value;
          masterDownloadLabel.value = progress.label;
        },
      );
      lastMasterDownloadAt.value = DateTime.now().toIso8601String();
      lastMasterDownloadSummary.value = '${result.products} produk • ${result.outlets} outlet';
      if (Get.isRegistered<ProductController>()) {
        await Get.find<ProductController>().refreshFromCache();
      }
      if (Get.isRegistered<OutletController>()) {
        await Get.find<OutletController>().refreshFromCache();
      }
      Get.snackbar(
        'Data terbaru siap',
        '${result.products} produk dan ${result.outlets} outlet diperbarui.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on StateError catch (error) {
      Get.snackbar('Tidak dapat mengunduh', error.message, snackPosition: SnackPosition.BOTTOM);
    } on FormatException catch (error) {
      Get.snackbar('Data server tidak valid', error.message, snackPosition: SnackPosition.BOTTOM);
    } catch (_) {
      Get.snackbar('Unduhan gagal', 'Data lokal sebelumnya tetap digunakan. Coba lagi saat koneksi stabil.', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isDownloadingMasterData.value = false;
    }
  }

  void _loadMasterDownloadSummary() {
    final products = LocalStorage.appBox.get('last_master_products_count');
    final outlets = LocalStorage.appBox.get('last_master_outlets_count');
    if (products is int && outlets is int) {
      lastMasterDownloadSummary.value = '$products produk • $outlets outlet';
    }
  }

  Future<void> changeTheme() async {
    isDarkMode.toggle();
    await LocalStorage.appBox.put('dark_mode', isDarkMode.value);
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  void deleteAllData() {
    Get.defaultDialog(
      title: 'Hapus Semua Data',
      middleText: 'Semua data lokal akan dihapus dari perangkat.',
      confirm: TextButton(
        onPressed: () async {
          await SyncStorage.clearAll();
          Get.back();
          Get.snackbar('Data lokal', 'Antrean sinkronisasi berhasil dihapus.');
        },
        child: const Text('Hapus'),
      ),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
    );
  }

  Future<void> logout() async {
    await Get.find<SessionService>().logout();
    Get.offAllNamed('/login');
  }

  void confirmRestoreServerState() {
    Get.defaultDialog(
      title: 'Pulihkan dari Server',
      middleText:
          'Unduh state terakhir yang sudah diterima server, termasuk kunjungan aktif. Data yang belum pernah tersinkron tidak dapat dipulihkan.',
      textConfirm: 'Pulihkan',
      textCancel: 'Batal',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        restoreServerState();
      },
      onCancel: () => Get.back(),
    );
  }

  Future<void> restoreServerState() async {
    if (isRestoringServerState.value) return;
    isRestoringServerState.value = true;
    try {
      await Get.find<SyncManager>().syncNow();
      final result = await Get.find<ServerStateRestoreService>().restore();
      lastServerStateRestoreAt.value = DateTime.now().toIso8601String();

      if (Get.isRegistered<HomeController>()) {
        await Get.find<HomeController>().refreshDashboard();
      }
      if (Get.isRegistered<VisitController>()) {
        await Get.find<VisitController>().loadVisits();
      }

      Get.snackbar(
        'State dipulihkan',
        '${result.records} data dipulihkan dari state server terakhir.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on StateError catch (error) {
      Get.snackbar('Tidak dapat memulihkan', error.message, snackPosition: SnackPosition.BOTTOM);
    } on FormatException catch (error) {
      Get.snackbar('State server tidak valid', error.message, snackPosition: SnackPosition.BOTTOM);
    } catch (_) {
      Get.snackbar(
        'Pemulihan gagal',
        'State server belum dapat diambil. Coba lagi saat koneksi stabil.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isRestoringServerState.value = false;
    }
  }
}
