class Vehicle {
  final int id;
  final int userId;
  final String username;
  final String licensePlate;
  final String brand;
  final String model;
  final String color;
  final String type;
  final DateTime createdAt;

  Vehicle({
    required this.id,
    required this.userId,
    required this.username,
    required this.licensePlate,
    required this.brand,
    required this.model,
    required this.color,
    required this.type,
    required this.createdAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
    id: _parseInt(json['id']),
    userId: _parseInt(json['user_id']),
    username: json['username']?.toString() ?? '',
    licensePlate: json['license_plate']?.toString() ?? '',
    brand: json['brand']?.toString() ?? '',
    model: json['model']?.toString() ?? '',
    color: json['color']?.toString() ?? '',
    type: json['type']?.toString() ?? 'car',
    createdAt: _parseDateTime(json['created_at']),
  );

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'username': username,
    'license_plate': licensePlate,
    'brand': brand,
    'model': model,
    'color': color,
    'type': type,
    'created_at': createdAt.toIso8601String(),
  };

  Vehicle copyWith({
    int? id,
    int? userId,
    String? username,
    String? licensePlate,
    String? brand,
    String? model,
    String? color,
    String? type,
    DateTime? createdAt,
  }) => Vehicle(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    username: username ?? this.username,
    licensePlate: licensePlate ?? this.licensePlate,
    brand: brand ?? this.brand,
    model: model ?? this.model,
    color: color ?? this.color,
    type: type ?? this.type,
    createdAt: createdAt ?? this.createdAt,
  );

  String get displayName => '$brand $model';
  
  @override
  String toString() => 'Vehicle(id: $id, licensePlate: $licensePlate, brand: $brand, model: $model)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vehicle && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}