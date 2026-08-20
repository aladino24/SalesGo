import 'package:get/get.dart';

import '../storage/local_storage.dart';
import 'app_roles.dart';
import '../../data/models/auth_session_model.dart';

class SessionService extends GetxService {
  static const _keyUserRole = 'user_role';
  static const _keyUserName = 'user_name';
  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyExpiresAt = 'expires_at';

  final Rx<AppRole?> currentRole = Rx<AppRole?>(null);
  final RxString userName = ''.obs;
  final RxString accessToken = ''.obs;
  final RxString refreshToken = ''.obs;
  final Rx<DateTime?> expiresAt = Rx<DateTime?>(null);

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
    accessToken.value = savedAccessToken ?? '';
    refreshToken.value = await LocalStorage.readSession(_keyRefreshToken) ?? '';
    final savedExpiry = await LocalStorage.readSession(_keyExpiresAt);
    expiresAt.value = savedExpiry == null ? null : DateTime.tryParse(savedExpiry);
    return isAuthenticated;
  }

  Future<void> saveSession(AuthSessionModel session) async {
    currentRole.value = session.role;
    userName.value = session.userName;
    accessToken.value = session.accessToken;
    refreshToken.value = session.refreshToken ?? '';
    expiresAt.value = session.expiresAt;
    await LocalStorage.saveSession(_keyUserRole, session.role.name);
    await LocalStorage.saveSession(_keyUserName, session.userName);
    await LocalStorage.saveSession(_keyAccessToken, session.accessToken);
    if (session.refreshToken != null) await LocalStorage.saveSession(_keyRefreshToken, session.refreshToken!);
    if (session.expiresAt != null) await LocalStorage.saveSession(_keyExpiresAt, session.expiresAt!.toIso8601String());
  }

  Future<void> logout() async {
    currentRole.value = null;
    userName.value = '';
    accessToken.value = '';
    refreshToken.value = '';
    expiresAt.value = null;
    await LocalStorage.deleteSession(_keyUserRole);
    await LocalStorage.deleteSession(_keyUserName);
    await LocalStorage.deleteSession(_keyAccessToken);
    await LocalStorage.deleteSession(_keyRefreshToken);
    await LocalStorage.deleteSession(_keyExpiresAt);
  }
}
