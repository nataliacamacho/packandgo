import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class MapaServicio {
  final token = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';

  /// Obtener ubicación actual del usuario
  Future<Position> obtenerUbicacionActual() async {
    bool servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) {
      throw Exception("Servicio de ubicación deshabilitado");
    }

    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }

    return await Geolocator.getCurrentPosition();
  }

  /// Obtener ruta en carro
  Future<List<dynamic>> obtenerRuta(
    double origenLat,
    double origenLng,
    double destinoLat,
    double destinoLng,
  ) async {
    final url =
        "https://api.mapbox.com/directions/v5/mapbox/driving/"
        "$origenLng,$origenLat;"
        "$destinoLng,$destinoLat"
        "?geometries=geojson&access_token=$token";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data["routes"][0]["geometry"]["coordinates"];
    } else {
      throw Exception("Error al obtener ruta");
    }
  }
}
