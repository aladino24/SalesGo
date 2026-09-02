import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../network/api_client.dart';
import '../network/api_endpoints.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.available,
    required this.versionName,
    required this.versionCode,
    required this.md5,
    required this.sizeBytes,
    required this.mandatory,
    required this.notes,
    required this.downloadPath,
  });

  final bool available;
  final String versionName;
  final int versionCode;
  final String md5;
  final int sizeBytes;
  final bool mandatory;
  final String notes;
  final String? downloadPath;

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) => AppUpdateInfo(
        available: json['updateAvailable'] == true,
        versionName: json['versionName']?.toString() ?? '',
        versionCode: int.tryParse(json['versionCode']?.toString() ?? '') ?? 0,
        md5: json['md5']?.toString().toLowerCase() ?? '',
        sizeBytes: int.tryParse(json['sizeBytes']?.toString() ?? '') ?? 0,
        mandatory: json['mandatory'] == true,
        notes: json['releaseNotes']?.toString() ?? '',
        downloadPath: json['downloadPath']?.toString(),
      );
}

class AppUpdateService {
  AppUpdateService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  static const _channel = MethodChannel('salesgo/app_update');
  final ApiClient _apiClient;

  Future<Map<String, dynamic>> installedApp() async {
    if (!Platform.isAndroid) return const {};
    final value = await _channel.invokeMapMethod<String, dynamic>('installedApp');
    return value == null ? const {} : Map<String, dynamic>.from(value);
  }

  Future<AppUpdateInfo> check() async {
    final installed = await installedApp();
    final data = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.appUpdateCheck,
      queryParameters: {
        'versionCode': installed['versionCode']?.toString() ?? '0',
        'versionName': installed['versionName']?.toString() ?? '',
        'md5': installed['md5']?.toString() ?? '',
      },
    );
    return AppUpdateInfo.fromJson(data);
  }

  Future<void> downloadAndInstall(
    AppUpdateInfo update, {
    required void Function(int received, int total) onProgress,
  }) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('Pembaruan APK hanya tersedia untuk Android.');
    }
    final downloadPath = update.downloadPath;
    if (downloadPath == null || downloadPath.isEmpty) {
      throw StateError('Server tidak mengirim tautan unduhan APK.');
    }
    // APK hanya diperlukan sampai installer Android dibuka. Cache internal
    // tidak memerlukan storage permission dan sudah dibagikan oleh FileProvider.
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}SalesGo-${update.versionCode}.apk');
    if (await file.exists()) await file.delete();
    await _apiClient.download(downloadPath, file.path, onReceiveProgress: onProgress);

    final actualMd5 = (await _channel.invokeMethod<String>('fileMd5', {
          'path': file.path,
        }))
            ?.toLowerCase() ??
        '';
    if (update.md5.isEmpty || actualMd5 != update.md5) {
      await file.delete();
      throw StateError('Integritas APK tidak valid. Unduhan dibatalkan.');
    }
    final result = await _channel.invokeMethod<String>('installApk', {
      'path': file.path,
    });
    if (result == 'permission_required') {
      throw StateError('Izinkan “Install unknown apps” untuk SalesGo, lalu tekan Instal lagi.');
    }
    if (result != 'installer_opened') {
      throw StateError('Installer Android tidak dapat dibuka.');
    }
  }
}
