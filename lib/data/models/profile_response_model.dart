class ProfileResponse {
  final int id;
  final String username;
  final String email;
  final String phone;
  final String fullName;
  final String? gender;
  final String? birthDate;
  final String? avatarUrl;
  final double walletBalance;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProfileResponse({
    required this.id,
    required this.username,
    required this.email,
    required this.phone,
    required this.fullName,
    this.gender,
    this.birthDate,
    this.avatarUrl,
    required this.walletBalance,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) => ProfileResponse(
    id: _parseInt(json['id']),
    username: json['username']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    phone: json['phone']?.toString() ?? '',
    fullName: json['full_name']?.toString() ?? '',
    gender: json['gender']?.toString(),
    birthDate: json['birth_date']?.toString(),
    avatarUrl: json['avatar_url']?.toString(),
    walletBalance: _parseDouble(json['wallet_balance']),
    role: json['role']?.toString() ?? 'user',
    createdAt: _parseDateTime(json['created_at']),
    updatedAt: _parseDateTime(json['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'phone': phone,
    'full_name': fullName,
    'gender': gender,
    'birth_date': birthDate,
    'avatar_url': avatarUrl,
    'wallet_balance': walletBalance,
    'role': role,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  ProfileResponse copyWith({
    int? id,
    String? username,
    String? email,
    String? phone,
    String? fullName,
    String? gender,
    String? birthDate,
    String? avatarUrl,
    double? walletBalance,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ProfileResponse(
    id: id ?? this.id,
    username: username ?? this.username,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    fullName: fullName ?? this.fullName,
    gender: gender ?? this.gender,
    birthDate: birthDate ?? this.birthDate,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    walletBalance: walletBalance ?? this.walletBalance,
    role: role ?? this.role,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  @override
  String toString() => 'ProfileResponse(id: $id, username: $username, email: $email, fullName: $fullName)';
}
