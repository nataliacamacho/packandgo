import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GooglePlacesServicio {
  static String get _apiKey => dotenv.env['GOOGLE_API_KEY'] ?? '';

  // ---------------------------------------------------------------------------
  // MAPEO APP -> GOOGLE
  // ---------------------------------------------------------------------------
  static const Map<String, String> _tipoAGoogleType = {
    'restaurante': 'restaurant',
    'cafeteria': 'cafe',
    'bar': 'bar',
    'parque': 'park',
    'museo': 'museum',
    'playa': 'natural_feature',
    'monumento': 'tourist_attraction',
    'zona_arqueologica': 'tourist_attraction',
    'mirador': 'tourist_attraction',
    'centro_comercial': 'shopping_mall',
    'actividades_extremas': 'amusement_park',
  };

  // ---------------------------------------------------------------------------
  // BUSCAR
  // ---------------------------------------------------------------------------
  static Future<List<Map<String, dynamic>>> buscarLugares(
    double lat,
    double lng, {
    String query = '',
    String? tipo,
    int radio = 15000,
  }) async {
    try {
      final googleTipo = tipo != null ? _tipoAGoogleType[tipo] : null;

      String url;

      // ---------------------------------------------------------------------
      // TEXT SEARCH
      // ---------------------------------------------------------------------
      if (query.isNotEmpty) {
        final queryFinal = googleTipo != null
            ? '${_traducirTipo(tipo!)} cerca de mi'
            : query;

        url =
            'https://maps.googleapis.com/maps/api/place/textsearch/json'
            '?query=${Uri.encodeComponent(queryFinal)}'
            '&location=$lat,$lng'
            '&radius=$radio'
            '&language=es'
            '&fields=photos,name,geometry,rating,place_id,types,vicinity'
            '&key=$_apiKey';

        if (googleTipo != null) {
          url += '&type=$googleTipo';
        }
      }
      // ---------------------------------------------------------------------
      // NEARBY SEARCH
      // ---------------------------------------------------------------------
      else {
        url =
            'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
            '?location=$lat,$lng'
            '&radius=$radio'
            '&region=mx'
            '&language=es'
            '&fields=photos,name,geometry,rating,place_id,types,vicinity'
            '&key=$_apiKey';

        // 🔥 SOLO poner type si realmente existe
        if (googleTipo != null) {
          url += '&type=$googleTipo';
        }
      }

      print('🌎 URL GOOGLE: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        print('❌ GOOGLE STATUS: ${response.statusCode}');
        return [];
      }

      final data = jsonDecode(response.body);

      print('🟦 GOOGLE STATUS API: ${data['status']}');

      final results = data['results'] as List? ?? [];

      print('🟦 GOOGLE RESULTADOS: ${results.length}');

      return results.map<Map<String, dynamic>>((place) {
        final loc = place['geometry']?['location'];

        final types =
            (place['types'] as List?)?.map((e) => e.toString()).toList() ?? [];

        final categoria = _mapearCategoria(types);

        print('📍 GOOGLE TYPES: $types');
        print('✅ CATEGORIA FINAL: $categoria');

        final priceLevel = place['price_level'];

        return {
          // -----------------------------------------------------------------
          // INFO
          // -----------------------------------------------------------------
          'name': place['name'] ?? 'Sin nombre',

          'direccion':
              place['vicinity'] ??
              place['formatted_address'] ??
              'Sin dirección',

          // -----------------------------------------------------------------
          // COORDENADAS
          // -----------------------------------------------------------------
          'lat': _toDouble(loc?['lat'], lat),
          'lng': _toDouble(loc?['lng'], lng),

          // -----------------------------------------------------------------
          // CATEGORÍAS
          // -----------------------------------------------------------------
          'categoriaPrincipal': categoria,

          'tipos_raw': types,

          // -----------------------------------------------------------------
          // RATING
          // -----------------------------------------------------------------
          'rating': _toDouble(place['rating'], 5.0),

          // -----------------------------------------------------------------
          // POPULARIDAD
          // -----------------------------------------------------------------
          'popularity': _popularidad(place['user_ratings_total']),

          // -----------------------------------------------------------------
          // PRECIO
          // -----------------------------------------------------------------
          'precio': priceLevel != null ? _mapearPrecio(priceLevel) : null,

          // -----------------------------------------------------------------
          // FOTO
          // -----------------------------------------------------------------
          'foto': _fotoUrl(place['photos']),

          // -----------------------------------------------------------------
          // IDS
          // -----------------------------------------------------------------
          'place_id': place['place_id'] ?? '',

          'fuente': 'google',
        };
      }).toList();
    } catch (e) {
      print('❌ ERROR GOOGLE: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // MAPEAR CATEGORÍAS
  // ---------------------------------------------------------------------------
  static String _mapearCategoria(List<String> types) {
    final texto = types.join(' ').toLowerCase();

    // -------------------------------------------------------------------------
    // RESTAURANTES
    // -------------------------------------------------------------------------
    if (texto.contains('restaurant')) return 'restaurante';
    if (texto.contains('food')) return 'restaurante';
    if (texto.contains('meal_takeaway')) return 'restaurante';
    if (texto.contains('meal_delivery')) return 'restaurante';

    // -------------------------------------------------------------------------
    // CAFETERÍAS
    // -------------------------------------------------------------------------
    if (texto.contains('cafe')) return 'cafeteria';
    if (texto.contains('coffee')) return 'cafeteria';
    if (texto.contains('bakery')) return 'cafeteria';

    // -------------------------------------------------------------------------
    // BARES
    // -------------------------------------------------------------------------
    if (texto.contains('bar')) return 'bar';
    if (texto.contains('night_club')) return 'bar';
    if (texto.contains('pub')) return 'bar';

    // -------------------------------------------------------------------------
    // PARQUES
    // -------------------------------------------------------------------------
    if (texto.contains('park')) return 'parque';
    if (texto.contains('garden')) return 'parque';

    // -------------------------------------------------------------------------
    // MUSEOS
    // -------------------------------------------------------------------------
    if (texto.contains('museum')) return 'museo';
    if (texto.contains('art_gallery')) return 'museo';

    // -------------------------------------------------------------------------
    // PLAYAS
    // -------------------------------------------------------------------------
    if (texto.contains('beach')) return 'playa';
    if (texto.contains('natural_feature')) return 'playa';

    // -------------------------------------------------------------------------
    // CENTROS COMERCIALES
    // -------------------------------------------------------------------------
    if (texto.contains('shopping_mall')) {
      return 'centro_comercial';
    }

    if (texto.contains('department_store')) {
      return 'centro_comercial';
    }

    if (texto.contains('store')) {
      return 'centro_comercial';
    }

    if (texto.contains('mall')) {
      return 'centro_comercial';
    }

    // -------------------------------------------------------------------------
    // MIRADORES
    // -------------------------------------------------------------------------
    if (texto.contains('view')) return 'mirador';

    // -------------------------------------------------------------------------
    // ZONAS ARQUEOLÓGICAS
    // -------------------------------------------------------------------------
    if (texto.contains('archaeological')) {
      return 'zona_arqueologica';
    }

    // -------------------------------------------------------------------------
    // ACTIVIDADES
    // -------------------------------------------------------------------------
    if (texto.contains('amusement_park')) {
      return 'actividades_extremas';
    }

    if (texto.contains('stadium')) {
      return 'actividades_extremas';
    }

    // -------------------------------------------------------------------------
    // MONUMENTOS
    // -------------------------------------------------------------------------
    if (texto.contains('tourist_attraction')) {
      return 'monumento';
    }

    if (texto.contains('historic')) {
      return 'monumento';
    }

    return 'otro';
  }

  // ---------------------------------------------------------------------------
  // TRADUCIR TIPO
  // ---------------------------------------------------------------------------
  static String _traducirTipo(String tipo) {
    switch (tipo) {
      case 'restaurante':
        return 'restaurantes';

      case 'cafeteria':
        return 'cafeterías';

      case 'bar':
        return 'bares';

      case 'parque':
        return 'parques';

      case 'museo':
        return 'museos';

      case 'playa':
        return 'playas';

      case 'centro_comercial':
        return 'centros comerciales';

      default:
        return tipo;
    }
  }

  // ---------------------------------------------------------------------------
  // PRECIO
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // FOTO
  // ---------------------------------------------------------------------------
  static String? _fotoUrl(List? photos) {
    try {
      if (photos == null || photos.isEmpty) {
        return null;
      }

      final primeraFoto = photos.first;

      final ref =
          primeraFoto['photo_reference'] ?? primeraFoto['photoReference'];

      if (ref == null) {
        return null;
      }

      return 'https://maps.googleapis.com/maps/api/place/photo'
          '?maxwidth=800'
          '&photo_reference=$ref'
          '&key=$_apiKey';
    } catch (e) {
      print('❌ ERROR FOTO GOOGLE: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------
  static double _toDouble(dynamic v, double fb) {
    if (v == null) return fb;

    if (v is double) return v;

    if (v is int) return v.toDouble();

    if (v is num) return v.toDouble();

    if (v is String) {
      return double.tryParse(v) ?? fb;
    }

    return fb;
  }

  static double _popularidad(dynamic v) {
    final total = _toDouble(v, 0);

    final pop = total / 100;

    if (pop > 10) return 10;

    return pop;
  }
}
