import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Hospedaje {
  final String nombre;
  final String direccion;
  final String imagen;
  final double rating;
  final String linkMaps;
  final double lat;
  final double lng;

  Hospedaje({
    required this.nombre,
    required this.direccion,
    required this.imagen,
    required this.rating,
    required this.linkMaps,
    required this.lat,
    required this.lng,
  });

  factory Hospedaje.fromGoogle(Map<String, dynamic> json) {
    final lat = json['geometry']['location']['lat'] ?? 0.0;
    final lng = json['geometry']['location']['lng'] ?? 0.0;

    final photos = json['photos'] as List?;
    String imageUrl = '';

    if (photos != null && photos.isNotEmpty) {
      final photoRef = photos[0]['photo_reference'];
      imageUrl =
          "https://maps.googleapis.com/maps/api/place/photo"
          "?maxwidth=400"
          "&photo_reference=$photoRef"
          "&key=${dotenv.env['GOOGLE_PLACES_API_KEY']}";
    }

    return Hospedaje(
      nombre: json['name'] ?? 'Sin nombre',
      direccion: json['vicinity'] ?? 'Sin dirección',
      imagen: imageUrl,
      rating: (json['rating'] ?? 0).toDouble(),
      lat: lat,
      lng: lng,
      linkMaps: "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
    );
  }
}

class HospedajeServicio {
  Future<List<Hospedaje>> obtenerHospedajes({
    required double lat,
    required double lng,
    int radius = 5000,
  }) async {
    final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'];

    if (apiKey == null) {
      print("❌ API KEY no encontrada");
      return [];
    }

    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
      "?location=$lat,$lng"
      "&radius=$radius"
      "&type=lodging"
      "&key=$apiKey",
    );

    try {
      final response = await http.get(url);

      if (response.statusCode != 200) {
        print("❌ Error API Google Places");
        return [];
      }

      final data = json.decode(response.body);

      final results = data['results'] as List;

      List<Hospedaje> hospedajes = results
          .map((e) => Hospedaje.fromGoogle(e))
          .where((h) {
            // filtro básico de validez
            return h.nombre.isNotEmpty &&
                h.lat != 0.0 &&
                h.lng != 0.0;
          })
          .toList();

      // ordenar por rating
      hospedajes.sort((a, b) => b.rating.compareTo(a.rating));

      return hospedajes.take(10).toList();
    } catch (e) {
      print("❌ Error: $e");
      return [];
    }
  }
}
