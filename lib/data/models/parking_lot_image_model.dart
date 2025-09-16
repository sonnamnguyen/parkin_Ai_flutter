class ParkingLotImage {
  final int id;
  final int parkingLotId;
  final String lotName;
  final String imageUrl;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  ParkingLotImage({
    required this.id,
    required this.parkingLotId,
    required this.lotName,
    required this.imageUrl,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ParkingLotImage.fromJson(Map<String, dynamic> json) => ParkingLotImage(
    id: _parseInt(json['id']),
    parkingLotId: _parseInt(json['parking_lot_id']),
    lotName: json['lot_name']?.toString() ?? '',
    imageUrl: json['image_url']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    createdAt: _parseDateTime(json['created_at']),
    updatedAt: _parseDateTime(json['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'parking_lot_id': parkingLotId,
    'lot_name': lotName,
    'image_url': imageUrl,
    'description': description,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      // Remove any non-numeric characters except minus sign
      final cleaned = value.replaceAll(RegExp(r'[^\d.-]'), '');
      return int.tryParse(cleaned) ?? 0;
    }
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

  @override
  String toString() => 'ParkingLotImage(id: $id, lotName: $lotName, imageUrl: $imageUrl)';
}
