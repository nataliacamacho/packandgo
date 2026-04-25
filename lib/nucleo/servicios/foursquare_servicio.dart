import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FoursquareServicio {
  // Categorías útiles para viajes (Foursquare Category IDs)
  static const Map<String, String> categorias = {
    'restaurantes': '13065',
    'hoteles': '19014',
    'atracciones': '16000',
    'museos': '10027',
    'parques': '16032',
    'cafes': '13032',
  };

  static Future<List<dynamic>> buscarLugaresCercanos(
    double lat,
    double lng, {
    String? categoria,   // 👈 parámetro opcional
    int radio = 3000,
    int limite = 10,
  }) async {
    final apiKey = dotenv.env['FOURSQUARE_API_KEY']?.trim();

    if (apiKey == null || apiKey.isEmpty) {
      print("❌ API KEY de Foursquare no encontrada");
      return [];
    }

    if (apiKey == null || apiKey.isEmpty) {
      print("❌ API KEY de Foursquare no encontrada");
      return [];
    }

    // Construimos los query params dinámicamente
    final queryParams = {
      'll': '$lat,$lng',
      'radius': '$radio',
      'limit': '$limite',
      'fields': 'name,location,categories,rating,photos,website,hours', // 👈 solo pedimos lo que necesitamos
      if (categoria != null && categorias.containsKey(categoria))
        'categories': categorias[categoria]!,
    };

    final url = Uri.https(
      'api.foursquare.com',
      '/v3/places/search',
      queryParams,
    );

    try {
      final respuesta = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': apiKey,
          // ✅ Quitamos Content-Type, no aplica en GET
        },
      ).timeout(const Duration(seconds: 10));

      print("📡 STATUS CODE: ${respuesta.statusCode}");

      if (respuesta.statusCode == 200) {
        final data = json.decode(respuesta.body);
        // ✅ Null safety: si no hay results, regresa lista vacía
        return data['results'] ?? [];

      } else if (respuesta.statusCode == 401) {
        print("❌ API KEY inválida o expirada");
        return [];

      } else if (respuesta.statusCode == 429) {
        print("⚠️ Límite de requests alcanzado, intenta más tarde");
        return [];

      } else {
        print("❌ Error ${respuesta.statusCode}: ${respuesta.body}");
        return [];
      }

    } on TimeoutException {
      print("❌ Timeout: la API tardó demasiado");
      return [];
    } catch (e) {
      print("❌ ERROR inesperado: $e");
      return [];
    }
  }
}