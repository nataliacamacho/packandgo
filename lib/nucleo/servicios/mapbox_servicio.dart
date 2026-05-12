import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class MapboxServicio {
  final token = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';

  Future<Map<String, dynamic>?> obtenerRuta({
    required double origenLat,
    required double origenLng,
    required double destinoLat,
    required double destinoLng,
  }) async {
    final url =
        'https://api.mapbox.com/directions/v5/mapbox/driving/'
        '$origenLng,$origenLat;$destinoLng,$destinoLat'
        '?geometries=geojson&access_token=$token';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final route = data['routes'][0];

        return {
          'distancia': route['distance'],
          'duracion': route['duration'],
          'coordenadas': route['geometry']['coordinates'],
        };
      }
    }

    return null;
  }
}