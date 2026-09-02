import 'dart:io';

import 'package:uuid/uuid.dart';

import '../storage/local_storage.dart';

/// Identifier acak per instalasi aplikasi. Ini bukan IMEI, nomor telepon,
/// maupun identifier perangkat fisik dan dapat dihapus bersama data aplikasi.
class AppDeviceIdentity {
  static const _deviceIdKey = 'app_installation_device_id';

  static Future<String> id() async {
    final existing = await LocalStorage.readSession(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    const uuid = Uuid();
    final value = uuid.v4();
    await LocalStorage.saveSession(_deviceIdKey, value);
    return value;
  }

  static String get platform => Platform.isIOS ? 'ios' : 'android';
}
