import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:proyecto/nucleo/utilidades/mapeo_categorias.dart';

class OpenTripMapServicio {
  static String get _apiKey => dotenv.env['OPENTRIPMAP_API_KEY'] ?? '';

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

  static Future<List<Map<String, dynamic>>> buscarLugaresCulturales(
    double lat,
    double lng, {
    String query = '',
    String? tipo,
    int radio = 15000,
  }) async {
    try {

      final url =
          'https://api.opentripmap.com/0.1/en/places/radius'
          '?radius=$radio'
          '&lon=$lng'
          '&lat=$lat'
          '&rate=1'
          '&limit=60'
          '&format=json'
          '&apikey=$_apiKey';

      final res = await http.get(Uri.parse(url));

      if (res.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(res.body);

      if (data is! List) {
        return [];
      }

      List<Map<String, dynamic>> lugares = data
          .whereType<Map>()
          .map((e) => _normalizarOTM(Map<String, dynamic>.from(e)))
          .toList();

      // 🔥 búsqueda local por texto
      if (query.isNotEmpty) {
        lugares = lugares.where((l) {
          return (l['name'] ?? '').toString().toLowerCase().contains(
            query.toLowerCase(),
          );
        }).toList();
      }

      return lugares;
    } catch (e) {
      return [];
    }
  }

  static Map<String, dynamic> _normalizarOTM(Map<String, dynamic> raw) {
    double lat = 0;
    double lng = 0;

    if (raw['point'] != null) {
      lat = (raw['point']['lat'] ?? 0).toDouble();
      lng = (raw['point']['lon'] ?? 0).toDouble();
    } else {
      lat = (raw['lat'] ?? 0).toDouble();
      lng = (raw['lon'] ?? 0).toDouble();
    }

    final kinds = (raw['kinds'] ?? '').toString();

    return {
      'name': raw['name'] ?? 'Sin nombre',
      'lat': lat,
      'lng': lng,
      'direccion': _direccionCategoria(kinds),
      'categoriaPrincipal': MapeoCategorias.obtenerCategoriaPrincipal(kinds),
      'rating': _rateToDouble(raw['rate']),
      'popularity': _rateToDouble(raw['rate']),
      'precio': null,
      'foto': null,
      'fuente': 'opentripmap',
    };
  }

  static String _direccionCategoria(String kinds) {
    final c = MapeoCategorias.obtenerCategoriaPrincipal(kinds);

    switch (c) {
      case 'restaurante':
        return 'Restaurante';

      case 'cafeteria':
        return 'Cafetería';

      case 'bar':
        return 'Bar';

      case 'parque':
        return 'Parque';

      case 'museo':
        return 'Museo';

      case 'playa':
        return 'Playa';

      case 'monumento':
        return 'Sitio histórico';

      case 'zona_arqueologica':
        return 'Zona arqueológica';

      case 'centro_comercial':
        return 'Centro comercial';

      case 'mirador':
        return 'Mirador';

      case 'actividades_extremas':
        return 'Actividad extrema';

      default:
        return 'Lugar turístico';
    }
  }

  static String _direccionAmigable(String kinds) {
    if (kinds.contains('museum')) {
      return 'Museo';
    }

    if (kinds.contains('historic')) {
      return 'Sitio histórico';
    }

    if (kinds.contains('architecture')) {
      return 'Lugar arquitectónico';
    }

    if (kinds.contains('natural')) {
      return 'Zona natural';
    }

    if (kinds.contains('beach')) {
      return 'Playa';
    }

    if (kinds.contains('foods')) {
      return 'Restaurante';
    }

    return 'Lugar turístico';
  }

  static double _rateToDouble(dynamic rate) {
    if (rate is int) {
      return ((rate * 2).clamp(0.0, 10.0)).toDouble();
    }

    if (rate is double) {
      return rate.clamp(0.0, 10.0).toDouble();
    }

    return 5.0;
  }
}
