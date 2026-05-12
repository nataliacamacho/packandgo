import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

final Map<String, dynamic> _cacheGoogle = {};

class GoogleServicio {
  final String apiKey = dotenv.env['GOOGLE_API_KEY']!;

  // ==============================
  // 🔥 GEOCODING
  // ==============================
  Future<Map<String, double>?> obtenerCoordenadas(String lugar) async {
    final cacheKey = "geo_$lugar";

    // 🔥 CACHE
    if (_cacheGoogle.containsKey(cacheKey)) {
      return _cacheGoogle[cacheKey] as Map<String, double>;
    }

    final url =
        "https://maps.googleapis.com/maps/api/geocode/json"
        "?address=${Uri.encodeComponent("$lugar, México")}"
        "&components=country:MX"
        "&region=mx"
        "&key=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data["results"] != null && data["results"].isNotEmpty) {
          final location = data["results"][0]["geometry"]["location"];

          final resultado = <String, double>{
            "lat": location["lat"].toDouble(),
            "lng": location["lng"].toDouble(),
          };

          // 🔥 GUARDAR CACHE
          _cacheGoogle[cacheKey] = resultado;

          return resultado;
        }
      }
    } catch (e) {
      print("❌ Error Geocoding: $e");
    }

    return null;
  }

  // ==============================
  // 🔥 DISTANCIA REAL
  // ==============================
  Future<Map<String, dynamic>?> obtenerRuta({
    required String origen,
    required String destino,
  }) async {
    try {
      Map<String, double>? origenCoords;
      Map<String, double>? destinoCoords;

      // 🔥 SI YA SON COORDENADAS
      if (origen.contains(",")) {
        final parts = origen.split(",");

        origenCoords = {
          "lat": double.parse(parts[0]),
          "lng": double.parse(parts[1]),
        };
      } else {
        origenCoords = await obtenerCoordenadas(origen);
      }

      // 🔥 SI YA SON COORDENADAS
      if (destino.contains(",")) {
        final parts = destino.split(",");

        destinoCoords = {
          "lat": double.parse(parts[0]),
          "lng": double.parse(parts[1]),
        };
      } else {
        destinoCoords = await obtenerCoordenadas(destino);
      }

      // 🔥 VALIDAR NULL
      if (origenCoords == null || destinoCoords == null) {
        return null;
      }

      final url =
          "https://maps.googleapis.com/maps/api/distancematrix/json"
          "?origins=${origenCoords['lat']},${origenCoords['lng']}"
          "&destinations=${destinoCoords['lat']},${destinoCoords['lng']}"
          "&key=$apiKey"
          "&region=mx"
          "&language=es";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data["rows"].isEmpty || data["rows"][0]["elements"].isEmpty) {
          return null;
        }

        final element = data["rows"][0]["elements"][0];

        if (element["status"] != "OK") {
          return null;
        }

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

  // ==============================
  // 🔥 TERMINAL AUTOBUS
  // ==============================
  Future<Map<String, dynamic>?> buscarTerminalAutobus(String ciudad) async {
    final cacheKey = "terminal_$ciudad";

    // 🔥 CACHE
    if (_cacheGoogle.containsKey(cacheKey)) {
      return _cacheGoogle[cacheKey] as Map<String, dynamic>;
    }

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

          final resultado = {
            "nombre": lugar["name"],
            "lat": lugar["geometry"]["location"]["lat"].toDouble(),
            "lng": lugar["geometry"]["location"]["lng"].toDouble(),
          };

          // 🔥 GUARDAR CACHE
          _cacheGoogle[cacheKey] = resultado;

          return resultado;
        }
      }
    } catch (e) {
      print("❌ Error buscarTerminal: $e");
    }

    return null;
  }

  // ==============================
  // 🔥 AEROPUERTO
  // ==============================
  Future<Map<String, dynamic>?> buscarAeropuerto(String ciudad) async {
    final cacheKey = "aeropuerto_$ciudad";

    // 🔥 CACHE
    if (_cacheGoogle.containsKey(cacheKey)) {
      return _cacheGoogle[cacheKey] as Map<String, dynamic>;
    }

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

          final resultado = {
            "nombre": lugar["name"],
            "lat": lugar["geometry"]["location"]["lat"].toDouble(),
            "lng": lugar["geometry"]["location"]["lng"].toDouble(),
          };

          // 🔥 GUARDAR CACHE
          _cacheGoogle[cacheKey] = resultado;

          return resultado;
        }
      }
    } catch (e) {
      print("❌ Error buscarAeropuerto: $e");
    }

    return null;
  }
}
