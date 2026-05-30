import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GooglePlacesServicio {
  static String get _apiKey => dotenv.env['GOOGLE_API_KEY'] ?? '';

  // ---------------------------------------------------------------------------
  // BUSCAR LUGARES (FILTRADO DESDE EL SERVIDOR)
  // ---------------------------------------------------------------------------
  static Future<List<Map<String, dynamic>>> buscarLugares(
    double lat,
    double lng, {
    String query = '',
    String? tipo,
    int radio = 50000,
  }) async {
    try {
      String url;

      // ---------------------------------------------------------------------
      // TEXT SEARCH
      // ---------------------------------------------------------------------
      if (query.isNotEmpty) {
        url = 'https://maps.googleapis.com/maps/api/place/textsearch/json'
            '?query=${Uri.encodeComponent(query)}'
            '&location=$lat,$lng'
            '&radius=$radio'
            '&language=es'
            // 🔥 CORRECCIÓN 1: Quitamos maxresults=5 para que Google nos mande 20 
            // y garantizar que haya suficientes para el Top 5
            '&fields=photos,name,geometry,rating,place_id,types,vicinity,opening_hours,price_level'
            '&key=$_apiKey';

        // 🔥 CORRECCIÓN 2: Inyectar directamente a la API el filtro estricto
        if (tipo != null && tipo.isNotEmpty) {
          url += '&type=$tipo';
        }
      } 
      // ---------------------------------------------------------------------
      // NEARBY SEARCH
      // ---------------------------------------------------------------------
      else {
        url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
            '?location=$lat,$lng'
            '&radius=$radio'
            '&region=mx'
            '&language=es'
            '&key=$_apiKey';

        if (tipo != null && tipo.isNotEmpty) {
          url += '&type=$tipo';
        } else {
          // Por defecto, si no hay filtro, que traiga turismo
          url += '&type=tourist_attraction';
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

      final filtradosReales = results.where((place) {
        final nombre = place['name']?.toString() ?? '';
        final geometry = place['geometry'];
        if (nombre.isEmpty || geometry == null) return false;

        final rawTypes = place['types'];
        final List<String> types = (rawTypes is List)
            ? rawTypes.map((e) => e.toString()).toList()
            : <String>[];

        if (types.isEmpty) return false;

        // 🔥 ¡ADIÓS AL ASESINO DE CAFETERÍAS!
        const bloqueados = [
          'supermarket', 
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
        final List<String> types = (place['types'] as List?)?.map((e) => e.toString()).toList() ?? [];

        String categoria = _mapearCategoria(types, nombre: place['name'] ?? '');

        // Correcciones manuales basadas en el nombre
        final nombreLower = (place['name'] ?? '').toString().toLowerCase();
        if (nombreLower.contains('mirador')) categoria = 'mirador';
        if (nombreLower.contains('zona arqueológica') || nombreLower.contains('ruinas')) categoria = 'zona_arqueologica';
        if (nombreLower.contains('mall') || nombreLower.contains('plaza')) categoria = 'centro_comercial';
        if (nombreLower.contains('extremo') || nombreLower.contains('adventure')) categoria = 'actividades_extremas';

        final priceLevel = place['price_level'];

          String horarioTexto = 'Horario no disponible';
          if (place['opening_hours'] != null) {
            // Las búsquedas generales nos devuelven un booleano de si está abierto ahora
            horarioTexto = place['opening_hours']['open_now'] == true 
                          ? '🟢 Abierto ahora' 
                          : '🔴 Cerrado en este momento';
          }

        return {
          'name': place['name'] ?? 'Sin nombre',
          'direccion': place['vicinity'] ?? place['formatted_address'] ?? 'Sin dirección',
          'lat': _toDouble(loc?['lat'], lat),
          'lng': _toDouble(loc?['lng'], lng),
          'categoriaPrincipal': categoria,
          'types': types,
          'rating': _toDouble(place['rating'], 5.0),
          'popularity': _popularidad(place['user_ratings_total']),
          'precio': priceLevel != null ? _mapearPrecio(priceLevel) : null,
          'foto': _fotoUrl(place['photos']),
          'photos': place['photos'],
          'place_id': place['place_id'] ?? '',
          'fuente': 'google',
          'horario': horarioTexto,
        };
      }).toList();
    } catch (e) {
      print('❌ ERROR GOOGLE: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // MAPEAR CATEGORÍAS (Corregido: Específicos primero, Generales después)
  // ---------------------------------------------------------------------------
  static String _mapearCategoria(List<String> types, {String nombre = ''}) {
    final texto = types.join(' ').toLowerCase();
    final n = nombre.toLowerCase();

    // 🔥 1. ESPECÍFICOS PRIMERO (Para que "food" no se los robe)
    if (texto.contains('cafe') || texto.contains('coffee') || texto.contains('bakery') || n.contains('cafe')) return 'cafeteria';
    if (texto.contains('bar') || texto.contains('night_club') || texto.contains('pub') || n.contains('bar')) return 'bar';

    // 🔥 2. GENERALES DESPUÉS
    if (texto.contains('restaurant') || texto.contains('food') || texto.contains('meal')) return 'restaurante';

    if (texto.contains('park') || texto.contains('garden')) return 'parque';
    if (texto.contains('museum') || texto.contains('art_gallery')) return 'museo';
    if (texto.contains('beach') || n.contains('playa')) return 'playa';
    if (texto.contains('shopping') || texto.contains('mall')) return 'centro_comercial';
    if (texto.contains('viewpoint') || n.contains('mirador')) return 'mirador';
    if (texto.contains('archaeological') || n.contains('ruinas') || n.contains('maya')) return 'zona_arqueologica';
    if (texto.contains('amusement_park') || n.contains('xcaret') || n.contains('extremo')) return 'actividades_extremas';
    if (texto.contains('tourist_attraction') || texto.contains('historic') || n.contains('monumento') || n.contains('catedral')) return 'monumento';

    return 'otro';
  }

  // ---------------------------------------------------------------------------
  // PRECIO
  // ---------------------------------------------------------------------------
  static String _mapearPrecio(int level) {
    switch (level) {
      case 0:
      case 1: return r'$';
      case 2: return r'$$';
      case 3:
      case 4: return r'$$$';
      default: return r'$';
    }
  }

  // ---------------------------------------------------------------------------
  // FOTO
  // ---------------------------------------------------------------------------
  static String? _fotoUrl(List? photos) {
    if (photos == null || photos.isEmpty) return null;
    final ref = photos.first['photo_reference'] ?? photos.first['photoReference'];
    if (ref == null) return null;
    return 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photo_reference=$ref&key=$_apiKey';
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------
  static double _toDouble(dynamic v, double fb) {
    if (v == null) return fb;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fb;
    return fb;
  }

  static double _popularidad(dynamic v) {
    final pop = _toDouble(v, 0) / 100;
    return pop > 10 ? 10 : pop;
  }


  // ---------------------------------------------------------------------------
  // BUSCAR POR MÚLTIPLES CATEGORÍAS (Para la pantalla de Exploración)
  // ---------------------------------------------------------------------------
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
    int radio = 50000,
  }) async {
    // Dispara las búsquedas al mismo tiempo (Concurrencia)
    final futures = categorias.map((cat) {
      final googleType = _categoriaAGoogleType[cat];
      return buscarLugares(
        lat,
        lng,
        tipo: googleType != null ? googleType : cat,
        radio: radio,
      );
    });

    final resultados = await Future.wait(futures);

    // Junta todos los resultados y elimina los repetidos
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
}