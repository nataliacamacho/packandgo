import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:proyecto/modulos/viajes/apartados/hospedaje/modelo_hospedaje.dart';

class HospedajeServicio {
  Future<List<Hospedaje>> obtenerHospedajes({
    required double lat,
    required double lng,
    int radius = 5000,
  }) async {
    final apiKey = dotenv.env['GOOGLE_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      print("❌ API KEY no encontrada");
      return [];
    }

    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
      "?location=$lat,$lng"
      "&radius=$radius"
      "&type=lodging"
      "&language=es"
      "&key=$apiKey",
    );

    try {
      final response = await http.get(url);

      if (response.statusCode != 200) {
        print("❌ Error API Google Places");
        return [];
      }

      final data = json.decode(response.body);

      print("🏨 RESPUESTA GOOGLE:");
      print(data);

      if (data['results'] == null) {
        return [];
      }

      final results = data['results'] as List;

      List<Hospedaje> hospedajes = results
          .map((e) => Hospedaje.fromGoogle(e, apiKey))
          .where((h) {
            return h.nombre.isNotEmpty &&
                h.lat != 0.0 &&
                h.lng != 0.0;
          })
          .toList();

      hospedajes.sort((a, b) => b.rating.compareTo(a.rating));

      return hospedajes.take(10).toList();
    } catch (e) {
      print("❌ Error obtenerHospedajes: $e");
      return [];
    }
  }
}