import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/device/app_device_identity.dart';
import '../../models/auth_session_model.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<AuthSessionModel> login({required String username, required String password}) async {
    final deviceId = await AppDeviceIdentity.id();
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      data: {
        'username': username,
        'password': password,
        'deviceId': deviceId,
        'platform': AppDeviceIdentity.platform,
      },
    );
    return AuthSessionModel.fromJson(response);
  }

  Future<AuthSessionModel> refresh(String refreshToken) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.refreshToken,
      data: {'refreshToken': refreshToken},
    );
    return AuthSessionModel.fromJson(response);
  }

  Future<void> logout() => _apiClient.post<void>(ApiEndpoints.logout);
}
