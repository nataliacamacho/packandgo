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
    'centro_comercial': 'shopping_mall',
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
        String queryFinal = query;

        if (tipo != null) {
          final tipoTraducido = _traducirTipo(tipo);

          if (query.trim().isEmpty) {
            queryFinal = tipoTraducido;
          } else {
            queryFinal = '$tipoTraducido $query';
          }
        }

        url =
            'https://maps.googleapis.com/maps/api/place/textsearch/json'
            '?query=${Uri.encodeComponent(queryFinal)}'
            '&location=$lat,$lng'
            '&radius=$radio'
            '&language=es'
            '&fields=photos,name,geometry,rating,place_id,types,vicinity'
            '&key=$_apiKey';
      }
      // ---------------------------------------------------------------------
      // NEARBY SEARCH
      // ---------------------------------------------------------------------
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
            '&key=$_apiKey';

        // -------------------------------------------------------------
        // TIPOS NATIVOS GOOGLE
        // -------------------------------------------------------------
        if (googleTipo != null &&
            tipo != 'mirador' &&
            tipo != 'zona_arqueologica' &&
            tipo != 'actividades_extremas' &&
            tipo != 'monumento' &&
            tipo != 'playa') {
          url += '&type=$googleTipo';
        }
        // -------------------------------------------------------------
        // CATEGORÍAS PERSONALIZADAS
        // -------------------------------------------------------------
        else if (tipo != null) {
          final keyword = _traducirTipo(tipo);
          url += '&keyword=${Uri.encodeComponent(keyword)}';
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

      final filtrados = results.where((place) {
        final nombre = place['name']?.toString() ?? '';
        final geometry = place['geometry'];

        return nombre.isNotEmpty && geometry != null;
      }).toList();

      print('🟦 GOOGLE RESULTADOS: ${results.length}');

      final filtradosReales = filtrados.where((place) {
        final rawTypes = place['types'];

        final List<String> types = (rawTypes is List)
            ? rawTypes.map((e) => e.toString()).toList()
            : <String>[];

        if (types.isEmpty) return false;

        const bloqueados = [
          'supermarket',
          'store',
          'department_store',
          'pharmacy',
          'bank',
          'gas_station',
          'lodging',
        ];

        return !types.any((t) => bloqueados.contains(t));
      }).toList();

      return filtradosReales.map<Map<String, dynamic>>((place) {
        final loc = place['geometry']?['location'];

        // 🔥 FIX IMPORTANTE: normalizar types correctamente
        final List<String> types =
            (place['types'] as List?)?.map((e) => e.toString()).toList() ?? [];

        print("DEBUG TYPES ${place['name']} => $types");

        String categoria = _mapearCategoria(types, nombre: place['name'] ?? '');

        final nombre = (place['name'] ?? '').toString().toLowerCase();

        if (nombre.contains('mirador')) {
          categoria = 'mirador';
        }

        if (nombre.contains('zona arqueológica') ||
            nombre.contains('arqueologica') ||
            nombre.contains('ruinas')) {
          categoria = 'zona_arqueologica';
        }

        if (nombre.contains('mall') ||
            nombre.contains('plaza') ||
            nombre.contains('center')) {
          categoria = 'centro_comercial';
        }

        if (nombre.contains('extremo') ||
            nombre.contains('adventure') ||
            nombre.contains('parque acuatico')) {
          categoria = 'actividades_extremas';
        }

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

          'types': types,

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
          'photos': place['photos'],

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

  // Agrega esto al final de la clase, antes del último }
  static const Map<String, String> _categoriaAGoogleType = {
    'restaurante': 'restaurant',
    'cafeteria': 'cafe',
    'bar': 'bar',
    'parque': 'park',
    'museo': 'museum',
    'monumento': 'tourist_attraction',
    'actividades_extremas': 'amusement_park',
    'centro_comercial': 'shopping_mall',
  };

  static Future<List<Map<String, dynamic>>> buscarPorCategorias(
    double lat,
    double lng, {
    required List<String> categorias,
    int radio = 15000,
  }) async {
    // Llama en paralelo una búsqueda por cada categoría
    final futures = categorias.map((cat) {
      final googleType = _categoriaAGoogleType[cat];
      return buscarLugares(
        lat,
        lng,
        tipo: googleType != null ? cat : null,
        radio: radio,
      );
    });

    final resultados = await Future.wait(futures);

    // Aplana y deduplica por place_id
    final Map<String, Map<String, dynamic>> vistos = {};
    for (final lista in resultados) {
      for (final lugar in lista) {
        final id = lugar['place_id'] ?? lugar['name'];
        if (id != null && !vistos.containsKey(id)) {
          vistos[id] = lugar;
        }
      }
    }

    return vistos.values.toList();
  }

  // ---------------------------------------------------------------------------
  // MAPEAR CATEGORÍAS
  // ---------------------------------------------------------------------------
  static String _mapearCategoria(List<String> types, {String nombre = ''}) {
    final texto = types.join(' ').toLowerCase();
    final n = nombre.toLowerCase();

    // -------------------------------------------------------------------------
    // RESTAURANTES
    // -------------------------------------------------------------------------
    if (texto.contains('restaurant') ||
        texto.contains('food') ||
        texto.contains('meal_takeaway') ||
        texto.contains('meal_delivery')) {
      return 'restaurante';
    }

    // -------------------------------------------------------------------------
    // CAFETERÍAS
    // -------------------------------------------------------------------------
    if (texto.contains('cafe') ||
        texto.contains('coffee') ||
        texto.contains('bakery')) {
      return 'cafeteria';
    }

    // -------------------------------------------------------------------------
    // BARES
    // -------------------------------------------------------------------------
    if (texto.contains('bar') ||
        texto.contains('night_club') ||
        texto.contains('pub')) {
      return 'bar';
    }

    // -------------------------------------------------------------------------
    // PARQUES
    // -------------------------------------------------------------------------
    if (texto.contains('park') || texto.contains('garden')) {
      return 'parque';
    }

    // -------------------------------------------------------------------------
    // MUSEOS
    // -------------------------------------------------------------------------
    if (texto.contains('museum') || texto.contains('art_gallery')) {
      return 'museo';
    }

    // -------------------------------------------------------------------------
    // PLAYAS
    // -------------------------------------------------------------------------
    if (texto.contains('beach') ||
        texto.contains('natural_feature') ||
        n.contains('playa') ||
        n.contains('beach')) {
      return 'playa';
    }

    // -------------------------------------------------------------------------
    // CENTROS COMERCIALES
    // -------------------------------------------------------------------------
    if (texto.contains('shopping') ||
        texto.contains('mall') ||
        texto.contains('shopping_mall') ||
        texto.contains('department_store') ||
        texto.contains('store')) {
      return 'centro_comercial';
    }

    // -------------------------------------------------------------------------
    // MIRADORES
    // -------------------------------------------------------------------------
    if (texto.contains('viewpoint') ||
        texto.contains('observation') ||
        n.contains('mirador')) {
      return 'mirador';
    }

    // -------------------------------------------------------------------------
    // ZONAS ARQUEOLÓGICAS
    // -------------------------------------------------------------------------
    if (texto.contains('archaeological') ||
        n.contains('zona arqueologica') ||
        n.contains('arqueologica') ||
        n.contains('ruinas') ||
        n.contains('templo maya') ||
        n.contains('piramide')) {
      return 'zona_arqueologica';
    }

    // -------------------------------------------------------------------------
    // ACTIVIDADES EXTREMAS
    // -------------------------------------------------------------------------
    if (texto.contains('amusement_park') ||
        texto.contains('stadium') ||
        texto.contains('campground') ||
        texto.contains('rv_park') ||
        n.contains('xcaret') ||
        n.contains('rafting') ||
        n.contains('tirolesa') ||
        n.contains('extremo') ||
        n.contains('adventure')) {
      return 'actividades_extremas';
    }

    // -------------------------------------------------------------------------
    // MONUMENTOS
    // -------------------------------------------------------------------------
    if (texto.contains('tourist_attraction') ||
        texto.contains('historic') ||
        n.contains('monumento') ||
        n.contains('catedral') ||
        n.contains('iglesia') ||
        n.contains('templo') ||
        n.contains('plaza principal')) {
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

      case 'mirador':
        return 'miradores';

      case 'zona_arqueologica':
        return 'zonas arqueológicas';

      case 'centro_comercial':
        return 'centros comerciales';

      case 'actividades_extremas':
        return 'actividades extremas';

      case 'monumento':
        return 'monumentos turísticos';

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
