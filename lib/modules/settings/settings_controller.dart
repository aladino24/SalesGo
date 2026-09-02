import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/auth/session_service.dart';
import '../../core/notifications/push_notification_service.dart';
import '../notification/notification_controller.dart';
import '../../core/storage/sync_storage.dart';
import '../../core/storage/local_storage.dart';
import '../../core/sync/sync_manager.dart';
import '../../core/sync/server_state_restore_service.dart';
import '../../core/sync/master_data_download_service.dart';
import '../../data/repositories/information_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../home/home_controller.dart';
import '../visit/visit_controller.dart';
import '../product/product_controller.dart';
import '../outlet/outlet_controller.dart';
import '../information/information_controller.dart';
import '../../app/widgets/sfa_feedback_dialog.dart';
import '../../core/localization/app_locale.dart';
import '../../core/update/app_update_service.dart';

class SettingsController extends GetxController {
  final RxBool isDarkMode = false.obs;
  final RxBool isRestoringServerState = false.obs;
  final RxString lastServerStateRestoreAt = ''.obs;
  final RxBool isDownloadingMasterData = false.obs;
  final RxDouble masterDownloadProgress = 0.0.obs;
  final RxString masterDownloadLabel = ''.obs;
  final RxString lastMasterDownloadAt = ''.obs;
  final RxString lastMasterDownloadSummary = ''.obs;
  final RxBool isClearingLocalData = false.obs;
  final RxString languageCode = 'id'.obs;
  final RxString appVersionLabel = '1.0.0 (1)'.obs;
  final RxBool isCheckingAppUpdate = false.obs;
  final RxBool isDownloadingAppUpdate = false.obs;
  final RxDouble appUpdateProgress = 0.0.obs;
  final RxString appUpdateLabel = ''.obs;

  @override
  void onInit() {
    super.onInit();
    isDarkMode.value = LocalStorage.appBox.get('dark_mode', defaultValue: false) as bool;
    languageCode.value = AppLocale.current.languageCode;
    lastServerStateRestoreAt.value =
        LocalStorage.appBox.get('last_server_state_restore_at', defaultValue: '') as String;
    lastMasterDownloadAt.value =
        LocalStorage.appBox.get('last_master_download_at', defaultValue: '') as String;
    _loadMasterDownloadSummary();
    Future<void>.microtask(_loadInstalledAppVersion);
  }

  Future<void> _loadInstalledAppVersion() async {
    try {
      final installed = await Get.find<AppUpdateService>().installedApp();
      final name = installed['versionName']?.toString();
      final code = installed['versionCode']?.toString();
      if (name != null && name.isNotEmpty && code != null && code.isNotEmpty) {
        appVersionLabel.value = '$name ($code)';
      }
    } catch (_) {
      // Tampilan fallback tetap tersedia pada platform non-Android.
    }
  }

  Future<void> changeLanguage(String code) async {
    if (code == languageCode.value) return;
    await AppLocale.update(code);
    languageCode.value = code;
  }

  Future<void> checkAppUpdate() async {
    if (isCheckingAppUpdate.value || isDownloadingAppUpdate.value) return;
    isCheckingAppUpdate.value = true;
    try {
      final update = await Get.find<AppUpdateService>().check();
      if (!update.available) {
        await SfaFeedbackDialog.show(
          type: SfaFeedbackType.success,
          title: 'Aplikasi terbaru',
          message: 'Versi aplikasi yang terpasang sudah sama dengan rilis backend.',
        );
        return;
      }
      final accepted = await Get.dialog<bool>(AlertDialog(
        title: const Text('Pembaruan tersedia'),
        content: Text(
          'Versi ${update.versionName} tersedia (${_formatBytes(update.sizeBytes)}).'
          '${update.notes.isEmpty ? '' : '\n\n${update.notes}'}\n\n'
          'Data lokal dan sesi aplikasi tidak akan dihapus saat Android memasang pembaruan.',
        ),
        actions: [
          if (!update.mandatory)
            TextButton(onPressed: () => Get.back(result: false), child: const Text('Nanti')),
          FilledButton(onPressed: () => Get.back(result: true), child: const Text('Unduh & Instal')),
        ],
      ));
      if (accepted == true) await _downloadAndInstall(update);
    } catch (error) {
      await SfaFeedbackDialog.show(
        type: SfaFeedbackType.error,
        title: 'Pemeriksaan update gagal',
        message: error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      isCheckingAppUpdate.value = false;
    }
  }

  Future<void> _downloadAndInstall(AppUpdateInfo update) async {
    isDownloadingAppUpdate.value = true;
    appUpdateProgress.value = 0;
    appUpdateLabel.value = 'Menyiapkan unduhan APK...';
    Get.dialog(
      Obx(() => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Mengunduh pembaruan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(value: appUpdateProgress.value, strokeWidth: 7),
              ),
              const SizedBox(height: 16),
              Text('${(appUpdateProgress.value * 100).round()}%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(appUpdateLabel.value, textAlign: TextAlign.center),
            ],
          ),
        ),
      )),
      barrierDismissible: false,
    );
    try {
      await Get.find<AppUpdateService>().downloadAndInstall(
        update,
        onProgress: (received, total) {
          if (total > 0) {
            appUpdateProgress.value = received / total;
            appUpdateLabel.value = '${_formatBytes(received)} dari ${_formatBytes(total)}';
          } else {
            appUpdateLabel.value = '${_formatBytes(received)} diunduh';
          }
        },
      );
      if (Get.isDialogOpen == true) Get.back();
      await SfaFeedbackDialog.show(
        type: SfaFeedbackType.success,
        title: 'Siap diinstal',
        message: 'Installer Android telah dibuka. Konfirmasi Update untuk mengganti aplikasi tanpa menghapus data lokal.',
      );
    } catch (error) {
      if (Get.isDialogOpen == true) Get.back();
      await SfaFeedbackDialog.show(
        type: SfaFeedbackType.error,
        title: 'Update gagal',
        message: error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      isDownloadingAppUpdate.value = false;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  void showAccount() {
    SfaFeedbackDialog.show(type: SfaFeedbackType.info, title: 'Account', message: 'Informasi user dan role akan ditampilkan di sini.');
  }

  Future<void> syncData() async {
    final sync = Get.find<SyncManager>();
    await sync.syncNow(force: true);
    final stats = sync.syncStats;
    final unresolved = (stats['conflict'] ?? 0) + (stats['blocked'] ?? 0);
    await SfaFeedbackDialog.show(type: unresolved > 0 ? SfaFeedbackType.warning : SfaFeedbackType.sync, title: unresolved > 0 ? 'Sync perlu perhatian' : 'Sinkronisasi selesai', message: unresolved > 0 ? '$unresolved item conflict/gagal perlu ditinjau.' : 'Sinkronisasi data selesai diproses.');
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
      lastMasterDownloadSummary.value = '${result.products} produk • ${result.outlets} outlet • ${result.routes} rute • ${result.promotions} promosi • ${result.files} file';
      if (Get.isRegistered<ProductController>()) {
        await Get.find<ProductController>().refreshFromCache();
      }
      if (Get.isRegistered<OutletController>()) {
        await Get.find<OutletController>().refreshFromCache();
      }
      if (Get.isRegistered<InformationController>()) {
        await Get.find<InformationController>().refreshFromCache();
      }
      if (Get.isRegistered<VisitController>()) {
        await Get.find<VisitController>().loadVisits();
      }
      await SfaFeedbackDialog.show(type: SfaFeedbackType.sync, title: 'Data terbaru siap', message: '${result.products} produk, ${result.outlets} outlet, ${result.routes} rute, ${result.promotions} promosi, dan ${result.files} metadata file diperbarui.');
    } on StateError catch (error) {
      SfaFeedbackDialog.show(type: SfaFeedbackType.error, title: 'Tidak dapat mengunduh', message: error.message);
    } on FormatException catch (error) {
      SfaFeedbackDialog.show(type: SfaFeedbackType.error, title: 'Data server tidak valid', message: error.message);
    } catch (error) {
      // Jangan sembunyikan error HTTP/timeout. Informasi ini diperlukan untuk
      // membedakan masalah jaringan, session, dan payload backend.
      final detail = error.toString().replaceFirst('Exception: ', '');
      SfaFeedbackDialog.show(
        type: SfaFeedbackType.error,
        title: 'Unduhan gagal',
        message: detail.isEmpty
            ? 'Data lokal sebelumnya tetap digunakan. Coba lagi saat koneksi stabil.'
            : '$detail\n\nData lokal sebelumnya tetap digunakan.',
      );
    } finally {
      isDownloadingMasterData.value = false;
    }
  }

  void _loadMasterDownloadSummary() {
    final products = LocalStorage.appBox.get('last_master_products_count');
    final outlets = LocalStorage.appBox.get('last_master_outlets_count');
    final routes = LocalStorage.appBox.get('last_master_routes_count');
    final promotions = LocalStorage.appBox.get('last_master_promotions_count');
    final files = LocalStorage.appBox.get('last_master_files_count');
    if (products is int && outlets is int) {
      lastMasterDownloadSummary.value = '$products produk • $outlets outlet${routes is int ? ' • $routes rute' : ''}${promotions is int ? ' • $promotions promosi' : ''}${files is int ? ' • $files file' : ''}';
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
          Get.back();
          await clearBusinessData();
        },
        child: const Text('Hapus'),
      ),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
    );
  }

  Future<void> logout() async {
    await Get.find<PushNotificationService>().stop();
    try {
      await AuthRepository().logout();
    } catch (_) {
      // Sesi di server akan kedaluwarsa otomatis bila perangkat sedang offline.
    }
    if (Get.isRegistered<NotificationController>()) {
      Get.delete<NotificationController>(force: true);
    }
    await Get.find<SessionService>().logout();
    Get.offAllNamed('/login');
  }

  Future<void> clearBusinessData() async {
    if (isClearingLocalData.value) return;
    isClearingLocalData.value = true;
    try {
      final information = InformationRepository();
      try {
        final cachedFiles = await information.getFiles(online: false);
        for (final file in cachedFiles.where((file) => file.isCached)) {
          await information.removeCache(file);
        }
      } catch (_) {
        // Cache Hive tetap dibersihkan di bawah. Kegagalan satu file tidak
        // boleh menghentikan reset data lokal seluruh aplikasi.
      }
      const boxes = [
        'master_products', 'master_outlets', 'visits', 'sales_orders',
        'outlet_transactions', 'visit_actions', 'visit_timeline', 'journeys', 'journey_activities',
        'journey_download_state', 'delivery_notes', 'meetings', 'approvals_cache',
        'promotions', 'files', 'notifications_cache', 'monitoring_cache',
        'route_master_cache', 'outlet_performance', 'dashboard_cache', 'payment_receivables_cache', 'ship_to_locations_cache', 'payments_local', 'sync_queue_box', 'sync_audit_log',
      ];
      var deletedRecords = 0;
      for (final name in boxes) {
        try {
          final box = Hive.isBoxOpen(name) ? Hive.box(name) : await Hive.openBox(name);
          deletedRecords += box.length;
          await box.clear();
        } catch (_) {
          // Box yang belum pernah dibuat atau gagal dibuka tidak menghalangi
          // penghapusan dataset lokal lainnya.
        }
      }
      await LocalStorage.appBox.deleteAll([
        'last_master_download_at', 'last_master_generated_at', 'last_master_revision',
        'last_master_products_count', 'last_master_outlets_count', 'last_master_routes_count',
        'last_master_promotions_count', 'last_master_files_count',
        'last_master_download_day', 'order_policy',
        'last_server_state_restore_at', 'last_server_state_generated_at',
        'has_server_state_snapshot',
      ]);
      lastMasterDownloadAt.value = '';
      lastMasterDownloadSummary.value = '';
      lastServerStateRestoreAt.value = '';
      if (Get.isRegistered<VisitController>()) Get.find<VisitController>().visits.clear();
      if (Get.isRegistered<ProductController>()) Get.find<ProductController>().products.clear();
      if (Get.isRegistered<OutletController>()) Get.find<OutletController>().outlets.clear();
      await SfaFeedbackDialog.show(type: SfaFeedbackType.delete, title: 'Data lokal dihapus', message: '$deletedRecords data cache dan antrean sync telah dihapus. Sesi login tetap aman. Gunakan Download Data Terbaru untuk memeriksa pemulihan dari server.');
    } finally {
      isClearingLocalData.value = false;
    }
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

      await SfaFeedbackDialog.show(type: SfaFeedbackType.sync, title: 'State dipulihkan', message: '${result.records} data dipulihkan dari state server terakhir.');
    } on StateError catch (error) {
      SfaFeedbackDialog.show(type: SfaFeedbackType.error, title: 'Tidak dapat memulihkan', message: error.message);
    } on FormatException catch (error) {
      SfaFeedbackDialog.show(type: SfaFeedbackType.error, title: 'State server tidak valid', message: error.message);
    } catch (_) {
      SfaFeedbackDialog.show(type: SfaFeedbackType.error, title: 'Pemulihan gagal', message: 'State server belum dapat diambil. Coba lagi saat koneksi stabil.');
    } finally {
      isRestoringServerState.value = false;
    }
  }
}
