import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/place_model.dart';
import '../constants/api_config.dart';

class PlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';
  static const String _autocompleteEndpoint = '/autocomplete/json';
  static const String _detailsEndpoint = '/details/json';
  static const String _nearbySearchEndpoint = '/nearbysearch/json';
  static const String _textSearchEndpoint = '/textsearch/json';
  
  static String get _apiKey => ApiConfig.googlePlacesApiKey;

  /// Search for places using autocomplete
  static Future<List<PlacePrediction>> getPlaceAutocomplete(
    String input, {
    String? sessionToken,
    String? location,
    double? radius,
    String? language = 'vi',
    List<String>? types,
  }) async {
    // Check if API key is loaded
    if (!ApiConfig.isApiKeyLoaded) {
      print('Error: Google Places API key not found in environment variables');
      return [];
    }
    
    try {
      final Map<String, String> queryParams = {
        'input': input,
        'key': _apiKey,
        'language': language ?? ApiConfig.defaultLanguage,
        'components': 'country:${ApiConfig.defaultCountry}', // Restrict to Vietnam
      };

      if (sessionToken != null) {
        queryParams['sessiontoken'] = sessionToken;
      }

      if (location != null) {
        queryParams['location'] = location;
      }

      if (radius != null) {
        queryParams['radius'] = radius.toString();
      }

      if (types != null && types.isNotEmpty) {
        queryParams['types'] = types.join('|');
      }

      final uri = Uri.parse('$_baseUrl$_autocompleteEndpoint').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List<dynamic>;
          return predictions
              .map((prediction) => PlacePrediction.fromJson(prediction))
              .toList();
        } else {
          print('Places API Error: ${data['status']} - ${data['error_message']}');
          return [];
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting place autocomplete: $e');
      return [];
    }
  }

  /// Get detailed information about a place
  static Future<PlaceModel?> getPlaceDetails(
    String placeId, {
    String? sessionToken,
    String? language = 'vi',
    List<String>? fields,
  }) async {
    // Check if API key is loaded
    if (!ApiConfig.isApiKeyLoaded) {
      print('Error: Google Places API key not found in environment variables');
      return null;
    }
    
    try {
      final Map<String, String> queryParams = {
        'place_id': placeId,
        'key': _apiKey,
        'language': language ?? ApiConfig.defaultLanguage,
      };

      if (sessionToken != null) {
        queryParams['sessiontoken'] = sessionToken;
      }

      if (fields != null && fields.isNotEmpty) {
        queryParams['fields'] = fields.join(',');
      }

      final uri = Uri.parse('$_baseUrl$_detailsEndpoint').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final result = data['result'] as Map<String, dynamic>;
          return PlaceModel.fromJson(result);
        } else {
          print('Places API Error: ${data['status']} - ${data['error_message']}');
          return null;
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting place details: $e');
      return null;
    }
  }

  /// Search for nearby places
  static Future<List<PlaceModel>> getNearbyPlaces(
    double latitude,
    double longitude, {
    double radius = 5000,
    String? type,
    String? keyword,
    String? language = 'vi',
  }) async {
    // Check if API key is loaded
    if (!ApiConfig.isApiKeyLoaded) {
      print('Error: Google Places API key not found in environment variables');
      return [];
    }
    
    try {
      final Map<String, String> queryParams = {
        'location': '$latitude,$longitude',
        'radius': radius.toString(),
        'key': _apiKey,
        'language': language ?? ApiConfig.defaultLanguage,
      };

      if (type != null) {
        queryParams['type'] = type;
      }

      if (keyword != null) {
        queryParams['keyword'] = keyword;
      }

      final uri = Uri.parse('$_baseUrl$_nearbySearchEndpoint').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final results = data['results'] as List<dynamic>;
          return results
              .map((result) => PlaceModel.fromJson(result))
              .toList();
        } else {
          print('Places API Error: ${data['status']} - ${data['error_message']}');
          return [];
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting nearby places: $e');
      return [];
    }
  }

  /// Text search for places
  static Future<List<PlaceModel>> searchPlaces(
    String query, {
    double? latitude,
    double? longitude,
    double? radius,
    String? language = 'vi',
  }) async {
    // Check if API key is loaded
    if (!ApiConfig.isApiKeyLoaded) {
      print('Error: Google Places API key not found in environment variables');
      return [];
    }
    
    try {
      final Map<String, String> queryParams = {
        'query': query,
        'key': _apiKey,
        'language': language ?? ApiConfig.defaultLanguage,
      };

      if (latitude != null && longitude != null) {
        queryParams['location'] = '$latitude,$longitude';
      }

      if (radius != null) {
        queryParams['radius'] = radius.toString();
      }

      final uri = Uri.parse('$_baseUrl$_textSearchEndpoint').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final results = data['results'] as List<dynamic>;
          return results
              .map((result) => PlaceModel.fromJson(result))
              .toList();
        } else {
          print('Places API Error: ${data['status']} - ${data['error_message']}');
          return [];
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error searching places: $e');
      return [];
    }
  }

  /// Generate a session token for billing optimization
  static String generateSessionToken() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
