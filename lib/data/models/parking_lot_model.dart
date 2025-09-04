import 'parking_hours_model.dart';

class ParkingLot {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double pricePerHour;
  final int totalSlots;
  final int availableSlots;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final List<String> amenities;
  final String description;
  final ParkingHours operatingHours;
  final bool isOpen;
  final double distance; // in meters

  ParkingLot({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.pricePerHour,
    required this.totalSlots,
    required this.availableSlots,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
    required this.amenities,
    required this.description,
    required this.operatingHours,
    required this.isOpen,
    this.distance = 0.0,
  });

  factory ParkingLot.fromJson(Map<String, dynamic> json) => ParkingLot(
    id: json['id'] as int,
    name: json['name'] as String,
    address: json['address'] as String,
    latitude: double.parse(json['latitude'].toString()),
    longitude: double.parse(json['longitude'].toString()),
    pricePerHour: double.parse(json['price_per_hour'].toString()),
    totalSlots: json['total_slots'] as int,
    availableSlots: json['available_slots'] as int,
    rating: double.parse(json['rating'].toString()),
    reviewCount: json['review_count'] as int,
    imageUrl: json['image_url'] as String,
    amenities: List<String>.from(json['amenities'] as List),
    description: json['description'] as String,
    operatingHours: ParkingHours.fromJson(json['operating_hours']),
    isOpen: json['is_open'] as bool,
    distance: json['distance'] != null ? double.parse(json['distance'].toString()) : 0.0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'price_per_hour': pricePerHour,
    'total_slots': totalSlots,
    'available_slots': availableSlots,
    'rating': rating,
    'review_count': reviewCount,
    'image_url': imageUrl,
    'amenities': amenities,
    'description': description,
    'operating_hours': operatingHours.toJson(),
    'is_open': isOpen,
    'distance': distance,
  };

  bool get hasAvailableSlots => availableSlots > 0;
  String get distanceText => distance < 1000 
      ? '${distance.toInt()}m' 
      : '${(distance / 1000).toStringAsFixed(1)}km';
  
  String get priceText => '${pricePerHour.toInt().toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  )} VNĐ/giờ';
}