import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../storage/local_storage.dart';
import 'app_roles.dart';
import '../../data/models/auth_session_model.dart';
import '../location/location_tracking_service.dart';
import '../sync/master_auto_download_service.dart';

class SessionService extends GetxService {
  static const _keyUserRole = 'user_role';
  static const _keyUserName = 'user_name';
  static const _keyUserId = 'user_id';
  static const _keyEmployeeCode = 'employee_code';
  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyExpiresAt = 'expires_at';

  final Rx<AppRole?> currentRole = Rx<AppRole?>(null);
  final RxString userName = ''.obs;
  final RxString userId = ''.obs;
  final RxString employeeCode = ''.obs;
  final RxString accessToken = ''.obs;
  final RxString refreshToken = ''.obs;
  final Rx<DateTime?> expiresAt = Rx<DateTime?>(null);
  Timer? _expiryTimer;

  bool get isAuthenticated => currentRole.value != null && accessToken.value.isNotEmpty && !isAccessTokenExpired;
  bool get isAccessTokenExpired => expiresAt.value != null && !expiresAt.value!.isAfter(DateTime.now());

  Future<void> loginAs(AppRole role, String name) async {
    await saveSession(AuthSessionModel(
      accessToken: 'development-token-${name.toLowerCase()}',
      refreshToken: null,
      userName: name,
      role: role,
    ));
  }

  Future<bool> loadSession() async {
    final savedRole = await LocalStorage.readSession(_keyUserRole);
    final savedName = await LocalStorage.readSession(_keyUserName);

    final savedAccessToken = await LocalStorage.readSession(_keyAccessToken);
    if (savedRole != null && savedAccessToken != null && savedAccessToken.isNotEmpty) {
      currentRole.value = AppRole.values.firstWhere(
        (role) => role.name == savedRole,
        orElse: () => AppRole.sales,
      );
    }

    userName.value = savedName ?? 'Sales';
    userId.value = await LocalStorage.readSession(_keyUserId) ?? '';
    employeeCode.value = await LocalStorage.readSession(_keyEmployeeCode) ?? '';
    accessToken.value = savedAccessToken ?? '';
    refreshToken.value = await LocalStorage.readSession(_keyRefreshToken) ?? '';
    final savedExpiry = await LocalStorage.readSession(_keyExpiresAt);
    expiresAt.value = savedExpiry == null ? null : DateTime.tryParse(savedExpiry);
    _scheduleExpiry();
    return isAuthenticated;
  }

  Future<void> saveSession(AuthSessionModel session) async {
    currentRole.value = session.role;
    userName.value = session.userName;
    userId.value = session.userId ?? '';
    employeeCode.value = session.employeeCode ?? '';
    accessToken.value = session.accessToken;
    refreshToken.value = session.refreshToken ?? '';
    expiresAt.value = session.expiresAt;
    _scheduleExpiry();
    await LocalStorage.saveSession(_keyUserRole, session.role.name);
    await LocalStorage.saveSession(_keyUserName, session.userName);
    if (session.userId != null) {
      await LocalStorage.saveSession(_keyUserId, session.userId!);
    } else {
      await LocalStorage.deleteSession(_keyUserId);
    }
    if (session.employeeCode != null) {
      await LocalStorage.saveSession(_keyEmployeeCode, session.employeeCode!);
    } else {
      await LocalStorage.deleteSession(_keyEmployeeCode);
    }
    await LocalStorage.saveSession(_keyAccessToken, session.accessToken);
    if (session.refreshToken != null) await LocalStorage.saveSession(_keyRefreshToken, session.refreshToken!);
    if (session.expiresAt != null) await LocalStorage.saveSession(_keyExpiresAt, session.expiresAt!.toIso8601String());
    if (Get.isRegistered<LocationTrackingService>()) {
      unawaited(Get.find<LocationTrackingService>().start());
    }
  }

  Future<void> logout() async {
    if (Get.isRegistered<LocationTrackingService>()) {
      await Get.find<LocationTrackingService>().stop();
    }
    if (Get.isRegistered<MasterAutoDownloadService>()) {
      Get.find<MasterAutoDownloadService>().dispose();
    }
    _expiryTimer?.cancel();
    currentRole.value = null;
    userName.value = '';
    userId.value = '';
    employeeCode.value = '';
    accessToken.value = '';
    refreshToken.value = '';
    expiresAt.value = null;
    await LocalStorage.deleteSession(_keyUserRole);
    await LocalStorage.deleteSession(_keyUserName);
    await LocalStorage.deleteSession(_keyUserId);
    await LocalStorage.deleteSession(_keyEmployeeCode);
    await LocalStorage.deleteSession(_keyAccessToken);
    await LocalStorage.deleteSession(_keyRefreshToken);
    await LocalStorage.deleteSession(_keyExpiresAt);
  }

  void _scheduleExpiry() {
    _expiryTimer?.cancel();
    final expiry = expiresAt.value;
    if (expiry == null) return;
    final duration = expiry.difference(DateTime.now());
    if (duration <= Duration.zero) {
      unawaited(_handleExpiredSession());
      return;
    }
    _expiryTimer = Timer(duration, _handleExpiredSession);
  }

  Future<void> _handleExpiredSession() async {
    await logout();
    if (Get.isDialogOpen ?? false) Get.back();
    await Get.dialog<void>(
      AlertDialog(
        title: const Text('Sesi telah berakhir'),
        content: const Text('Sesi login berlaku selama 5 jam. Silakan masuk kembali untuk melanjutkan.'),
        actions: [FilledButton(onPressed: () => Get.back(), child: const Text('Ke Login'))],
      ),
      barrierDismissible: false,
    );
    Get.offAllNamed('/login');
  }
}
