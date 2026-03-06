import 'dart:convert'; // Nos sirve para traducir el texto de internet a un formato que Flutter entienda (JSON)
import 'package:http/http.dart' as http; // El "teléfono" que acabamos de instalar
import 'package:flutter_dotenv/flutter_dotenv.dart'; // La herramienta para abrir tu caja fuerte (.env)

class FoursquareServicio {
  
  // Función principal: pide coordenadas (latitud y longitud) y busca lugares cerca
  static Future<void> buscarLugaresCercanos(double lat, double lng) async {
    
    // 1. Abrimos la caja fuerte para sacar tu API Key
    final apiKey = dotenv.env['FOURSQUARE_API_KEY'];

    if (apiKey == null) {
      print("❌ Error: No se encontró la llave en el archivo .env");
      return;
    }

    // 2. Preparamos la dirección web a la que vamos a llamar.
    // ll = coordenadas, radius = buscar a 5000 metros a la redonda, limit = traer solo 5 lugares por ahora.
    final url = Uri.parse('https://api.foursquare.com/v3/places/search?ll=$lat,$lng&radius=5000&limit=5');

    try {
      // 3. Hacemos la llamada HTTP (Tipo GET, porque solo queremos OBTENER datos)
      final respuesta = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': apiKey, // ¡Aquí presentamos tu llave secreta como credencial!
        },
      );

      // 4. Revisamos si Foursquare nos dejó entrar. (El código 200 significa "Todo OK" en la web)
      if (respuesta.statusCode == 200) {
        // Traducimos la respuesta a un mapa (diccionario) de Dart
        final datos = json.decode(respuesta.body); 
        
        print("✅ ¡Conexión exitosa a Foursquare!");
        
        // Vamos a imprimir el nombre del primer lugar turístico que encontró para comprobar que sirve
        final primerLugar = datos['results'][0]['name'];
        print("🌍 Primer lugar encontrado: $primerLugar");
        
      } else {
        print("❌ Error en la petición. Foursquare dijo: ${respuesta.statusCode}");
      }
      
    } catch (e) {
      print("❌ Error de internet: $e");
    }
  }
}