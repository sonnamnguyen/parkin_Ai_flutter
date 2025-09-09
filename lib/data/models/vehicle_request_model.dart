class VehicleRequest {
  final String licensePlate;
  final String brand;
  final String model;
  final String color;
  final String type;

  VehicleRequest({
    required this.licensePlate,
    required this.brand,
    required this.model,
    required this.color,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
    'license_plate': licensePlate,
    'brand': brand,
    'model': model,
    'color': color,
    'type': type,
  };
}
