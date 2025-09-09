// lib/data/models/auth_response_model.dart
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final int userId;
  final String username;
  final String role;
  final double walletBalance;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.username,
    required this.role,
    required this.walletBalance,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    accessToken: json['access_token'] as String,
    refreshToken: json['refresh_token'] as String,
    userId: json['user_id'] as int,
    username: json['username'] as String,
    role: json['role'] as String,
    walletBalance: double.parse(json['wallet_balance'].toString()),
  );

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'user_id': userId,
    'username': username,
    'role': role,
    'wallet_balance': walletBalance,
  };
}