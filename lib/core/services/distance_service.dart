import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_config.dart';

class DistanceMatrixService {
  static const String _baseUrl = 'https://rsapi.goong.io/DistanceMatrix';
  static String get _apiKey => ApiConfig.goongMapsApiKey;

  static Future<DistanceMatrixResult?> getDurations({
    required String origins, // "lat,lng|lat,lng"
    required String destinations, // "lat,lng|lat,lng"
    String mode = 'driving', // driving, bicycling, walking, motorcycle
    String language = 'vi',
  }) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'origins': origins,
      'destinations': destinations,
      'vehicle': mode,
      'language': language,
      'api_key': _apiKey,
    });

    try {
      print('DistanceMatrix API URL: $uri');
      final resp = await http.get(uri);
      print('DistanceMatrix API response status: ${resp.statusCode}');
      print('DistanceMatrix API response body: ${resp.body}');
      
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        return DistanceMatrixResult.fromJson(data);
      }
      return null;
    } catch (e) {
      print('DistanceMatrix API error: $e');
      return null;
    }
  }
}

class DistanceMatrixResult {
  final List<List<DistanceElement>> rows;
  DistanceMatrixResult(this.rows);
  factory DistanceMatrixResult.fromJson(Map<String, dynamic> json) {
    final rows = <List<DistanceElement>>[];
    for (final row in (json['rows'] as List)) {
      final elements = <DistanceElement>[];
      for (final el in (row['elements'] as List)) {
        elements.add(DistanceElement.fromJson(el));
      }
      rows.add(elements);
    }
    return DistanceMatrixResult(rows);
  }
}

class DistanceElement {
  final String status;
  final TextValue duration;
  final TextValue distance;
  DistanceElement({required this.status, required this.duration, required this.distance});
  factory DistanceElement.fromJson(Map<String, dynamic> json) {
    return DistanceElement(
      status: json['status'] ?? 'UNKNOWN',
      duration: TextValue.fromJson(json['duration'] ?? {}),
      distance: TextValue.fromJson(json['distance'] ?? {}),
    );
  }
}

class TextValue {
  final String text;
  final int value;
  TextValue({required this.text, required this.value});
  factory TextValue.fromJson(Map<String, dynamic> json) {
    return TextValue(
      text: json['text'] ?? '',
      value: (json['value'] ?? 0) as int,
    );
  }
}
