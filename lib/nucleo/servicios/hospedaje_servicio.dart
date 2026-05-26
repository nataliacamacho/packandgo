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
        .map((e) => Hospedaje.fromGoogle(e, apiKey))
        .where((h) => _filtrar(h.ubicacion, destino))
        .toList();

    list.sort((a, b) => b.rating.compareTo(a.rating));

    return list.take(10).toList();
  }

  bool _filtrar(String ubicacion, String destino) {
    final u = ubicacion.toLowerCase();
    final d = destino.toLowerCase();

    return u.contains(d.split(' ').first) ||
        u.contains('méxico') ||
        u.contains('quintana roo') ||
        u.contains('jalisco') ||
        u.contains('baja california');
  }
}