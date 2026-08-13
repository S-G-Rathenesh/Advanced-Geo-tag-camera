import 'user_model.dart';

/// Login response from the authentication endpoint.
class LoginResponse {
  final bool success;
  final String? token;
  final String? refreshToken;
  final UserModel? user;
  final String? error;

  const LoginResponse({
    required this.success,
    this.token,
    this.refreshToken,
    this.user,
    this.error,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] as bool,
      token: json['token'] as String?,
      refreshToken: json['refresh_token'] as String?,
      user: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      error: json['error'] as String?,
    );
  }

  factory LoginResponse.error(String message) {
    return LoginResponse(success: false, error: message);
  }
}
