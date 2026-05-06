import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GooglePlacesServicio {
  static String get _apiKey => dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';

  // Mapeo de tipos de filtro → tipos de Google Places
  static const Map<String, String> _tipoAGoogleType = {
    'restaurante': 'restaurant',
    'cafeteria': 'cafe',
    'bar': 'bar',
    'parque': 'park',
    'museo': 'museum',
    'playa': 'natural_feature',
    'monumento': 'tourist_attraction',
    'zona_arqueologica': 'tourist_attraction',
    'mirador': 'point_of_interest',
    'centro_comercial': 'shopping_mall',
    'actividades_extremas': 'amusement_park',
  };

  /// Busca lugares cercanos a [lat],[lng] con query opcional y tipo opcional.
  static Future<List<Map<String, dynamic>>> buscarLugares(
    double lat,
    double lng, {
    String query = '',
    String? tipo,
    int radio = 15000,
  }) async {
    try {
      String url;

      if (query.isNotEmpty) {
        // Text Search cuando hay texto
        url =
            'https://maps.googleapis.com/maps/api/place/textsearch/json'
            '?query=${Uri.encodeComponent(query)}'
            '&location=$lat,$lng'
            '&radius=$radio'
            '&language=es'
            '&key=$_apiKey';

        if (tipo != null && _tipoAGoogleType.containsKey(tipo)) {
          url += '&type=${_tipoAGoogleType[tipo]}';
        }
      } else {
        // Nearby Search cuando solo hay coordenadas
        final googleTipo = tipo != null && _tipoAGoogleType.containsKey(tipo)
            ? _tipoAGoogleType[tipo]!
            : 'tourist_attraction';

        url =
            'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
            '?location=$lat,$lng'
            '&radius=$radio'
            '&type=$googleTipo'
            '&language=es'
            '&key=$_apiKey';
      }

      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) return [];

      final data = jsonDecode(res.body);
      final results = data['results'] as List? ?? [];

      return results.map<Map<String, dynamic>>((place) {
        final loc = place['geometry']?['location'];
        final priceLevel = place['price_level'];

        return {
          'name': place['name'] ?? 'Sin nombre',
          'lat': (loc?['lat'] ?? lat).toDouble(),
          'lng': (loc?['lng'] ?? lng).toDouble(),
          'direccion':
              place['vicinity'] ??
              place['formatted_address'] ??
              'Sin dirección',
          'categoriaPrincipal': _mapearCategoria(place['types']),
          'tipos_raw': place['types'] ?? [],
          'rating': (place['rating'] ?? 5.0).toDouble(),
          'popularity': ((place['user_ratings_total'] ?? 0) / 100.0).clamp(
            0.0,
            10.0,
          ),
          'precio': priceLevel != null ? _mapearPrecio(priceLevel) : null,
          'foto': _fotoUrl(place['photos']),
          'place_id': place['place_id'] ?? '',
          'fuente': 'google',
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  static String _mapearCategoria(List? types) {
    if (types == null || types.isEmpty) return 'otro';

    const Map<String, String> googleACategoria = {
      'restaurant': 'restaurante',
      'cafe': 'cafeteria',
      'bar': 'bar',
      'park': 'parque',
      'museum': 'museo',
      'natural_feature': 'playa',
      'tourist_attraction': 'monumento',
      'shopping_mall': 'centro_comercial',
      'amusement_park': 'actividades_extremas',
      'point_of_interest': 'mirador',
      'lodging': 'hotel',
      'store': 'centro_comercial',
      'food': 'restaurante',
      'night_club': 'bar',
    };

    for (final t in types) {
      if (googleACategoria.containsKey(t)) return googleACategoria[t]!;
    }
    return 'otro';
  }

  static String _mapearPrecio(int level) {
    switch (level) {
      case 0:
      case 1:
        return r'$';
      case 2:
        return r'$$';
      case 3:
      case 4:
        return r'$$$';
      default:
        return r'$';
    }
  }

  static String? _fotoUrl(List? photos) {
    if (photos == null || photos.isEmpty) return null;
    final ref = photos[0]['photo_reference'];
    if (ref == null) return null;
    return 'https://maps.googleapis.com/maps/api/place/photo'
        '?maxwidth=400&photo_reference=$ref&key=$_apiKey';
  }
}
