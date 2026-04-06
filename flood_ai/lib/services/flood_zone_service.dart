import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class FloodZoneService {
  static const String _baseUrl = String.fromEnvironment('API_BASE_URL');

  /// Fetch flood polygons ONLY for current visible map bounds
  static Future<List<Polygon>> fetchFloodPolygons({
    required LatLngBounds bounds,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/flood-zones'
      '?minLat=${bounds.southwest.latitude}'
      '&maxLat=${bounds.northeast.latitude}'
      '&minLng=${bounds.southwest.longitude}'
      '&maxLng=${bounds.northeast.longitude}',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load flood zones');
    }

    final Map<String, dynamic> geojson = json.decode(response.body);
    final List features = geojson['features'] ?? [];

    final List<Polygon> polygons = [];

    for (int i = 0; i < features.length; i++) {
      final feature = features[i];
      final geometry = feature['geometry'];

      if (geometry == null) continue;
      if (geometry['type'] != 'Polygon') continue;

      final List rings = geometry['coordinates'];
      if (rings.isEmpty) continue;

      final List coords = rings[0];
      if (coords.length < 3) continue;

      final List<LatLng> points = [];

      for (final c in coords) {
        if (c.length < 2) continue;

        final double lng = (c[0] as num).toDouble();
        final double lat = (c[1] as num).toDouble();

        points.add(LatLng(lat, lng));
      }

      // Ensure polygon is closed
      if (points.isNotEmpty &&
          (points.first.latitude != points.last.latitude ||
              points.first.longitude != points.last.longitude)) {
        points.add(points.first);
      }

      polygons.add(
        Polygon(
          polygonId: PolygonId('flood_$i'),
          points: points,
          fillColor: Colors.blue.withOpacity(0.45),
          strokeColor: Colors.blue,
          strokeWidth: 1,
        ),
      );
    }

    debugPrint('🌊 Flood polygons loaded: ${polygons.length}');
    return polygons;
  }
}
