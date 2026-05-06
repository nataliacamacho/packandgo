import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenTripMapServicio {
  static String get _apiKey => dotenv.env['OPENTRIPMAP_API_KEY'] ?? '';

  // Mapeo de tipos de filtro → kinds de OpenTripMap
  static const Map<String, String> _tipoAKinds = {
    'restaurante': 'foods',
    'cafeteria': 'foods',
    'bar': 'foods',
    'parque': 'natural',
    'museo': 'museums',
    'playa': 'beaches',
    'monumento': 'historic',
    'zona_arqueologica': 'archaeology',
    'mirador': 'view_points',
    'centro_comercial': 'shops',
    'actividades_extremas': 'sport',
  };

  /// Busca lugares culturales/turísticos cerca de [lat],[lng].
  static Future<List<Map<String, dynamic>>?> buscarLugaresCulturales(
    double lat,
    double lng, {
    String query = '',
    String? tipo,
    int radio = 15000,
  }) async {
    try {
      final kinds = tipo != null && _tipoAKinds.containsKey(tipo)
          ? _tipoAKinds[tipo]!
          : 'interesting_places';

      // Si hay texto, usar automplete primero para conseguir xid
      if (query.isNotEmpty) {
        return await _buscarPorTexto(query, lat, lng, kinds);
      }

      return await _buscarPorRadio(lat, lng, kinds, radio);
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> _buscarPorRadio(
    double lat,
    double lng,
    String kinds,
    int radio,
  ) async {
    final url =
        'https://api.opentripmap.com/0.1/es/places/radius'
        '?radius=$radio'
        '&lon=$lng'
        '&lat=$lat'
        '&kinds=$kinds'
        '&rate=2'
        '&limit=20'
        '&format=json'
        '&apikey=$_apiKey';

    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) return [];

    final data = jsonDecode(res.body);
    if (data is! List) return [];

    return data
        .whereType<Map>()
        .map((e) => _normalizarOTM(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> _buscarPorTexto(
    String query,
    double lat,
    double lng,
    String kinds,
  ) async {
    final url =
        'https://api.opentripmap.com/0.1/es/places/autosuggest'
        '?name=${Uri.encodeComponent(query)}'
        '&lon=$lng'
        '&lat=$lat'
        '&radius=50000'
        '&kinds=$kinds'
        '&limit=15'
        '&format=json'
        '&apikey=$_apiKey';

    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) return [];

    final data = jsonDecode(res.body);
    if (data is! List) return [];

    return data
        .whereType<Map>()
        .map((e) => _normalizarOTM(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Map<String, dynamic> _normalizarOTM(Map<String, dynamic> raw) {
    final props = raw['properties'] ?? raw;
    final geo = raw['geometry'];
    final coords = geo?['coordinates'];

    double lat = 0, lng = 0;
    if (coords is List && coords.length >= 2) {
      lng = (coords[0] as num).toDouble();
      lat = (coords[1] as num).toDouble();
    } else {
      lat = (props['lat'] ?? raw['lat'] ?? 0.0).toDouble();
      lng = (props['lon'] ?? raw['lon'] ?? raw['lng'] ?? 0.0).toDouble();
    }

    final kinds = (props['kinds'] ?? raw['kinds'] ?? '').toString();
    final rate = (props['rate'] ?? raw['rate'] ?? 0);

    return {
      'name': (props['name'] ?? raw['name'] ?? 'Sin nombre').toString(),
      'lat': lat,
      'lng': lng,
      'direccion': kinds.isNotEmpty ? kinds.split(',').first : 'Sin dirección',
      'categoriaPrincipal': _mapearKinds(kinds),
      'rating': _rateToDouble(rate),
      'popularity': _rateToDouble(rate),
      'precio': null,
      'foto': null,
      'fuente': 'opentripmap',
    };
  }

  static String _mapearKinds(String kinds) {
    if (kinds.contains('museum')) return 'museo';
    if (kinds.contains('historic') || kinds.contains('archaeology'))
      return 'monumento';
    if (kinds.contains('beach')) return 'playa';
    if (kinds.contains('natural')) return 'parque';
    if (kinds.contains('food') || kinds.contains('restaurant'))
      return 'restaurante';
    if (kinds.contains('shop')) return 'centro_comercial';
    if (kinds.contains('sport')) return 'actividades_extremas';
    if (kinds.contains('view')) return 'mirador';
    return 'otro';
  }

  static double _rateToDouble(dynamic rate) {
    if (rate is int) return (rate * 1.5).clamp(0.0, 10.0);
    if (rate is double) return rate.clamp(0.0, 10.0);
    if (rate is String) {
      final n = int.tryParse(rate);
      if (n != null) return (n * 1.5).clamp(0.0, 10.0);
    }
    return 5.0;
  }
}
