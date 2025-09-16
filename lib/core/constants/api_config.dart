import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // Google Places API Configuration
  // Prefer PLACE_API_KEY; fallback to MAPS_API_KEY for backward compatibility
 static String get googlePlacesApiKey {
  final key = dotenv.env['PLACE_API_KEY'];
  if (key == null || key.isEmpty) {
    throw Exception("Google Places API key not found in environment variables");
  }
  return key;
}

  
  // API Endpoints
  static const String googlePlacesBaseUrl = 'https://maps.googleapis.com/maps/api/place';
  
  // Default settings
  static const String defaultLanguage = 'vi';
  static const String defaultCountry = 'vn';
  static const double defaultSearchRadius = 5000.0; // 5km
  
  // Validate that the API key is loaded
  static bool get isApiKeyLoaded => googlePlacesApiKey.isNotEmpty;
}
