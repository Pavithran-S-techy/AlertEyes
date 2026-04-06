import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SavedLocationService {
  static const String baseUrl =
      String.fromEnvironment('API_BASE_URL');

  static Future<List<dynamic>> fetchLocations(int userId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/saved-locations/$userId'),
    );
    return json.decode(res.body);
  }

  static Future<void> addLocation(
    int userId,
    String name,
    LatLng position,
  ) async {
    await http.post(
      Uri.parse('$baseUrl/saved-locations'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': userId,
        'name': name,
        'latitude': position.latitude,
        'longitude': position.longitude,
      }),
    );
  }
}
