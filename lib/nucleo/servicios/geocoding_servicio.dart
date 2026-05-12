import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeocodingServicio {
  final token = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
  Future<Map<String, double>?> obtenerCoordenadas(String lugar) async {
    final lugarCodificado = Uri.encodeComponent("$lugar, México");

    final url =
        'https://api.mapbox.com/geocoding/v5/mapbox.places/$lugarCodificado.json'
        '?access_token=$token&limit=1';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['features'] != null && data['features'].isNotEmpty) {
        final coords = data['features'][0]['center'];

        return {'lat': coords[1].toDouble(), 'lng': coords[0].toDouble()};
      }
    }

    return null;
  }
}
