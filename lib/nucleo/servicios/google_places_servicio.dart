import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GooglePlacesServicio {
  static String get _apiKey => dotenv.env['GOOGLE_API_KEY'] ?? '';

  // ---------------------------------------------------------------------------
  // BUSCAR LUGARES (FILTRADO DESDE EL SERVIDOR) - VERSIÓN REPARADA (HORARIOS)
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
        url =
            'https://maps.googleapis.com/maps/api/place/textsearch/json'
            '?query=${Uri.encodeComponent(query)}'
            '&location=$lat,$lng'
            '&radius=$radio'
            '&language=es'
            // 🔥 El candado de horarios está bien aquí
            '&fields=photos,name,geometry,rating,place_id,types,vicinity,opening_hours,price_level'
            '&key=$_apiKey';

        if (tipo != null && tipo.isNotEmpty) {
          url += '&type=$tipo';
        }
      }
      // ---------------------------------------------------------------------
      // NEARBY SEARCH (El culpable reparado)
      // ---------------------------------------------------------------------
      else {
        // 🔥 Para que nearbysearch envíe horarios, cambiamos a la versión 'textsearch'
        // pero buscando por el "tipo" en texto en la ubicación específica.
        // Es un truco legal de Google Maps para obligarlo a darte todos los fields sin costo extra.

        String queryTipo = tipo != null && tipo.isNotEmpty
            ? tipo
            : 'tourist_attraction';
        // Traducimos el tipo a español para que la búsqueda sea más natural (ej: 'restaurant' a 'restaurantes')
        if (queryTipo == 'restaurant') queryTipo = 'restaurantes';
        if (queryTipo == 'cafe') queryTipo = 'cafeterías';

        url =
            'https://maps.googleapis.com/maps/api/place/textsearch/json'
            '?query=${Uri.encodeComponent(queryTipo)}'
            '&location=$lat,$lng'
            '&radius=$radio'
            '&language=es'
            // 🔥 AHORA SÍ LE PEDIMOS LOS HORARIOS EXPLÍCITAMENTE AL NEARBY
            '&fields=photos,name,geometry,rating,place_id,types,vicinity,opening_hours,price_level'
            '&key=$_apiKey';
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
        final List<String> types =
            (place['types'] as List?)?.map((e) => e.toString()).toList() ?? [];

        String categoria = _mapearCategoria(types, nombre: place['name'] ?? '');

        final nombreLower = (place['name'] ?? '').toString().toLowerCase();
        if (nombreLower.contains('mirador')) categoria = 'mirador';
        if (nombreLower.contains('zona arqueológica') ||
            nombreLower.contains('ruinas'))
          categoria = 'zona_arqueologica';
        if (nombreLower.contains('mall') || nombreLower.contains('plaza'))
          categoria = 'centro_comercial';
        if (nombreLower.contains('extremo') ||
            nombreLower.contains('adventure'))
          categoria = 'actividades_extremas';

        final priceLevel = place['price_level'];

        // 🔥 ¡AQUÍ ESTÁ LA MAGIA PARA LA TARJETA!
        bool? estaAbierto;
        String horarioTexto = 'Horario no disponible';

        if (place['opening_hours'] != null &&
            place['opening_hours']['open_now'] != null) {
          estaAbierto = place['opening_hours']['open_now'];
          horarioTexto = estaAbierto == true
              ? '🟢 Abierto ahora'
              : '🔴 Cerrado en este momento';
        }

        return {
          'name': place['name'] ?? 'Sin nombre',
          'direccion':
              place['vicinity'] ??
              place['formatted_address'] ??
              'Sin dirección',
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
          'abierto': estaAbierto, // 🔥 ¡ESTO ES LO QUE NECESITA TU TARJETA!
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
    if (texto.contains('cafe') ||
        texto.contains('coffee') ||
        texto.contains('bakery') ||
        n.contains('cafe'))
      return 'cafeteria';
    if (texto.contains('bar') ||
        texto.contains('night_club') ||
        texto.contains('pub') ||
        n.contains('bar'))
      return 'bar';

    // 🔥 2. GENERALES DESPUÉS
    if (texto.contains('restaurant') ||
        texto.contains('food') ||
        texto.contains('meal'))
      return 'restaurante';

    if (texto.contains('park') || texto.contains('garden')) return 'parque';
    if (texto.contains('museum') || texto.contains('art_gallery'))
      return 'museo';
    if (texto.contains('beach') || n.contains('playa')) return 'playa';
    if (texto.contains('shopping') || texto.contains('mall'))
      return 'centro_comercial';
    if (texto.contains('viewpoint') || n.contains('mirador')) return 'mirador';
    if (texto.contains('archaeological') ||
        n.contains('ruinas') ||
        n.contains('maya'))
      return 'zona_arqueologica';
    if (texto.contains('amusement_park') ||
        n.contains('xcaret') ||
        n.contains('extremo'))
      return 'actividades_extremas';
    if (texto.contains('tourist_attraction') ||
        texto.contains('historic') ||
        n.contains('monumento') ||
        n.contains('catedral'))
      return 'monumento';

    return 'otro';
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
    if (photos == null || photos.isEmpty) return null;
    final ref =
        photos.first['photo_reference'] ?? photos.first['photoReference'];
    if (ref == null) return null;
    return 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&maxheight=800&photo_reference=$ref&key=$_apiKey';
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
    final futures = categorias.map((cat) async {
      final googleType = _categoriaAGoogleType[cat];
      final resultados = await buscarLugares(
        lat,
        lng,
        tipo: googleType != null ? googleType : cat,
        radio: radio,
      );
      // 🔥 FIX: fuerza la categoría del perfil a los resultados de esa búsqueda
      for (final lugar in resultados) {
        lugar['categoriaPrincipal'] = cat;
      }
      return resultados;
    });

    final resultados = await Future.wait(futures);

    final Map<String, Map<String, dynamic>> vistos = {};
    for (final lista in resultados) {
      for (final lugar in lista) {
        final nombreLimpio = (lugar['name'] ?? 'sin_nombre')
            .toString()
            .toLowerCase()
            .trim();
        if (!vistos.containsKey(nombreLimpio)) {
          vistos[nombreLimpio] = lugar;
        } else if (lugar['foto'] != null &&
            vistos[nombreLimpio]!['foto'] == null) {
          vistos[nombreLimpio] = lugar;
        }
      }
    }

    return vistos.values.toList();
  }

  // 🔥 NUEVA FUNCIÓN: OBTENER HORARIOS Y SEMÁFORO DESDE DETAILS
  static Future<Map<String, dynamic>> obtenerDetallesHorario(
    String placeId,
  ) async {
    final apiKey = dotenv.env['GOOGLE_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return {'abierto': null, 'dias': []};

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=$placeId'
      '&fields=opening_hours'
      '&language=es'
      '&key=$apiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] != null && data['result']['opening_hours'] != null) {
          final hours = data['result']['opening_hours'];
          return {
            'abierto': hours['open_now'],
            'dias': hours['weekday_text'] != null
                ? List<String>.from(hours['weekday_text'])
                : <String>[],
          };
        }
      }
      return {'abierto': null, 'dias': []};
    } catch (e) {
      print("❌ Error obteniendo detalles de horario: $e");
      return {'abierto': null, 'dias': []};
    }
  }
}
