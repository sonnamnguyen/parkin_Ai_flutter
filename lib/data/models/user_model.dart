class User {
  final int id;
  final String username;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final String? avatarUrl;
  final double walletBalance;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.avatarUrl,
    required this.walletBalance,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as int,
    username: json['username'] as String,
    fullName: json['full_name'] as String,
    email: json['email'] as String,
    phone: json['phone'] as String,
    role: json['role'] as String,
    avatarUrl: json['avatar_url'] as String?,
    walletBalance: double.parse(json['wallet_balance'].toString()),
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'full_name': fullName,
    'email': email,
    'phone': phone,
    'role': role,
    'avatar_url': avatarUrl,
    'wallet_balance': walletBalance,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  User copyWith({
    int? id,
    String? username,
    String? fullName,
    String? email,
    String? phone,
    String? role,
    String? avatarUrl,
    double? walletBalance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => User(
    id: id ?? this.id,
    username: username ?? this.username,
    fullName: fullName ?? this.fullName,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    role: role ?? this.role,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    walletBalance: walletBalance ?? this.walletBalance,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  String toString() => 'User(id: $id, username: $username, email: $email)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}