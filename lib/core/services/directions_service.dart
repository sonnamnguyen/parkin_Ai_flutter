import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:http/http.dart' as http;

import '../constants/api_config.dart';

class DirectionsService {
  const DirectionsService();

  Future<List<LatLng>> getDrivingRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final token = ApiConfig.mapboxAccessToken;
    if (token.isEmpty) {
      throw Exception('Missing Mapbox access token');
    }

    final url = Uri.parse(
      'https://api.mapbox.com/directions/v5/mapbox/driving-traffic'
      '/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}'
      '?alternatives=false&geometries=geojson&overview=full&steps=false&access_token=$token',
    );

    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw Exception('Directions request failed: ${res.statusCode} ${res.body}');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final routes = (json['routes'] as List?) ?? [];
    if (routes.isEmpty) {
      throw Exception('No route found');
    }
    final geometry = routes.first['geometry'] as Map<String, dynamic>;
    final coords = (geometry['coordinates'] as List).cast<List>();
    return coords
        .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
        .toList(growable: false);
  }
}


