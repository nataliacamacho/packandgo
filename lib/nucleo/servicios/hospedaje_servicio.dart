import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:proyecto/modulos/viajes/apartados/hospedaje/modelo_hospedaje.dart';

class HospedajeServicio {
  final String _base = "https://maps.googleapis.com/maps/api";

  Future<Map<String, dynamic>?> _geocodificar(String destino) async {
    final apiKey = dotenv.env['GOOGLE_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return null;

    final url = Uri.parse(
      "$_base/geocode/json?address=${Uri.encodeComponent('$destino, México')}&region=mx&key=$apiKey",
    );

    final res = await http.get(url);
    final data = json.decode(res.body);

    if (data['results'] == null || data['results'].isEmpty) return null;

    final result = data['results'][0];

    return {
      "lat": result['geometry']['location']['lat'],
      "lng": result['geometry']['location']['lng'],
      "address": result['formatted_address'],
    };
  }

  Future<List<Hospedaje>> obtenerHospedajes({
    required String destino,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    int radius = 12000,
  }) async {
    final apiKey = dotenv.env['GOOGLE_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return [];

    final geo = await _geocodificar(destino);
    if (geo == null) return [];

    final lat = geo['lat'];
    final lng = geo['lng'];

    final url = Uri.parse(
      "$_base/place/textsearch/json"
      "?query=${Uri.encodeComponent('hoteles en $destino México')}"
      "&location=$lat,$lng"
      "&radius=$radius"
      "&region=mx"
      "&language=es"
      "&key=$apiKey",
    );

    final res = await http.get(url);
    final data = json.decode(res.body);

    if (data['results'] == null) return [];

    final results = data['results'] as List;

    final list = results
        .where((e) => _filtrar(e))
        .map((e) => Hospedaje.fromGoogle(e, apiKey))
        .toList();

    list.sort((a, b) => b.rating.compareTo(a.rating));

    final hoy = DateTime.now();
    final listConDisponibilidad = list.map((h) {
      final disponible =
          fechaInicio.isAfter(hoy) && fechaFin.isAfter(fechaInicio);
      return Hospedaje(
        nombre: h.nombre,
        imagen: h.imagen,
        precio: h.precio,
        ubicacion: h.ubicacion,
        disponible: disponible,
        link: h.link,
        lat: h.lat,
        lng: h.lng,
        rating: h.rating,
        placeId: h.placeId,
      );
    }).toList();

    return listConDisponibilidad.take(10).toList();
  }

  bool _filtrar(Map<String, dynamic> json) {
    final vicinity = (json['vicinity'] ?? '').toString().toLowerCase();
    final name = (json['name'] ?? '').toString().toLowerCase();
    final formatted = (json['formatted_address'] ?? '')
        .toString()
        .toLowerCase();

    final texto = '$vicinity $name $formatted';

    // Excluir resultados claramente fuera de México
    if (texto.contains('united states') ||
        texto.contains('usa') ||
        texto.contains('españa') ||
        texto.contains('spain')) {
      return false;
    }

    return true;
  }
}
