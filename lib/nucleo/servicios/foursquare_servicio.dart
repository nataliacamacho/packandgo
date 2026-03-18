import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FoursquareServicio {
  
  static Future<void> buscarLugaresCercanos(double lat, double lng) async {
    
    final apiKey = dotenv.env['FOURSQUARE_API_KEY']?.trim();

    if (apiKey == null || apiKey.isEmpty) {
      print("❌ Error: La llave secreta está vacía.");
      return;
    }

    final url = Uri.parse('https://places-api.foursquare.com/places/search?ll=$lat,$lng&radius=5000&limit=5');

    try {
      final respuesta = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $apiKey', // Aquí entrará tu llave 4AZ... triunfante
          'X-places-api-version': '2025-02-05', 
        },
      );

      if (respuesta.statusCode == 200) {
        final datos = json.decode(respuesta.body); 
        print("✅ ¡POR FIN! Conexión exitosa a la NUEVA API de Foursquare 🥳");
        
        if (datos['results'] != null && datos['results'].isNotEmpty) {
           final primerLugar = datos['results'][0]['name'];
           print("🌍 Primer lugar encontrado: $primerLugar");
        } else {
           print("🌍 Foursquare contestó, pero no hay lugares cerca.");
        }

      } else {
        print("❌ Error en la petición. Foursquare dijo: ${respuesta.statusCode}");
        print("Detalles del error: ${respuesta.body}"); 
      }
      
    } catch (e) {
      print("❌ Error de internet: $e");
    }
  }
}