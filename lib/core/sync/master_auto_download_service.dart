import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../auth/session_service.dart';
import '../storage/local_storage.dart';
import 'master_data_download_service.dart';
import '../../modules/home/home_controller.dart';
import '../../modules/information/information_controller.dart';
import '../../modules/outlet/outlet_controller.dart';
import '../../modules/product/product_controller.dart';
import '../../modules/visit/visit_controller.dart';

/// Refreshes master cache at most once per calendar day while the app is alive.
/// A startup dialog can be hidden; refresh continues in the background.
class MasterAutoDownloadService with WidgetsBindingObserver {
  MasterAutoDownloadService({
    required MasterDataDownloadService downloader,
    required SessionService session,
  }) : _downloader = downloader,
       _session = session;

  final MasterDataDownloadService _downloader;
  final SessionService _session;
  Timer? _timer;
  bool _running = false;
  bool _progressDialogVisible = false;
  final RxBool isDownloading = false.obs;
  final RxDouble progress = 0.0.obs;
  final RxString label = ''.obs;

  void start({bool showProgress = false}) {
    WidgetsBinding.instance.addObserver(this);
    _timer ??= Timer.periodic(
      const Duration(minutes: 15),
      (_) => refreshIfDue(),
    );
    if (showProgress) {
      Future<void>.delayed(
        const Duration(milliseconds: 450),
        () => refreshIfDue(showProgress: true),
      );
    } else {
      unawaited(refreshIfDue());
    }
  }

  Future<void> refreshIfDue({bool showProgress = false}) async {
    if (_running || !_session.isAuthenticated) return;
    final today = _dayKey(DateTime.now());
    final downloaded = LocalStorage.appBox
        .get('last_master_download_day')
        ?.toString();
    if (downloaded == today) return;
    _running = true;
    isDownloading.value = true;
    progress.value = 0;
    label.value = 'Menyiapkan unduhan data terbaru...';
    if (showProgress) _showProgressDialog();
    try {
      await _downloader.download(
        onProgress: (value) {
          progress.value = value.value;
          label.value = value.label;
        },
      );
      await _refreshVisibleCache();
    } catch (_) {
      // Offline/server errors keep the last valid local master cache. The next
      // timer tick or app resume retries without disturbing the user.
    } finally {
      _running = false;
      isDownloading.value = false;
      if (_progressDialogVisible && (Get.isDialogOpen ?? false)) Get.back();
      _progressDialogVisible = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed)
      unawaited(refreshIfDue(showProgress: true));
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _timer = null;
  }

  String _dayKey(DateTime value) => '${value.year}-${value.month}-${value.day}';

  void _showProgressDialog() {
    if (_progressDialogVisible || Get.context == null) return;
    _progressDialogVisible = true;
    Get.dialog<void>(
      PopScope(
        onPopInvokedWithResult: (_, __) => _progressDialogVisible = false,
        child: Obx(
          () => AlertDialog(
            title: const Text('Memperbarui data'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.value),
                const SizedBox(height: 14),
                LinearProgressIndicator(value: progress.value),
                const SizedBox(height: 8),
                Text(
                  '${(progress.value * 100).round()}%',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _progressDialogVisible = false;
                  Get.back();
                },
                child: const Text('Sembunyikan'),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  Future<void> _refreshVisibleCache() async {
    if (Get.isRegistered<ProductController>())
      await Get.find<ProductController>().refreshFromCache();
    if (Get.isRegistered<OutletController>())
      await Get.find<OutletController>().refreshFromCache();
    if (Get.isRegistered<InformationController>())
      await Get.find<InformationController>().refreshFromCache();
    if (Get.isRegistered<VisitController>())
      await Get.find<VisitController>().loadVisits();
    if (Get.isRegistered<HomeController>())
      await Get.find<HomeController>().refreshDashboard();
  }
}
