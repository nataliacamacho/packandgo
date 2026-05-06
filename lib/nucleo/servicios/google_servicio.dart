import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GoogleServicio {
  final String apiKey = dotenv.env['GOOGLE_API_KEY']!;

  // 🔥 GEOCODING
  Future<String?> obtenerCoordenadas(String lugar) async {
    final url =
        "https://maps.googleapis.com/maps/api/geocode/json"
        "?address=${Uri.encodeComponent(lugar)}"
        "&key=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data["results"] != null && data["results"].isNotEmpty) {
          final location = data["results"][0]["geometry"]["location"];

          final lat = location["lat"];
          final lng = location["lng"];

          return "$lat,$lng"; // 🔥 formato para Distance Matrix
        }
      }
    } catch (e) {
      print("❌ Error Geocoding: $e");
    }

    return null;
  }

  // 🔥 DISTANCIA REAL (CON COORDENADAS)
  Future<Map<String, dynamic>?> obtenerRuta({
    required String origen,
    required String destino,
  }) async {
    try {
      final origenCoords = await obtenerCoordenadas(origen);
      final destinoCoords = await obtenerCoordenadas(destino);

      print("📍 ORIGEN COORDS: $origenCoords");
      print("📍 DESTINO COORDS: $destinoCoords");

      if (origenCoords == null || destinoCoords == null) {
        return null;
      }

      final url =
          "https://maps.googleapis.com/maps/api/distancematrix/json"
          "?origins=$origenCoords"
          "&destinations=$destinoCoords"
          "&key=$apiKey"
          "&language=es";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data["rows"].isEmpty || data["rows"][0]["elements"].isEmpty) {
          return null;
        }

        final element = data["rows"][0]["elements"][0];

        if (element["status"] != "OK") return null;

        return {
          "duracion": element["duration"]["text"],
          "distancia": element["distance"]["text"],
        };
      }
    } catch (e) {
      print("❌ Error Google: $e");
    }

    return null;
  }

  Future<Map<String, dynamic>?> buscarTerminalAutobus(String ciudad) async {
    final url =
        "https://maps.googleapis.com/maps/api/place/textsearch/json"
        "?query=${Uri.encodeComponent("central de autobuses en $ciudad")}"
        "&key=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data["results"] != null && data["results"].isNotEmpty) {
          final lugar = data["results"][0];

          return {
            "nombre": lugar["name"],
            "lat": lugar["geometry"]["location"]["lat"],
            "lng": lugar["geometry"]["location"]["lng"],
          };
        }
      }
    } catch (e) {
      print("❌ Error buscarTerminal: $e");
    }

    return null;
  }

  Future<Map<String, dynamic>?> buscarAeropuerto(String ciudad) async {
    final url =
        "https://maps.googleapis.com/maps/api/place/textsearch/json"
        "?query=${Uri.encodeComponent("aeropuerto en $ciudad")}"
        "&key=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data["results"] != null && data["results"].isNotEmpty) {
          final lugar = data["results"][0];

          return {
            "nombre": lugar["name"],
            "lat": lugar["geometry"]["location"]["lat"],
            "lng": lugar["geometry"]["location"]["lng"],
          };
        }
      }
    } catch (e) {
      print("❌ Error buscarAeropuerto: $e");
    }

    return null;
  }
}
