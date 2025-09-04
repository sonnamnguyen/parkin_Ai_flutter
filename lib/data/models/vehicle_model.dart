class Vehicle {
  final int id;
  final int userId;
  final String licensePlate;
  final String brand;
  final String model;
  final String color;
  final String type;
  final DateTime createdAt;

  Vehicle({
    required this.id,
    required this.userId,
    required this.licensePlate,
    required this.brand,
    required this.model,
    required this.color,
    required this.type,
    required this.createdAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
    id: json['id'] as int,
    userId: json['user_id'] as int,
    licensePlate: json['license_plate'] as String,
    brand: json['brand'] as String,
    model: json['model'] as String,
    color: json['color'] as String,
    type: json['type'] as String,
    createdAt: DateTime.parse(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
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
    String? licensePlate,
    String? brand,
    String? model,
    String? color,
    String? type,
    DateTime? createdAt,
  }) => Vehicle(
    id: id ?? this.id,
    userId: userId ?? this.userId,
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