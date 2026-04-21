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
      print(" API KEY de Foursquare no encontrada");
      return [];
    }

    final url = Uri.parse(
      'https://api.foursquare.com/v3/places/search'
      '?ll=$lat,$lng'
      '&radius=3000'
      '&limit=10',
    );

    try {
      final respuesta = await http.get(
        url,
        headers: {
          'Authorization': apiKey, 
          'Accept': 'application/json',
          'X-Places-Api-Version': '2023-10-10', 
        },
      )
      .timeout(const Duration(seconds: 10));

      print(" STATUS CODE: ${respuesta.statusCode}");
      print(" BODY: ${respuesta.body}");
      print(" API KEY: $apiKey");

      if (respuesta.statusCode == 200) {
        final data = json.decode(respuesta.body);
        return data['results']; //lo importante
      } else {
        print("❌ Error en la API");
        return [];
      }
    } catch (e) {
      print("❌ ERROR: $e");
      return [];
    }
  }
}
