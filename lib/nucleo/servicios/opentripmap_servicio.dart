import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenTripMapServicio {
  
  static Future<List<dynamic>> buscarLugaresCulturales(double lat, double lng, {int radius = 1000}) async {
    
    final apiKey = dotenv.env['OPENTRIPMAP_API_KEY']?.trim();

    if (apiKey == null || apiKey.isEmpty) {
      print("❌ Error: La llave de OpenTripMap está vacía.");
      return []; 
    }

    // Pedimos lugares turísticos (interesting_places) en un radio de 5km
    // Ojo: OpenTripMap usa 'lon' en lugar de 'lng'
    final url = Uri.parse('https://api.opentripmap.com/0.1/en/places/radius?radius=5000&lon=$lng&lat=$lat&kinds=interesting_places&apikey=$apiKey');

    try {
      final respuesta = await http.get(url);

      if (respuesta.statusCode == 200) {
        final datos = json.decode(respuesta.body); 
        print("✅ ¡POR FIN! Conexión exitosa a OpenTripMap 🌍");
        
        // OpenTripMap agrupa sus resultados dentro de 'features'
        if (datos['features'] != null && datos['features'].isNotEmpty) {
           return datos['features']; 
        }

      } else {
        print("❌ Error en OpenTripMap. Código: ${respuesta.statusCode}");
      }
      
    } catch (e) {
      print("❌ Error de internet con OpenTripMap: $e");
    }
    
    return []; 
  }
}