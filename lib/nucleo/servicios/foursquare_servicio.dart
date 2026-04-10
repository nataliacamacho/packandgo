import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FoursquareServicio {
  static Future<List<dynamic>> buscarLugaresCercanos(
    double lat,
    double lng,
  ) async {
    final apiKey = dotenv.env['FOURSQUARE_API_KEY']?.trim();

    if (apiKey == null || apiKey.isEmpty) {
      print("❌ API KEY de Foursquare no encontrada");
      return [];
    }

    final url = Uri.parse(
      'https://api.foursquare.com/v3/places/search'
      '?ll=$lat,$lng'
      '&radius=3000'
      '&limit=20',
    );

    try {
      final respuesta = await http.get(
        url,
        headers: {'Accept': 'application/json', 'Authorization': apiKey},
      );

      print("📡 STATUS CODE: ${respuesta.statusCode}");
      print("📦 BODY: ${respuesta.body}");
    } catch (e) {
      print("❌ ERROR: $e");
    }
      return [];
  }
}
