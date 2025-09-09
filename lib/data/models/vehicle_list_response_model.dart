import 'vehicle_model.dart';

class VehicleListResponse {
  final List<Vehicle> list;
  final int total;

  VehicleListResponse({
    required this.list,
    required this.total,
  });

  factory VehicleListResponse.fromJson(Map<String, dynamic> json) => VehicleListResponse(
    list: (json['list'] as List? ?? [])
        .map((vehicle) => Vehicle.fromJson(vehicle as Map<String, dynamic>))
        .toList(),
    total: _parseInt(json['total']),
  );

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() => {
    'list': list.map((vehicle) => vehicle.toJson()).toList(),
    'total': total,
  };
}
