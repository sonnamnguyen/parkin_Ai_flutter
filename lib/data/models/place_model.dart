class PlaceModel {
  final String placeId;
  final String name;
  final String formattedAddress;
  final double? latitude;
  final double? longitude;
  final String? photoReference;
  final double? rating;
  final int? userRatingsTotal;
  final List<String> types;
  final String? vicinity;

  PlaceModel({
    required this.placeId,
    required this.name,
    required this.formattedAddress,
    this.latitude,
    this.longitude,
    this.photoReference,
    this.rating,
    this.userRatingsTotal,
    this.types = const [],
    this.vicinity,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    
    return PlaceModel(
      placeId: json['place_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      formattedAddress: json['formatted_address'] as String? ?? '',
      latitude: location?['lat']?.toDouble(),
      longitude: location?['lng']?.toDouble(),
      photoReference: json['photos']?.isNotEmpty == true 
          ? json['photos'][0]['photo_reference'] as String?
          : null,
      rating: json['rating']?.toDouble(),
      userRatingsTotal: json['user_ratings_total'] as int?,
      types: (json['types'] as List<dynamic>?)?.cast<String>() ?? [],
      vicinity: json['vicinity'] as String?,
    );
  }

  factory PlaceModel.fromGoongJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    
    return PlaceModel(
      placeId: json['place_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      formattedAddress: json['formatted_address'] as String? ?? '',
      latitude: location?['lat']?.toDouble(),
      longitude: location?['lng']?.toDouble(),
      photoReference: json['photos']?.isNotEmpty == true 
          ? json['photos'][0]['photo_reference'] as String?
          : null,
      rating: json['rating']?.toDouble(),
      userRatingsTotal: json['user_ratings_total'] as int?,
      types: (json['types'] as List<dynamic>?)?.cast<String>() ?? [],
      vicinity: json['vicinity'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'place_id': placeId,
      'name': name,
      'formatted_address': formattedAddress,
      'latitude': latitude,
      'longitude': longitude,
      'photo_reference': photoReference,
      'rating': rating,
      'user_ratings_total': userRatingsTotal,
      'types': types,
      'vicinity': vicinity,
    };
  }

  @override
  String toString() {
    return 'PlaceModel(placeId: $placeId, name: $name, formattedAddress: $formattedAddress)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlaceModel && other.placeId == placeId;
  }

  @override
  int get hashCode => placeId.hashCode;
}

class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;
  final List<String> types;

  PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
    this.types = const [],
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    final structuredFormatting = json['structured_formatting'] as Map<String, dynamic>?;
    
    return PlacePrediction(
      placeId: json['place_id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      mainText: structuredFormatting?['main_text'] as String? ?? '',
      secondaryText: structuredFormatting?['secondary_text'] as String? ?? '',
      types: (json['types'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  factory PlacePrediction.fromGoongJson(Map<String, dynamic> json) {
    return PlacePrediction(
      placeId: json['place_id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      mainText: json['structured_formatting']?['main_text'] as String? ?? '',
      secondaryText: json['structured_formatting']?['secondary_text'] as String? ?? '',
      types: (json['types'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'place_id': placeId,
      'description': description,
      'main_text': mainText,
      'secondary_text': secondaryText,
      'types': types,
    };
  }

  @override
  String toString() {
    return 'PlacePrediction(placeId: $placeId, description: $description)';
  }
}
