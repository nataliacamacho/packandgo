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
    int limite = 10, required String query,
  }) async {
    final apiKey = dotenv.env['FOURSQUARE_API_KEY']?.trim();

    if (apiKey == null || apiKey.isEmpty) {
      print(" API KEY de Foursquare no encontrada");
      return [];
    }

    final url = Uri.parse(
      'https://api.foursquare.com/v3/places/search'
      '?ll=$lat,$lng'
      '&radius=20000' // 🔥 Subimos a 20 km para alcanzar zonas hoteleras
      '&limit=50'     // 🔥 Pedimos 50 lugares para garantizar que haya restaurantes y bares
      // 🔥 LA MAGIA: Le exigimos que nos mande las reseñas, calificaciones y precios
      '&fields=fsq_id,name,geocodes,location,categories,price,rating,popularity,tastes,tips'
    );

    try {
      final respuesta = await http.get(
        url,
        headers: {
          'Authorization': apiKey, 
          'Accept': 'application/json',
          'Accept-Language': 'es',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print("📡 STATUS CODE: ${respuesta.statusCode}");
      print("📦 BODY: ${respuesta.body}");
      print("🔑 API KEY: $apiKey");

      if (respuesta.statusCode == 200) {
        final data = json.decode(respuesta.body);
        return data['results']; // 👈 AQUÍ está lo importante
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