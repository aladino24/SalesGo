import '../../core/auth/app_roles.dart';

class AuthSessionModel {
  const AuthSessionModel({
    required this.accessToken,
    required this.refreshToken,
    required this.userName,
    required this.role,
    this.expiresAt,
  });

  final String accessToken;
  final String? refreshToken;
  final String userName;
  final AppRole role;
  final DateTime? expiresAt;

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? json;
    final roleName = (user['role'] ?? json['role'] ?? 'sales').toString();
    return AuthSessionModel(
      accessToken: (json['accessToken'] ?? json['token'] ?? '').toString(),
      refreshToken: json['refreshToken']?.toString(),
      userName: (user['name'] ?? user['username'] ?? '').toString(),
      role: AppRole.values.firstWhere(
        (role) => role.name.toLowerCase() == roleName.toLowerCase(),
        orElse: () => AppRole.sales,
      ),
      expiresAt: json['expiresAt'] == null ? null : DateTime.tryParse(json['expiresAt'].toString()),
    );
  }
}
