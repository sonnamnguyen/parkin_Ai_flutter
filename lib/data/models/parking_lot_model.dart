import 'parking_lot_image_model.dart';
import 'parking_hours_model.dart';

class ParkingLot {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final int ownerId;
  final bool isVerified;
  final bool isActive;
  final int totalSlots;
  final int availableSlots;
  final double pricePerHour;
  final String description;
  final String openTime;
  final String closeTime;
  final String imageUrl;
  final List<ParkingLotImage> images;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Additional properties for UI compatibility
  final double rating;
  final int reviewCount;
  final List<String> amenities;
  final ParkingHours? operatingHours;
  final bool isOpen;
  final double distance;

  ParkingLot({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.ownerId,
    required this.isVerified,
    required this.isActive,
    required this.totalSlots,
    required this.availableSlots,
    required this.pricePerHour,
    required this.description,
    required this.openTime,
    required this.closeTime,
    required this.imageUrl,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.amenities = const [],
    this.operatingHours,
    this.isOpen = true,
    this.distance = 0.0,
  });

  factory ParkingLot.fromJson(Map<String, dynamic> json) {
    try {
      return ParkingLot(
        id: _parseInt(json['id']),
        name: json['name']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        latitude: _parseDouble(json['latitude']),
        longitude: _parseDouble(json['longitude']),
        ownerId: _parseInt(json['owner_id']),
        isVerified: json['is_verified'] == true || json['is_verified'] == 'true' || json['is_verified'] == 1,
        isActive: json['is_active'] == true || json['is_active'] == 'true' || json['is_active'] == 1,
        totalSlots: _parseInt(json['total_slots']),
        availableSlots: _parseInt(json['available_slots']),
        pricePerHour: _parseDouble(json['price_per_hour']),
        description: json['description']?.toString() ?? '',
        openTime: _formatTime(json['open_time']?.toString() ?? ''),
        closeTime: _formatTime(json['close_time']?.toString() ?? ''),
        imageUrl: json['image_url']?.toString() ?? '',
        images: (json['images'] as List? ?? [])
            .map((image) {
              try {
                return ParkingLotImage.fromJson(image as Map<String, dynamic>);
              } catch (e) {
                print('Error parsing parking lot image: $e, data: $image');
                return null;
              }
            })
            .where((image) => image != null)
            .cast<ParkingLotImage>()
            .toList(),
        createdAt: _parseDateTime(json['created_at']),
        updatedAt: _parseDateTime(json['updated_at']),
        rating: _parseDouble(json['rating']),
        reviewCount: _parseInt(json['review_count']),
        amenities: (json['amenities'] as List? ?? [])
            .map((amenity) => amenity.toString())
            .toList(),
        operatingHours: json['operating_hours'] != null 
            ? ParkingHours.fromJson(json['operating_hours'] as Map<String, dynamic>)
            : null,
        isOpen: json['is_open'] == true || json['is_open'] == 'true' || json['is_open'] == 1,
        distance: _parseDouble(json['distance']),
      );
    } catch (e) {
      print('Error parsing ParkingLot: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'owner_id': ownerId,
    'is_verified': isVerified,
    'is_active': isActive,
    'total_slots': totalSlots,
    'available_slots': availableSlots,
    'price_per_hour': pricePerHour,
    'description': description,
    'open_time': openTime,
    'close_time': closeTime,
    'image_url': imageUrl,
    'images': images.map((image) => image.toJson()).toList(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'rating': rating,
    'review_count': reviewCount,
    'amenities': amenities,
    'operating_hours': operatingHours?.toJson(),
    'is_open': isOpen,
    'distance': distance,
  };

  ParkingLot copyWith({
    int? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    int? ownerId,
    bool? isVerified,
    bool? isActive,
    int? totalSlots,
    int? availableSlots,
    double? pricePerHour,
    String? description,
    String? openTime,
    String? closeTime,
    String? imageUrl,
    List<ParkingLotImage>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? rating,
    int? reviewCount,
    List<String>? amenities,
    ParkingHours? operatingHours,
    bool? isOpen,
    double? distance,
  }) => ParkingLot(
    id: id ?? this.id,
    name: name ?? this.name,
    address: address ?? this.address,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    ownerId: ownerId ?? this.ownerId,
    isVerified: isVerified ?? this.isVerified,
    isActive: isActive ?? this.isActive,
    totalSlots: totalSlots ?? this.totalSlots,
    availableSlots: availableSlots ?? this.availableSlots,
    pricePerHour: pricePerHour ?? this.pricePerHour,
    description: description ?? this.description,
    openTime: openTime ?? this.openTime,
    closeTime: closeTime ?? this.closeTime,
    imageUrl: imageUrl ?? this.imageUrl,
    images: images ?? this.images,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    rating: rating ?? this.rating,
    reviewCount: reviewCount ?? this.reviewCount,
    amenities: amenities ?? this.amenities,
    operatingHours: operatingHours ?? this.operatingHours,
    isOpen: isOpen ?? this.isOpen,
    distance: distance ?? this.distance,
  );

  // Helper methods
  double get occupancyRate => totalSlots > 0 ? (totalSlots - availableSlots) / totalSlots : 0.0;
  bool get isFullyOccupied => availableSlots == 0;
  bool get hasAvailableSlots => availableSlots > 0;
  String get formattedPrice => '${pricePerHour.toStringAsFixed(1)} VNĐ/giờ';
  String get priceText => '${pricePerHour.toStringAsFixed(0)} VNĐ/giờ';
  String get distanceText => distance > 1000 ? '${(distance / 1000).toStringAsFixed(1)} km' : '${distance.toStringAsFixed(0)} m';
  String get statusText => isActive ? (hasAvailableSlots ? 'Còn chỗ' : 'Hết chỗ') : 'Đóng cửa';

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

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      // Remove any non-numeric characters except minus sign and decimal point
      final cleaned = value.replaceAll(RegExp(r'[^\d.-]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        // Handle different date formats
        if (value.contains(' ')) {
          // Format: "2006-01-02 15:04:05"
          return DateTime.parse(value);
        } else if (value.contains('T')) {
          // ISO format
          return DateTime.parse(value);
        } else {
          // Try parsing as is
          return DateTime.parse(value);
        }
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  static String _formatTime(String timeString) {
    if (timeString.isEmpty) return '';
    
    try {
      // Handle time format like "15:04:05"
      if (timeString.contains(':')) {
        final parts = timeString.split(':');
        if (parts.length >= 2) {
          final hour = int.tryParse(parts[0]) ?? 0;
          final minute = int.tryParse(parts[1]) ?? 0;
          
          // Check if this is a placeholder time (15:04:05 is Go's default time)
          if (hour == 15 && minute == 4) {
            return '24/7'; // Show 24/7 for placeholder times
          }
          
          return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        }
      }
      return timeString;
    } catch (e) {
      return timeString;
    }
  }

  @override
  String toString() => 'ParkingLot(id: $id, name: $name, address: $address)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParkingLot && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}