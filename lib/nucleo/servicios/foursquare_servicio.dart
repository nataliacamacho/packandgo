import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FoursquareServicio {
  
  static Future<List<dynamic>> buscarLugaresCercanos(double lat, double lng) async {
    final apiKey = dotenv.env['FOURSQUARE_API_KEY']?.trim();

    if (apiKey == null || apiKey.isEmpty) {
      return _obtenerDatosDeRespaldo();
    }

    // URL sin pedir fotos para evitar cobros
    final url = Uri.parse('https://places-api.foursquare.com/places/search?ll=$lat,$lng&radius=5000&limit=5');

    try {
      final respuesta = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'X-places-api-version': '2025-02-05', 
        },
      );

      if (respuesta.statusCode == 200) {
        final datos = json.decode(respuesta.body); 
        if (datos['results'] != null && datos['results'].isNotEmpty) {
           return datos['results']; 
        }
      } else {
        print("⚠️ Foursquare marcó error ${respuesta.statusCode}. Entrando al Plan B...");
        return _obtenerDatosDeRespaldo(); // Si marca 429, usamos los datos falsos
      }
      
    } catch (e) {
      print("⚠️ Error de conexión. Entrando al Plan B...");
      return _obtenerDatosDeRespaldo();
    }
    
    return _obtenerDatosDeRespaldo(); 
  }

  // --- NUESTROS DATOS DE RESPALDO (MOCK DATA) ---
  // Tienen la estructura exacta que tu nueva pantalla necesita
  static List<dynamic> _obtenerDatosDeRespaldo() {
    return [
      {
        "name": "El Parián de Tlaquepaque",
        "categories": [{"name": "Atracción Turística"}],
        "location": {"formatted_address": "Calle Juárez, Centro, Tlaquepaque"}
      },
      {
        "name": "Teatro Experimental de Jalisco",
        "categories": [{"name": "Teatro cultural"}],
        "location": {"formatted_address": "Calz. Independencia Sur, Guadalajara"}
      },
      {
        "name": "Carajillo",
        "categories": [{"name": "Restaurante / Bar"}],
        "location": {"formatted_address": "Av. Patria, Zapopan"}
      },
      {
        "name": "The Happy Fish",
        "categories": [{"name": "Mariscos"}],
        "location": {"formatted_address": "Av. Chapultepec, Guadalajara"}
      }
    ];
  }
}