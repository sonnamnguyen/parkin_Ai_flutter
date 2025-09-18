import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/place_model.dart';
import '../constants/api_config.dart';

class GoongPlacesService {
  static const String _baseUrl = 'https://rsapi.goong.io/Place';
  
  static String get _apiKey => ApiConfig.goongPlacesApiKey;

  /// Get place autocomplete suggestions from Goong Places API
  static Future<List<PlacePrediction>> getPlaceAutocomplete(
    String input, {
    String? location,
    double? radius,
    String? language = 'vi',
  }) async {
    if (!ApiConfig.isPlacesApiKeyLoaded) {
      print('Error: Goong Places API key not found in environment variables');
      return [];
    }

    try {
      final Map<String, String> queryParams = {
        'api_key': _apiKey,
        'input': input,
        'limit': '10',
      };

      if (location != null) {
        queryParams['location'] = location;
      }
      if (radius != null) {
        queryParams['radius'] = radius.toString();
      }
      if (language != null) {
        queryParams['language'] = language;
      }

      final uri = Uri.parse('$_baseUrl/AutoComplete').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List<dynamic>;
          return predictions.map((prediction) => PlacePrediction.fromGoongJson(prediction)).toList();
        } else {
          print('Goong Places API Error: ${data['status']} - ${data['error_message']}');
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

  /// Get place details from Goong Places API
  static Future<PlaceModel?> getPlaceDetails(
    String placeId, {
    String? language = 'vi',
    List<String>? fields,
  }) async {
    if (!ApiConfig.isPlacesApiKeyLoaded) {
      print('Error: Goong Places API key not found in environment variables');
      return null;
    }

    try {
      final Map<String, String> queryParams = {
        'api_key': _apiKey,
        'place_id': placeId,
      };

      if (language != null) {
        queryParams['language'] = language;
      }

      final uri = Uri.parse('$_baseUrl/Detail').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return PlaceModel.fromGoongJson(data['result']);
        } else {
          print('Goong Places API Error: ${data['status']} - ${data['error_message']}');
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

  /// Search places using Goong Places API
  static Future<List<PlaceModel>> searchPlaces(
    String query, {
    String? location,
    double? radius,
    String? language = 'vi',
  }) async {
    if (!ApiConfig.isPlacesApiKeyLoaded) {
      print('Error: Goong Places API key not found in environment variables');
      return [];
    }

    try {
      final Map<String, String> queryParams = {
        'api_key': _apiKey,
        'input': query,
        'limit': '20',
      };

      if (location != null) {
        queryParams['location'] = location;
      }
      if (radius != null) {
        queryParams['radius'] = radius.toString();
      }
      if (language != null) {
        queryParams['language'] = language;
      }

      final uri = Uri.parse('$_baseUrl/TextSearch').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final results = data['results'] as List<dynamic>;
          return results.map((result) => PlaceModel.fromGoongJson(result)).toList();
        } else {
          print('Goong Places API Error: ${data['status']} - ${data['error_message']}');
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

  /// Generate a session token (for compatibility with existing code)
  static String generateSessionToken() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
