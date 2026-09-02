import '../../core/auth/app_roles.dart';
import '../../core/network/api_config.dart';
import '../datasources/remote/auth_remote_data_source.dart';
import '../models/auth_session_model.dart';

class AuthRepository {
  AuthRepository({AuthRemoteDataSource? remoteDataSource}) : _remoteDataSource = remoteDataSource ?? AuthRemoteDataSource();
  final AuthRemoteDataSource _remoteDataSource;

  bool get _usesDevelopmentFallback => baseUrl.contains('salesgo.local');

  Future<AuthSessionModel> login({required String username, required String password}) async {
    if (_usesDevelopmentFallback) return _developmentSession(username);
    return _remoteDataSource.login(username: username, password: password);
  }

  Future<AuthSessionModel> refresh(String refreshToken) => _remoteDataSource.refresh(refreshToken);

  Future<void> logout() => _usesDevelopmentFallback ? Future.value() : _remoteDataSource.logout();

  AuthSessionModel _developmentSession(String username) {
    final normalized = username.toLowerCase();
    final role = normalized == 'it' || normalized.contains('administrator')
        ? AppRole.it
        : normalized.contains('marketing')
        ? AppRole.marketing
        : normalized.contains('supervisor')
        ? AppRole.supervisor
        : normalized.contains('manager')
            ? AppRole.branchManager
            : normalized.contains('key')
                ? AppRole.keyAccountManager
                : AppRole.sales;
    return AuthSessionModel(
      accessToken: 'development-token-$normalized',
      refreshToken: 'development-refresh-$normalized',
      userName: username.isEmpty ? 'Sales' : username,
      role: role,
      expiresAt: _developmentSessionExpiry(),
    );
  }

  DateTime _developmentSessionExpiry() {
    final now = DateTime.now();
    // Batas dev mengikuti aturan produksi: paling lambat tengah malam waktu
    // perangkat, dan tidak lebih dari 24 jam dari waktu login.
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final max = now.add(const Duration(hours: 24));
    return midnight.isBefore(max) ? midnight : max;
  }
}
