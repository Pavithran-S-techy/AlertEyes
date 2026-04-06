import 'dart:convert';
import 'package:http/http.dart' as http;

class GridPredictionService {
  static const String _baseUrl =
      String.fromEnvironment('API_BASE_URL');

  static Future<List<dynamic>> fetchGridPredictions() async {
    final uri =
        Uri.parse('$_baseUrl/flood-prediction/grid-predictions');

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load grid predictions');
    }

    return json.decode(response.body);
  }
}
