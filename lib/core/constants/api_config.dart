import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // Goong Maps API Configuration
  static String get goongMapsApiKey {
    final key = (dotenv.isInitialized ? dotenv.env['MAPS_API_KEY'] : null)
        ?? const String.fromEnvironment('MAPS_API_KEY');
    return key ?? '';
  }
  
  // Mapbox SDK access token (public token for runtime)
  static String get mapboxAccessToken {
    final key = (dotenv.isInitialized ? dotenv.env['ACCESS_TOKEN'] : null)
        ?? const String.fromEnvironment('MAPBOX_ACCESS_TOKEN');
    return key ?? '';
  }

  static String get goongPlacesApiKey {
    final key = (dotenv.isInitialized ? dotenv.env['PLACE_API_KEY'] : null)
        ?? const String.fromEnvironment('PLACE_API_KEY');
    return key ?? '';
  }
  
  // API Endpoints
  static const String goongMapsBaseUrl = 'https://rsapi.goong.io';
  static const String goongPlacesBaseUrl = 'https://rsapi.goong.io/Place';
  
  // Default settings
  static const String defaultLanguage = 'vi';
  static const String defaultCountry = 'vn';
  static const double defaultSearchRadius = 5000.0; // 5km
  
  // Validate that the API keys are loaded
  static bool get isMapsApiKeyLoaded => goongMapsApiKey.isNotEmpty;
  static bool get isPlacesApiKeyLoaded => goongPlacesApiKey.isNotEmpty;
  static bool get isMapboxAccessTokenLoaded => mapboxAccessToken.isNotEmpty;
}
